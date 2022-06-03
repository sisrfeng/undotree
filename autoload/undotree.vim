"=================================================
" File: autoload/undotree.vim
" Description: Manage your undo history in a graph.
" Author: David Knoble <ben.knoble@gmail.com>
" License: BSD

" Avoid installing twice.
    if exists('g:autoloaded_undotree')
        finish
    en
    let g:autoloaded_undotree = 0

    " At least version 7.3 with 005 patch is needed for undo branches.
    " Refer to https://github.com/mbbill/undotree/issues/4 for details.
    " Thanks kien
    if v:version < 703
        finish
    en
    if (v:version == 703 && !has("patch005"))
        finish
    en
    let g:loaded_undotree = 1   " Signal plugin availability with a value of 1.

" time indicators
    if g:undotree_ShortIndicators == 1
        let s:timeSecond   = '1 s'
        let s:timeSeconds  = ' s'

        let s:timeMinute   = '1 m'
        let s:timeMinutes  = ' m'

        let s:timeHour     = '1 h'
        let s:timeHours    = ' h'

        let s:timeDay      = '1 d'
        let s:timeDays     = ' d'

        let s:timeOriginal = 'Orig'
    el
        let s:timeSecond   = '1 second ago'
        let s:timeSeconds  = ' seconds ago'

        let s:timeMinute   = '1 minute ago'
        let s:timeMinutes  = ' minutes ago'

        let s:timeHour     = '1 hour ago'
        let s:timeHours    = ' hours ago'

        let s:timeDay      = '1 day ago'
        let s:timeDays     = ' days ago'

        let s:timeOriginal = 'Original'
    en

"=================================================
" Help text
    let s:helpmore = ['"    ===== Marks ===== ',
                \'" >num< : The current state',
                \'" {num} : The next redo state',
                \'" [num] : The latest state',
                \'"   s   : Saved states',
                \'"   S   : The last saved state',
                \'"   ===== Hotkeys =====']
    if !g:undotree_HelpLine
        let s:helpless = []
    el
        let s:helpless = ['" Press ? for help.']
    en

    "Custom key mappings: add this function to your vimrc.
    "You can define whatever mapping as you like, this is a hook function which
    "will be called after undotree window initialized.
    "
    "function g:Undotree_CustomMap()
    "    map <buffer> <c-n> J
    "    map <buffer> <c-p> K
    "endfunction

    " Keymap
    let s:keymap = []
    " action, key, help.
    let s:keymap += [['Help'               , '?'             , 'Toggle quick help']]
    let s:keymap += [['Close'              , 'q'             , 'Close undotree panel']]
    let s:keymap += [['FocusTarget'        , '<tab>'         , 'Set Focus back to the editor']]
    let s:keymap += [['ClearHistory'       , 'C'             , 'Clear undo history (with confirmation)']]
    let s:keymap += [['TimestampToggle'    , 'T'             , 'Toggle relative timestamp']]
    let s:keymap += [['DiffToggle'         , 'D'             , 'Toggle the diff panel']]
    let s:keymap += [['NextState'          , 'K'             , 'Move to the next undo state']]
    let s:keymap += [['PreviousState'      , 'J'             , 'Move to the previous undo state']]
    let s:keymap += [['NextSavedState'     , '>'             , 'Move to the next saved state']]
    let s:keymap += [['PreviousSavedState' , '<'             , 'Move to the previous saved state']]
    let s:keymap += [['Redo'               , '<c-r>'         , 'Redo']]
    let s:keymap += [['Undo'               , 'u'             , 'Undo']]
    let s:keymap += [['Enter'              , '<2-LeftMouse>' , 'Move to the current state']]
    let s:keymap += [['Enter'              , '<cr>'          , 'Move to the current state']]

" 'Diff' sign definitions. There are two 'delete' signs; a 'normal' one and one
    " that is used if the very end of the buffer has been deleted (in which case the
    " deleted text is actually bejond the end of the current buffer version and therefore
    " it is not possible to place a sign on the exact line - because it doesn't exist.
    " Instead, a 'special' delete sign is placed on the (existing) last line of the
    " buffer)
    exe 'sign define UndotreeAdd text=++ texthl='.undotree_HighlightSyntaxAdd
    exe 'sign define UndotreeChg text=~~ texthl='.undotree_HighlightSyntaxChange
    exe 'sign define UndotreeDel text=-- texthl='.undotree_HighlightSyntaxDel
    exe 'sign define UndotreeDelEnd text=-v texthl='.undotree_HighlightSyntaxDel

" " Id to use for all signs.
    " This is an arbirary number that is hoped to be unique within the instance of vim.
    " There is no way of guaranteeing it IS unique,
    " which is a shame because
    " it needs to be!
    " Note that all signs are placed with the same Id
    " - as long as we keep a count of how many we have placed (so we can remove them all again),
    " this is ok

    let s:signId = 2123654789


fun! s:new(obj) abort
    let newobj = deepcopy(a:obj)
    call newobj.Init()
    return newobj
endf

" Get formatted time
    fun! s:gettime(time) abort
        if a:time == 0
            return s:timeOriginal
        en
        if !g:undotree_RelativeTimestamp
            let today = substitute(strftime("%c",localtime())," .*$",'','g')
            if today == substitute(strftime("%c",a:time)," .*$",'','g')
                return strftime("%H:%M:%S",a:time)
            el
                return strftime("%H:%M:%S %b%d %Y",a:time)
            en
        el
            let sec = localtime() - a:time
            if sec < 0
                let sec = 0
            en
            if sec < 60
                if sec == 1
                    return s:timeSecond
                el
                    return sec.s:timeSeconds
                en
            en
            if sec < 3600
                if (sec/60) == 1
                    return s:timeMinute
                el
                    return (sec/60).s:timeMinutes
                en
            en
            if sec < 86400 "3600*24
                if (sec/3600) == 1
                    return s:timeHour
                el
                    return (sec/3600).s:timeHours
                en
            en
            if (sec/86400) == 1
                return s:timeDay
            el
                return (sec/86400).s:timeDays
            en
        en
    endf


" If debug file exists, enable debug output.
    " Set to 1 to enable debug log
    let s:debug = 0
    let s:debugfile = $cache_X..'/undotree_debug.log'
    if filewritable(s:debugfile)
        let s:debug = 1
        exec 'redir >> '. s:debugfile
        silent echo "==========================\n"
        redir END
    en

fun! s:log(msg) abort
    if s:debug
        exec 'redir >> ' . s:debugfile
        silent echon strftime('%H:%M:%S') . ': ' . string(a:msg) . "\n"
        redir END
    en
endf



fun! s:exec(cmd) abort
    call s:log("s:exec() ".a:cmd)
    silent exe a:cmd
endf

" Don't trigger any events(like BufEnter which could cause redundant refresh)
    fun! s:exec_silent(cmd) abort
        call s:log("s:exec_silent() ".a:cmd)
        let ei_bak= &eventignore
        set eventignore=BufEnter,BufLeave,BufWinLeave,InsertLeave,CursorMoved,BufWritePost
        silent exe a:cmd
        let &eventignore = ei_bak
    endf

" Return a unique id each time.
    let s:cntr = 0
    fun! s:getUniqueID() abort
        let s:cntr = s:cntr + 1
        return s:cntr
    endf



"=================================================
"Base class for panels.
let s:panel = {}

fun! s:panel.Init() abort
    let self.bufname = "invalid"
    " echom 'self是______' self
    " {
"     \ 'Hide': function('607'),
"     \ 'Init': function('604'),
"     \ 'bufname': 'invalid',
"     \ 'SetFocus': function('605'),
"     \ 'IsVisible': function('606'),
"    \ }
endf

fun! s:panel.SetFocus() abort
    let winnr = bufwinnr(self.bufname)
    " already focused.
    if winnr == winnr()
        return
    en
    if winnr == -1
        echoerr "操!: window does not exist!"
        return
    en
    call s:log("SetFocus() winnr:".winnr." bufname:".self.bufname)
    " wincmd would cause cursor outside window.
    call s:exec_silent("norm! ".winnr."\<c-w>\<c-w>")
endf

fun! s:panel.IsVisible() abort
    try
        let l:_num =  bufwinnr(self.bufname)
    catch
        let l:_num = -1
    endtry

    if  l:_num != -1
        return 1
    el
        return 0
    en
endf

fun! s:panel.Hide() abort
    call s:log(self.bufname." Hide()")
    if !self.IsVisible()
        return
    en
    call self.SetFocus()
    call s:exec("quit")
endf

"=================================================
" undotree panel class.
" extended from panel.
"

" {rawtree}
"     |
"     | ConvertInput()               {seq2index}--> [seq1:index1]
"     v                                             [seq2:index2] ---+
"  {tree}                                               ...          |
"     |                                    [asciimeta]               |
"     | Render()                                |                    |
"     v                                         v                    |
" [asciitree] --> [" * | SEQ DDMMYY "] <==> [node1{seq,time,..}]     |
"                 [" |/             "]      [node2{seq,time,..}] <---+
"                         ...                       ...

let s:undotree = s:new(s:panel)

fun! s:undotree.Init() abort
    let self.bufname = "undotree_".s:getUniqueID()
    " Increase to make it unique.
    let self.width = g:undotree_SplitWidth
    let self.opendiff = g:undotree_DiffAutoOpen
    let self.targetid = -1
    let self.targetBufnr = -1
    let self.rawtree = {}  "data passed from undotree()
    let self.tree = {}     "data converted to internal format.
    let self.seq_last = -1
    let self.save_last = -1
    let self.save_last_bak = -1

    " seqs
    let self.seq_cur = -1
    let self.seq_curhead = -1
    let self.seq_newhead = -1
    let self.seq_saved = {} "{saved value -> seq} pair

    "backup, for mark
    let self.seq_cur_bak = -1
    let self.seq_curhead_bak = -1
    let self.seq_newhead_bak = -1

    let self.asciitree = []     "output data.
    let self.asciimeta = []     "meta data behind ascii tree.
    let self.seq2index = {}     "table used to convert seq to index.
    let self.showHelp = 0
endf

fun! s:undotree.BindKey() abort
    if v:version > 703 || (v:version == 703 && has("patch1261"))
        let map_options = ' <nowait> '
    el
        let map_options = ''
    en
    let map_options = map_options.' <silent> <buffer> '
    for i in s:keymap
        silent exec 'nmap '.map_options.i[1].' <plug>Undotree'.i[0]
        silent exec 'nnoremap '.map_options.'<plug>Undotree'.i[0]
            \ .' :call <sid>undotreeAction("'.i[0].'")<cr>'
    endfor
    if exists('*g:Undotree_CustomMap')
        call g:Undotree_CustomMap()
    en
endf

fun! s:undotree.BindAu() abort
    " Auto exit if it's the last window
    augroup Undotree_Main
        au!
        au BufEnter <buffer> call s:exitIfLast()
        au BufEnter,BufLeave <buffer> if exists('t:undotree') |
                    \let t:undotree.width = winwidth(winnr()) | endif
        au BufWinLeave <buffer> if exists('t:diffpanel') |
                    \call t:diffpanel.Hide() | endif
    augroup end
endf

fun! s:undotree.Action(action) abort
    call s:log("undotree.Action() ".a:action)
    if !self.IsVisible() || !exists('b:isUndotreeBuffer')
        echoerr "Fatal: window does not exist."
        return
    en
    if !has_key(self,'Action'.a:action)
        echoerr "Fatal: Action does not exist!"
        return
    en
    silent exec 'call self.Action'.a:action.'()'
endf

" Helper function, do action in target window, and then update itself.
fun! s:undotree.ActionInTarget(cmd) abort
    if !self.SetTargetFocus()
        return
    en
    " Target should be a normal buffer.
    if (&bt == '' || &bt == 'acwrite') && (&modifiable == 1) && (mode() == 'n')
        call s:exec(a:cmd)
        call self.Update()
    en
    " Update not always set current focus.
    call self.SetFocus()
endf

fun! s:undotree.ActionHelp() abort
    let self.showHelp = !self.showHelp
    call self.Draw()
    call self.MarkSeqs()
endf

fun! s:undotree.ActionFocusTarget() abort
    call self.SetTargetFocus()
endf

fun! s:undotree.ActionEnter() abort
    let index = self.Screen2Index(line('.'))
    if index < 0
        return
    en
    let seq = self.asciimeta[index].seq
    if seq == -1
        return
    en
    if seq == 0
        call self.ActionInTarget('norm 9999u')
        return
    en
    call self.ActionInTarget('u '.self.asciimeta[index].seq)
endf

fun! s:undotree.ActionUndo() abort
    call self.ActionInTarget('undo')
endf

fun! s:undotree.ActionRedo() abort
    call self.ActionInTarget("redo")
endf

fun! s:undotree.ActionPreviousState() abort
    call self.ActionInTarget('earlier')
endf

fun! s:undotree.ActionNextState() abort
    call self.ActionInTarget('later')
endf

fun! s:undotree.ActionPreviousSavedState() abort
    call self.ActionInTarget('earlier 1f')
endf

fun! s:undotree.ActionNextSavedState() abort
    call self.ActionInTarget('later 1f')
endf

fun! s:undotree.ActionDiffToggle() abort
    let self.opendiff = !self.opendiff
    call t:diffpanel.Toggle()
    call self.UpdateDiff()
endf

fun! s:undotree.ActionTimestampToggle() abort
    if !self.SetTargetFocus()
        return
    en
    let g:undotree_RelativeTimestamp = !g:undotree_RelativeTimestamp
    let self.targetBufnr = -1 "force update
    call self.Update()
    " Update not always set current focus.
    call self.SetFocus()
endf

fun! s:undotree.ActionClearHistory() abort
    if input("Clear ALL undo history? Type \"YES\" to continue: ") != "YES"
        return
    en
    if !self.SetTargetFocus()
        return
    en
    let ul_bak = &undolevels
    let &undolevels = -1
    call s:exec("norm! a \<BS>\<Esc>")
    let &undolevels = ul_bak
    unlet ul_bak
    let self.targetBufnr = -1 "force update
    call self.Update()
endf

fun! s:undotree.ActionClose() abort
    call self.Toggle()
endf

fun! s:undotree.UpdateDiff() abort
    call s:log("undotree.UpdateDiff()")
    if !t:diffpanel.IsVisible()
        return
    en
    call t:diffpanel.Update(self.seq_cur,self.targetBufnr,self.targetid)
endf

" May fail due to target window closed.
fun! s:undotree.SetTargetFocus() abort
    for win_num in range(1, winnr('$')) "winnr starts from 1
        if getwinvar(win_num, 'undotree_id') == self.targetid
            if winnr() != win_num
                call s:exec("norm! ".win_num."\<c-w>\<c-w>")
                return 1
            en
        en
    endfor
    return 0
endf

fun! s:undotree.Toggle() abort
    "Global auto commands to keep undotree up to date.
    let auEvents = "BufEnter,InsertLeave,CursorMoved,BufWritePost"

    " echom 'self.bufname'
    " echom self.bufname
    call s:log(self.bufname." Toggle()")
    if self.IsVisible()
        call self.Hide()
        call t:diffpanel.Hide()
        call self.SetTargetFocus()
        augroup Undotree
            autocmd!
        augroup END
    el
        call self.Show()
        if !g:undotree_SetFocusWhenToggle
            call self.SetTargetFocus()
        en
        augroup Undotree
            au!
            exec "au! ".auEvents." * call undotree#UndotreeUpdate()"
        augroup END
    en
endf

fun! s:undotree.GetStatusLine() abort
    if self.seq_cur != -1
        let seq_cur = self.seq_cur
    el
        let seq_cur = 'None'
    en
    if self.seq_curhead != -1
        let seq_curhead = self.seq_curhead
    el
        let seq_curhead = 'None'
    en
    return 'current: '.seq_cur.' redo: '.seq_curhead
endf

