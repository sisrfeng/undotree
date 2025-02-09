" Avoid installing twice.
if exists('g:loaded_undotree')
    finish
en
let g:loaded_undotree = 0

" At least version 7.3 with 005 patch is needed for undo branches.
if v:version < 703
    com!  -n=0 -bar UndotreeToggle :echoerr "undotree.vim needs Vim version >= 7.3"
    finish
en
if (v:version == 703 && !has("patch005"))
    com!  -n=0 -bar UndotreeToggle :echoerr "undotree.vim needs vim7.3 with patch005 applied."
    finish
en
let g:loaded_undotree = 1   " Signal plugin availability with a value of 1.

"=================================================
"Options:

" Window layout
" Style 3
" +------------------------+----------+
" |                        |          |
" |                        |          |
" |                        | undotree |
" |                        |          |
" |                        |          |
" |                        +----------+
" |                        |          |
" |                        |   diff   |
" |                        |          |
" +------------------------+----------+
" Style 4
" +-----------------------++----------+
" |                        |          |
" |                        |          |
" |                        | undotree |
" |                        |          |
" |                        |          |
" +------------------------+----------+
" |                                   |
" |                            diff   |
" |                                   |
" +-----------------------------------+
if !exists('g:undotree_WindowLayout')
    let g:undotree_WindowLayout = 1
en

" e.g. using 'd' instead of 'days' to save some space.
if !exists('g:undotree_ShortIndicators')
    let g:undotree_ShortIndicators = 0
en

" undotree window width
if !exists('g:undotree_SplitWidth')
    if g:undotree_ShortIndicators == 1
        let g:undotree_SplitWidth = 24
    el
        let g:undotree_SplitWidth = 30
    en
en

" diff window height
if !exists('g:undotree_DiffpanelHeight')
    let g:undotree_DiffpanelHeight = 10
en

" auto open diff window
if !exists('g:undotree_DiffAutoOpen')
    let g:undotree_DiffAutoOpen = 1
en

" if set, let undotree window get focus after being opened, otherwise
" focus will stay in current window.
if !exists('g:undotree_SetFocusWhenToggle')
    let g:undotree_SetFocusWhenToggle = 0
en

" tree node shape.
if !exists('g:undotree_TreeNodeShape')
    let g:undotree_TreeNodeShape = '*'
en

" tree vertical shape.
if !exists('g:undotree_TreeVertShape')
    let g:undotree_TreeVertShape = '|'
en

" tree split shape.
if !exists('g:undotree_TreeSplitShape')
    let g:undotree_TreeSplitShape = '/'
en

" tree return shape.
if !exists('g:undotree_TreeReturnShape')
    let g:undotree_TreeReturnShape = '\'
en

if !exists('g:undotree_DiffCommand')
    let g:undotree_DiffCommand = "diff"
en

" relative timestamp
if !exists('g:undotree_RelativeTimestamp')
    let g:undotree_RelativeTimestamp = 1
en

" Highlight changed text
if !exists('g:undotree_HighlightChangedText')
    let g:undotree_HighlightChangedText = 1
en

" Highlight changed text using signs in the gutter
if !exists('g:undotree_HighlightChangedWithSign')
    let g:undotree_HighlightChangedWithSign = 1
en

" Highlight linked syntax type.
" You may chose your favorite through ":hi" command
if !exists('g:undotree_HighlightSyntaxAdd')
    let g:undotree_HighlightSyntaxAdd = "DiffAdd"
en
if !exists('g:undotree_HighlightSyntaxChange')
    let g:undotree_HighlightSyntaxChange = "DiffChange"
en
if !exists('g:undotree_HighlightSyntaxDel')
    let g:undotree_HighlightSyntaxDel = "DiffDelete"
en

" Deprecates the old style configuration.
if exists('g:undotree_SplitLocation')
    echo "g:undotree_SplitLocation is deprecated,
                \ please use g:undotree_WindowLayout instead."
en

" Show help line
if !exists('g:undotree_HelpLine')
    let g:undotree_HelpLine = 1
en

" Show cursorline
if !exists('g:undotree_CursorLine')
    let g:undotree_CursorLine = 1
en

"=================================================
" User commands.
com!  -n=0 -bar UndotreeToggle   :call undotree#UndotreeToggle()
com!  -n=0 -bar UndotreeHide     :call undotree#UndotreeHide()
com!  -n=0 -bar UndotreeShow     :call undotree#UndotreeShow()
com!  -n=0 -bar UndotreeFocus    :call undotree#UndotreeFocus()

" vim: set et fdm=marker sts=4 sw=4:
