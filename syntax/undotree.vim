exe  "syn match UndotreeNode ' \\zs".escape(g:undotree_TreeNodeShape,'*')."\\ze '"
exe  "syn match UndotreeNodeCurrent '\\zs" . escape(g:undotree_TreeNodeShape, '*' ) . "\\ze.*>\d\+<'"
syn match UndotreeTimeStamp '(.*)$'
syn match UndotreeFirstNode 'Original'
exe  "syn match UndotreeBranch '[" . escape(g:undotree_TreeVertShape.g:undotree_TreeSplitShape.g:undotree_TreeReturnShape, '\') . "]'"
syn match UndotreeSeq         '\zs\d\+\ze '

syn match UndotreeCurrent     '>\zs\d\+\ze<'
"\ syn match UndotreeHide     '>\ze\d\+<'
"\ hi UndotreeHide gui=none guifg=#faf4e4 guibg=#faf4e4
syn match UndotreeNext        '{\d\+}'
syn match UndotreeHead        '\[\d\+]'

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
hi  def  link  UndotreeCurrent      In_VictoR
hi  def  link  UndotreeNext         Type
hi  def  link  UndotreeHead         Identifier
hi  def  link  UndotreeHelp         Comment
hi  def  link  UndotreeHelpKey      Function
hi  def  link  UndotreeHelpTitle    Type
hi  def  link  UndotreeSavedSmall   WarningMsg
hi  def  link  UndotreeSavedBig     MatchParen

" Description: undotree syntax
        " Author: Ming Bai <mbbill@gmail.com>
        " License: BSD