fun! s:undotree.Show() abort
    call s:log("undotree.Show()")
    if self.IsVisible()
        return
    en

    let self.targetid = w:undotree_id

    " Create undotree window.
    if exists("g:undotree_CustomUndotreeCmd")
        let cmd = g:undotree_CustomUndotreeCmd . ' ' .
                    \self.bufname
    elseif g:undotree_WindowLayout == 1 || g:undotree_WindowLayout == 2
        let cmd = "topleft vertical" .
                    \self.width . ' new ' . self.bufname
    el
        let cmd = "botright vertical" .
                    \self.width . ' new ' . self.bufname
    en
    call s:exec("silent keepalt ".cmd)
    call self.SetFocus()

    " We need a way to tell if the buffer is belong to undotree,
    " bufname() is not always reliable.
    let b:isUndotreeBuffer = 1

    setl     winfixwidth
    setl     noswapfile
    setl     buftype=nowrite
    setl     bufhidden=delete
    setl     nowrap
    setl     foldcolumn=0
    setl     nobuflisted
    setl     nospell
    setl     nonumber
    setl     norelativenumber
    if g:undotree_CursorLine
        setl     cursorline
    el
        setl     nocursorline
    en
    setl     nomodifiable
    setl     statusline=%!t:undotree.GetStatusLine()
    setfiletype undotree

    call self.BindKey()
    call self.BindAu()

    let ei_bak= &eventignore
    set eventignore=all

    call self.SetTargetFocus()
    let self.targetBufnr = -1 "force update
    call self.Update()

    let &eventignore = ei_bak

    if self.opendiff
        call t:diffpanel.Show()
        call self.UpdateDiff()
    en
endf

" called outside undotree window
fun! s:undotree.Update() abort
    if !self.IsVisible()
        return
    en
    " do nothing if we're in the undotree or diff panel
    if exists('b:isUndotreeBuffer')
        return
    en
    if (&bt != '' && &bt != 'acwrite') || (&modifiable == 0) || (mode() != 'n')
        if &bt == 'quickfix' || &bt == 'nofile'
            "Do nothing for quickfix and q:
            call s:log("undotree.Update() ignore quickfix")
            return
        en
        if self.targetBufnr == bufnr('%') && self.targetid == w:undotree_id
            call s:log("undotree.Update() invalid buffer NOupdate")
            return
        en
        let emptybuf = 1 "This is not a valid buffer, could be help or something.
        call s:log("undotree.Update() invalid buffer update")
    el
        let emptybuf = 0
        "update undotree,set focus
        if self.targetBufnr == bufnr('%')
            let self.targetid = w:undotree_id
            let newrawtree = undotree()
            if self.rawtree == newrawtree
                return
            en

            " same buffer, but seq changed.
            if newrawtree.seq_last == self.seq_last
                call s:log("undotree.Update() update seqs")
                let self.rawtree = newrawtree
                call self.ConvertInput(0) "only update seqs.
                if (self.seq_cur == self.seq_cur_bak) &&
                            \(self.seq_curhead == self.seq_curhead_bak)&&
                            \(self.seq_newhead == self.seq_newhead_bak)&&
                            \(self.save_last == self.save_last_bak)
                    return
                en
                call self.SetFocus()
                call self.MarkSeqs()
                call self.UpdateDiff()
                return
            en
        en
    en
    call s:log("undotree.Update() update whole tree")

    let self.targetBufnr = bufnr('%')
    let self.targetid = w:undotree_id
    if emptybuf " Show an empty undo tree instead of do nothing.
        let self.rawtree = {'seq_last':0,'entries':[],'time_cur':0,'save_last':0,'synced':1,'save_cur':0,'seq_cur':0}
    el
        let self.rawtree = undotree()
    en
    let self.seq_last = self.rawtree.seq_last
    let self.seq_cur = -1
    let self.seq_curhead = -1
    let self.seq_newhead = -1
    call self.ConvertInput(1) "update all.
    call self.Render()
    call self.SetFocus()
    call self.Draw()
    call self.MarkSeqs()
    call self.UpdateDiff()
endf

fun! s:undotree.AppendHelp() abort
    if self.showHelp
        call append(0,'') "empty line
        for i in s:keymap
            call append(0,'" '.i[1].' : '.i[2])
        endfor
        call append(0,s:helpmore)
    el
        if g:undotree_HelpLine
            call append(0,'')
        en
        call append(0,s:helpless)
    en
endf

fun! s:undotree.Index2Screen(index) abort
    " index starts from zero
    let index_padding = 1
    let empty_line = 1
    let lineNr = a:index + index_padding + empty_line
    " calculate line number according to the help text.
    " index starts from zero and lineNr starts from 1
    if self.showHelp
        let lineNr += len(s:keymap) + len(s:helpmore)
    el
        let lineNr += len(s:helpless)
        if !g:undotree_HelpLine
            let lineNr -= empty_line
        en
    en
    return lineNr
endf

" <0 if index is invalid.
" e.g. current line is in help text.
fun! s:undotree.Screen2Index(line) abort
    let index_padding = 1
    let empty_line = 1
    let index = a:line - index_padding - empty_line

    if self.showHelp
        let index -= len(s:keymap) + len(s:helpmore)
    el
        let index -= len(s:helpless)
        if !g:undotree_HelpLine
            let index += empty_line
        en
    en
    return index
endf

" Current window must be undotree.
fun! s:undotree.Draw() abort
    " remember the current cursor position.
    let savedview = winsaveview()

    setl     modifiable
    " Delete text into blackhole register.
    call s:exec('1,$ d _')
    call append(0,self.asciitree)

    call self.AppendHelp()

    "remove the last empty line
    call s:exec('$d _')

    " restore previous cursor position.
    call winrestview(savedview)

    setl     nomodifiable
endf

