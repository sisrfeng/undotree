exe  "syn match UndotreeNode ' \\zs".escape(g:undotree_TreeNodeShape,'*')."\\ze '"
exe  "syn match UndotreeNodeCurrent '\\zs" . escape(g:undotree_TreeNodeShape, '*' ) . "\\ze.*>\d\+<'"

syn match UndotreeTimeStamp '(.*)$'

syn match UndotreeFirstNode 'Original'

exe  "syn match UndotreeBranch '[" . escape(g:undotree_TreeVertShape.g:undotree_TreeSplitShape.g:undotree_TreeReturnShape, '\') . "]'"

"\ sequence?  序号
syn match UndotreeSeq         '\zs\d\+\ze '

"\ 靠/home/wf/dotF/cfg/nvim/conceal_fast.vim里的Bye_undotree 封印括号
    syn match UndotreeCurrent     '>\zs\d\+\ze<'
    syn match UndotreeNext        '{\d\+}'
    syn match UndotreeHead        '\[\d\+]'

    hi   UndotreeNext         gui=none guifg=#00aadd guibg=none
    hi  def  link  UndotreeCurrent      In_VictoR
    hi  def  link  UndotreeHead         Identifier

syn match UndotreeHelp        '^".*$' contains=UndotreeHelpKey,UndotreeHelpTitle
syn match UndotreeHelpKey     '^" \zs.\{-}\ze:' contained
syn match UndotreeHelpTitle   '===.*===' contained

syn match UndotreeSavedSmall  '\zss\ze '
syn match UndotreeSavedBig    '\zsS\ze '

hi  def  link  UndotreeNode         Fade_out
hi  def  link  UndotreeNodeCurrent  Statement
hi  def  link  UndotreeTimeStamp    Normal
hi  def  link  UndotreeFirstNode    Function
hi  def  link  UndotreeBranch       Normal
hi  def  link  UndotreeSeq          Fade_out
hi  def  link  UndotreeHelp         Comment
hi  def  link  UndotreeHelpKey      Function
hi  def  link  UndotreeHelpTitle    Type
hi  def  link  UndotreeSavedSmall   Type
hi  def  link  UndotreeSavedBig     MatchParen

" Description: undotree syntax
        " Author: Ming Bai <mbbill@gmail.com>
        " License: BSD