fun! s:undotree.MarkSeqs() abort
    call s:log("bak(cur,curhead,newhead): ".
                \self.seq_cur_bak.' '.
                \self.seq_curhead_bak.' '.
                \self.seq_newhead_bak)
    call s:log("(cur,curhead,newhead): ".
                \self.seq_cur.' '.
                \self.seq_curhead.' '.
                \self.seq_newhead)
    setl     modifiable
    " reset bak seq lines.
    if self.seq_cur_bak != -1
        let index = self.seq2index[self.seq_cur_bak]
        call setline(self.Index2Screen(index),self.asciitree[index])
    en
    if self.seq_curhead_bak != -1
        let index = self.seq2index[self.seq_curhead_bak]
        call setline(self.Index2Screen(index),self.asciitree[index])
    en
    if self.seq_newhead_bak != -1
        let index = self.seq2index[self.seq_newhead_bak]
        call setline(self.Index2Screen(index),self.asciitree[index])
    en
    " mark save seqs
    for i in keys(self.seq_saved)
        let index = self.seq2index[self.seq_saved[i]]
        let lineNr = self.Index2Screen(index)
        call setline(lineNr,substitute(self.asciitree[index],
                    \' \d\+  \zs \ze','s',''))
    endfor
    let max_saved_num = max(keys(self.seq_saved))
    if max_saved_num > 0
        let lineNr = self.Index2Screen(self.seq2index[self.seq_saved[max_saved_num]])
        call setline(lineNr,substitute(getline(lineNr),'s','S',''))
    en
    " mark new seqs.
    if self.seq_cur != -1
        let index = self.seq2index[self.seq_cur]
        let lineNr = self.Index2Screen(index)
        call setline(lineNr,substitute(getline(lineNr),
                    \'\zs \(\d\+\) \ze [sS ] ','>\1<',''))
        " move cursor to that line.
        call s:exec("normal! " . lineNr . "G")
    en
    if self.seq_curhead != -1
        let index = self.seq2index[self.seq_curhead]
        let lineNr = self.Index2Screen(index)
        call setline(lineNr,substitute(getline(lineNr),
                    \'\zs \(\d\+\) \ze [sS ] ','{\1}',''))
    en
    if self.seq_newhead != -1
        let index = self.seq2index[self.seq_newhead]
        let lineNr = self.Index2Screen(index)
        call setline(lineNr,substitute(getline(lineNr),
                    \'\zs \(\d\+\) \ze [sS ] ','[\1]',''))
    en
    setl     nomodifiable
endf

" tree node class
let s:node = {}

fun! s:node.Init() abort
    let self.seq = -1
    let self.p = []
    let self.time = -1
endf

fun! s:undotree._parseNode(in,out) abort
    " type(in) == type([]) && type(out) == type({})
    if empty(a:in) "empty
        return
    en
    let curnode = a:out
    for i in a:in
        if has_key(i,'alt')
            call self._parseNode(i.alt,curnode)
        en
        let newnode = s:new(s:node)
        let newnode.seq = i.seq
        let newnode.time = i.time
        if has_key(i,'newhead')
            let self.seq_newhead = i.seq
        en
        if has_key(i,'curhead')
            let self.seq_curhead = i.seq
            let self.seq_cur = curnode.seq
        en
        if has_key(i,'save')
            let self.seq_saved[i.save] = i.seq
        en
        call extend(curnode.p,[newnode])
        let curnode = newnode
    endfor
endf

"Sample:
"let s:test={'seq_last': 4, 'entries': [{'seq': 3, 'alt': [{'seq': 1, 'time': 1345131443}, {'seq': 2, 'time': 1345131445}], 'time': 1345131490}, {'seq': 4, 'time': 1345131492, 'newhead': 1}], 'time_cur': 1345131493, 'save_last': 0, 'synced': 0, 'save_cur': 0, 'seq_cur': 4}

" updatetree: 0: no update, just assign seqs;  1: update and assign seqs.
fun! s:undotree.ConvertInput(updatetree) abort
    "reset seqs
    let self.seq_cur_bak = self.seq_cur
    let self.seq_curhead_bak = self.seq_curhead
    let self.seq_newhead_bak = self.seq_newhead
    let self.save_last_bak = self.save_last

    let self.seq_cur = -1
    let self.seq_curhead = -1
    let self.seq_newhead = -1
    let self.seq_saved = {}

    "Generate root node
    let root = s:new(s:node)
    let root.seq = 0
    let root.time = 0

    call self._parseNode(self.rawtree.entries,root)

    let self.save_last = self.rawtree.save_last
    " Note: Normally, the current node should be the one that seq_cur points to,
    " but in fact it's not. May be bug, bug anyway I found a workaround:
    " first try to find the parent node of 'curhead', if not found, then use
    " seq_cur.
    if self.seq_cur == -1
        let self.seq_cur = self.rawtree.seq_cur
    en
    " undo history is cleared
    if empty(self.rawtree.entries)
        let self.seq_cur = 0
    en
    if a:updatetree
        let self.tree = root
    en
endf

"=================================================
" Ascii undo tree generator
"
" Example:
" 6 8  7
" |/   |
" 2    4
"  \   |
"   1  3  5
"    \ | /
"      0

" Tree sieve, p:fork, x:none
"
" x         8
" 8x        | 7
" 87         \ \
" x87       6 | |
" 687       |/ /
" p7x       | | 5
" p75       | 4 |
" p45       | 3 |
" p35       | |/
" pp        2 |
" 2p        1 |
" 1p        |/
" p         0
" 0
"
" Data sample:
"let example = {'seq':0,'p':[{'seq':1,'p':[{'seq':2,'p':[{'seq':6,'p':[]},{'seq':8,'p':[]}]}]},{'seq':3,'p':[{'seq':4,'p':[{'seq':7,'p':[]}]}]},{'seq':5,'p':[]}]}
"
" Convert self.tree -> self.asciitree
fun! s:undotree.Render() abort
    " We gonna modify self.tree so we'd better make a copy first.
    " Cannot make a copy because variable nested too deep, gosh.. okay,
    " fine..
    " let tree = deepcopy(self.tree)
    let tree = self.tree
    let slots = [tree]
    let out = []
    let outmeta = []
    let seq2index = {}
    let TYPE_E = type({})
    let TYPE_P = type([])
    let TYPE_X = type('x')
    while slots != []
        "find next node
        let foundx = 0 " 1 if x element is found.
        let index = 0 " Next element to be print.

        " Find x element first.
        for i in range(len(slots))
            if type(slots[i]) == TYPE_X
                let foundx = 1
                let index = i
                break
            en
        endfor

        " Then, find the element with minimun seq.
        let minseq = 99999999
        let minnode = {}
        if foundx == 0
            "assume undo level isn't more than this... of course
            for i in range(len(slots))
                if type(slots[i]) == TYPE_E
                    if slots[i].seq < minseq
                        let minseq = slots[i].seq
                        let index = i
                        let minnode = slots[i]
                        continue
                    en
                en
                if type(slots[i]) == TYPE_P
                    for j in slots[i]
                        if j.seq < minseq
                            let minseq = j.seq
                            let index = i
                            let minnode = j
                            continue
                        en
                    endfor
                en
            endfor
        en

        " output.
        let onespace = " "
        let newline = onespace
        let newmeta = {}
        let node = slots[index]
        if type(node) == TYPE_X
            let newmeta = s:new(s:node) "invalid node.
            if index+1 != len(slots) " not the last one, append '\'
                for i in range(len(slots))
                    if i < index
                        let newline = newline.g:undotree_TreeVertShape.' '
                    en
                    if i > index
                        let newline = newline.' '.g:undotree_TreeReturnShape
                    en
                endfor
            en
            call remove(slots,index)
        en
        if type(node) == TYPE_E
            let newmeta = node
            let seq2index[node.seq]=len(out)
            for i in range(len(slots))
                if index == i
                    let newline = newline.g:undotree_TreeNodeShape.' '
                el
                    let newline = newline.g:undotree_TreeVertShape.' '
                en
            endfor
            let newline = newline.'   '.(node.seq).'    '.
                        \'('.s:gettime(node.time).')'
            " update the printed slot to its child.
            if empty(node.p)
                let slots[index] = 'x'
            en
            if len(node.p) == 1 "only one child.
                let slots[index] = node.p[0]
            en
            if len(node.p) > 1 "insert p node
                let slots[index] = node.p
            en
            let node.p = [] "cut reference.
        en
        if type(node) == TYPE_P
            let newmeta = s:new(s:node) "invalid node.
            for k in range(len(slots))
                if k < index
                    let newline = newline.g:undotree_TreeVertShape." "
                en
                if k == index
                    let newline = newline.g:undotree_TreeVertShape.g:undotree_TreeSplitShape." "
                en
                if k > index
                    let newline = newline.g:undotree_TreeSplitShape." "
                en
            endfor
            call remove(slots,index)
            if len(node) == 2
                if node[0].seq > node[1].seq
                    call insert(slots,node[1],index)
                    call insert(slots,node[0],index)
                el
                    call insert(slots,node[0],index)
                    call insert(slots,node[1],index)
                en
            en
            " split P to E+P if elements in p > 2
            if len(node) > 2
                call remove(node,index(node,minnode))
                call insert(slots,minnode,index)
                call insert(slots,node,index)
            en
        en
        unlet node
        if newline != onespace
            let newline = substitute(newline,'\s*$','','g') "remove trailing space.
            call insert(out,newline,0)
            call insert(outmeta,newmeta,0)
        en
    endwhile
    let self.asciitree = out
    let self.asciimeta = outmeta
    " revert index.
    let totallen = len(out)
    for i in keys(seq2index)
        let seq2index[i] = totallen - 1 - seq2index[i]
    endfor
    let self.seq2index = seq2index
endf

"=================================================
"diff panel
let s:diffpanel = s:new(s:panel)

fun! s:diffpanel.Update(seq,targetBufnr,targetid) abort
    call s:log('diffpanel.Update(),seq:'.a:seq.' bufname:'.bufname(a:targetBufnr))
    if !self.diffexecutable
        return
    en
    let diffresult = []
    let self.changes.add = 0
    let self.changes.del = 0

    if a:seq == 0
        let diffresult = []
    el
        if has_key(self.cache,a:targetBufnr.'_'.a:seq)
            call s:log("diff cache hit.")
            let diffresult = self.cache[a:targetBufnr.'_'.a:seq]
        el
            " Double check the target winnr and bufnr
            let targetWinnr = -1
            for winnr in range(1, winnr('$')) "winnr starts from 1
                if (getwinvar(winnr,'undotree_id') == a:targetid)
                            \&& winbufnr(winnr) == a:targetBufnr
                    let targetWinnr = winnr
                en
            endfor
            if targetWinnr == -1
                return
            en

            let ei_bak = &eventignore
            set eventignore=all

            call s:exec_silent(targetWinnr." wincmd w")

            " remember and restore cursor and window position.
            let savedview = winsaveview()

            let new = getbufline(a:targetBufnr,'^','$')
            silent undo
            let old = getbufline(a:targetBufnr,'^','$')
            silent redo

            call winrestview(savedview)

            " diff files.
            let tempfile1 = tempname()
            let tempfile2 = tempname()
            if writefile(old,tempfile1) == -1
                echoerr "Can not write to temp file:".tempfile1
            en
            if writefile(new,tempfile2) == -1
                echoerr "Can not write to temp file:".tempfile2
            en
            let diffresult = split(system(g:undotree_DiffCommand.' '.tempfile1.' '.tempfile2),"\n")
            call s:log("diffresult: ".string(diffresult))
            if delete(tempfile1) != 0
                echoerr "Can not delete temp file:".tempfile1
            en
            if delete(tempfile2) != 0
                echoerr "Can not delete temp file:".tempfile2
            en
            let &eventignore = ei_bak
            "Update cache
            let self.cache[a:targetBufnr.'_'.a:seq] = diffresult
        en
    en

    call self.ParseDiff(diffresult, a:targetBufnr)

    call self.SetFocus()

    setl     modifiable
    call s:exec('1,$ d _')

    call append(0,diffresult)
    call append(0,'- seq: '.a:seq.' -')

    "remove the last empty line
    if getline("$") == ""
        call s:exec('$d _')
    en
    call s:exec('norm! gg') "move cursor to line 1.
    setl     nomodifiable
    call t:undotree.SetFocus()
endf

fun! s:diffpanel.ParseDiff(diffresult, targetBufnr) abort
    " set target focus first.
    call t:undotree.SetTargetFocus()

    " If 'a:diffresult' is empty then there are no new signs to place. However,
    " we need to ensure any old signs are removed. This is especially important
    " if we are at the very first sequence, otherwise signs get left
    if (exists("w:undotree_diffsigns"))
        while w:undotree_diffsigns > 0
            exe 'sign unplace '.s:signId
            let w:undotree_diffsigns -= 1
        endwhile
    en

    if empty(a:diffresult)
        return
    en

    " clear previous highlighted syntax
    " matchadd associates with windows.
    if exists("w:undotree_diffmatches")
        for i in w:undotree_diffmatches
            call matchdelete(i)
        endfor
    en

    let w:undotree_diffmatches = []
    let w:undotree_diffsigns = 0
    let lineNr = 0
    let l:lastLine = line('$')
    for line in a:diffresult
        let matchnum = matchstr(line,'^[0-9,\,]*[acd]\zs\d*\ze')
        if !empty(matchnum)
            let lineNr = str2nr(matchnum)
            let matchwhat = matchstr(line,'^[0-9,\,]*\zs[acd]\ze\d*')
            if matchwhat ==# 'd'
                if g:undotree_HighlightChangedWithSign
                    " Normally, for a 'delete' change, the line number we have is always 1 less than the line we
                    " need to place the sign at, hence '+ 1'
                    " However, if the very end of the buffer has been deleted then this is not possible (because
                    " that bit of the buffer no longer exists), so we place a 'special' version of the 'delete'
                    " sign on what is the last available line)
                    exe 'sign place '.s:signId.' line='.((lineNr < l:lastLine) ? lineNr + 1 : l:lastLine).' name='.((lineNr < l:lastLine) ? 'UndotreeDel' : 'UndotreeDelEnd').' buffer='.a:targetBufnr
                    let w:undotree_diffsigns += 1
                en

                let matchnum = 0
                let matchwhat = ''
            en
            continue
        en
        if matchstr(line,'^<.*$') != ''
            let self.changes.del += 1
        en

        let matchtext = matchstr(line,'^>\zs .*$')
        if empty(matchtext)
            continue
        en

        let self.changes.add += 1
        if g:undotree_HighlightChangedText
            if matchtext != ' '
                let matchtext = '\%'.lineNr.'l\V'.escape(matchtext[1:],'"\') "remove beginning space.
                call s:log("matchadd(".matchwhat.") ->  ".matchtext)
                call add(w:undotree_diffmatches,matchadd((matchwhat ==# 'a' ? g:undotree_HighlightSyntaxAdd : g:undotree_HighlightSyntaxChange),matchtext))
            en
        en

        if g:undotree_HighlightChangedWithSign
            exe 'sign place '.s:signId.' line='.lineNr.' name='.(matchwhat ==# 'a' ? 'UndotreeAdd' : 'UndotreeChg').' buffer='.a:targetBufnr
            let w:undotree_diffsigns += 1
        en

        let lineNr = lineNr+1
    endfor
endf

fun! s:diffpanel.GetStatusLine() abort
    let max = winwidth(0) - 4
    let sum = self.changes.add + self.changes.del
    if sum > max
        let add = self.changes.add * max / sum + 1
        let del = self.changes.del * max / sum + 1
    el
        let add = self.changes.add
        let del = self.changes.del
    en
    return string(sum).' '.repeat('+',add).repeat('-',del)
endf

fun! s:diffpanel.Init() abort
    let self.bufname = "diffpanel_".s:getUniqueID()
    let self.cache = {}
    let self.changes = {'add':0, 'del':0}
    let self.diffexecutable = executable('diff')
    if !self.diffexecutable
        echoerr '"diff" is not executable.'
    en
endf

fun! s:diffpanel.Toggle() abort
    call s:log(self.bufname." Toggle()")
    if self.IsVisible()
        call self.Hide()
    el
        call self.Show()
    en
endf

fun! s:diffpanel.Show() abort
    call s:log("diffpanel.Show()")
    if self.IsVisible()
        return
    en
    " Create diffpanel window.
    call t:undotree.SetFocus() "can not exist without undotree
    " remember and restore cursor and window position.
    let savedview = winsaveview()

    let ei_bak= &eventignore
    set eventignore=all

    if exists("g:undotree_CustomDiffpanelCmd")
        let cmd = g:undotree_CustomDiffpanelCmd.' '.self.bufname
    elseif g:undotree_WindowLayout == 1 || g:undotree_WindowLayout == 3
        let cmd = 'belowright '.g:undotree_DiffpanelHeight.'new '.self.bufname
    el
        let cmd = 'botright '.g:undotree_DiffpanelHeight.'new '.self.bufname
    en
    call s:exec_silent(cmd)

    let b:isUndotreeBuffer = 1

    setl     winfixwidth
    setl     winfixheight
    setl     noswapfile
    setl     buftype=nowrite
    setl     bufhidden=delete
    setl     nowrap
    setl     nobuflisted
    setl     nospell
    setl     nonumber
    setl     norelativenumber
    setl     nocursorline
    setl     nomodifiable
    setl     statusline=%!t:diffpanel.GetStatusLine()

    let &eventignore = ei_bak

    " syntax need filetype autocommand
    setfiletype diff
    setl     foldcolumn=0
    setl     nofoldenable

    call self.BindAu()
    call t:undotree.SetFocus()
    call winrestview(savedview)
endf

fun! s:diffpanel.BindAu() abort
    " Auto exit if it's the last window or undotree closed.
    augroup Undotree_Diff
        au!
        au BufEnter <buffer> call s:exitIfLast()
        au BufEnter <buffer> if !t:undotree.IsVisible()
                    \|call t:diffpanel.Hide() |endif
    augroup end
endf

fun! s:diffpanel.CleanUpHighlight() abort
    call s:log("CleanUpHighlight()")
    " save current position
    let curwinnr = winnr()
    let savedview = winsaveview()

    " clear w:undotree_diffmatches in all windows.
    let winnum = winnr('$')
    for i in range(1,winnum)
        call s:exec_silent("norm! ".i."\<c-w>\<c-w>")
        if exists("w:undotree_diffmatches")
            for j in w:undotree_diffmatches
                call matchdelete(j)
            endfor
            let w:undotree_diffmatches = []
        en
        if (exists("w:undotree_diffsigns"))
            while w:undotree_diffsigns > 0
                exe 'sign unplace '.s:signId
                let w:undotree_diffsigns -= 1
            endwhile
        en
    endfor

    "restore position
    call s:exec_silent("norm! ".curwinnr."\<c-w>\<c-w>")
    call winrestview(savedview)
endf

fun! s:diffpanel.Hide() abort
    call s:log(self.bufname." Hide()")
    if !self.IsVisible()
        return
    en
    call self.SetFocus()
    call s:exec("quit")
    call self.CleanUpHighlight()
endf

"=================================================
" It will set the target of undotree window to the current editing buffer.
fun! s:undotreeAction(action) abort
    call s:log("undotreeAction()")
    if !exists('t:undotree')
        echoerr "Fatal: t:undotree does not exist!"
        return
    en
    call t:undotree.Action(a:action)
endf

fun! s:exitIfLast() abort
    let num = 0
    if exists('t:undotree') && t:undotree.IsVisible()
        let num = num + 1
    en
    if exists('t:diffpanel') && t:diffpanel.IsVisible()
        let num = num + 1
    en
    if winnr('$') == num
        if exists('t:undotree')
            call t:undotree.Hide()
        en
        if exists('t:diffpanel')
            call t:diffpanel.Hide()
        en
    en
endf

"=================================================
" User command functions
"called outside undotree window
fun! undotree#UndotreeUpdate() abort
    if !exists('t:undotree')
        return
    en
    if !exists('w:undotree_id')
        let w:undotree_id = 'id_'.s:getUniqueID()
        call s:log("Unique window id assigned: ".w:undotree_id)
    en
    " assume window layout won't change during updating.
    let thiswinnr = winnr()
    call t:undotree.Update()
    " focus moved
    if winnr() != thiswinnr
        call s:exec("norm! ".thiswinnr."\<c-w>\<c-w>")
    en
endf

fun! undotree#UndotreeToggle() abort
    try
        call s:log(">>> UndotreeToggle()")
        if !exists('w:undotree_id')
            let w:undotree_id = 'id_'.s:getUniqueID()
            call s:log("Unique window id assigned: ".w:undotree_id)
        en
        if !exists('t:undotree')
            let t:undotree = s:new(s:undotree)
            let t:diffpanel = s:new(s:diffpanel)
        en
        call t:undotree.Toggle()
        call s:log("<<< UndotreeToggle() leave")
    catch /^Vim\%((\a\+)\)\?:E11/
        echohl ErrorMsg
        echom v:exception
        echohl NONE
    endtry
endf

fun! undotree#UndotreeIsVisible() abort
    return (exists('t:undotree') && t:undotree.IsVisible())
endf

fun! undotree#UndotreeHide() abort
    if undotree#UndotreeIsVisible()
        try
            call undotree#UndotreeToggle()
        catch /^Vim\%((\a\+)\)\?:E11/
            echohl ErrorMsg
            echom v:exception
            echohl NONE
        endtry
    en
endf

fun! undotree#UndotreeShow() abort
    try
        if ! undotree#UndotreeIsVisible()
            call undotree#UndotreeToggle()
        el
            call t:undotree.SetFocus()
        en
    catch /^Vim\%((\a\+)\)\?:E11/
        echohl ErrorMsg
        echom v:exception
        echohl NONE
    endtry
endf

fun! undotree#UndotreeFocus() abort
    if undotree#UndotreeIsVisible()
        try
            call t:undotree.SetFocus()
        catch /^Vim\%((\a\+)\)\?:E11/
            echohl ErrorMsg
            echom v:exception
            echohl NONE
        endtry
    en
endf

" vim: set et fdm=marker sts=4 sw=4:
