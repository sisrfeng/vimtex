"\ 全文就一个函数
fun! vimtex#syntax#p#cleveref#load(cfg) abort " {{{1
" \cref, \namecref, etc
    syn  match texCmdCRef
                \ "\v\\%(%(label)?c%(page)?|C)ref>"
                \ nextgroup=texCRefArg
                \ skipwhite  skipnl
                \ conceal

    syn  match texCmdCRef
                \ "\v\\%(lc)?name[cC]refs?>"
                \ nextgroup=texCRefArg
                \ skipwhite skipnl
                \ conceal

" \crefrange,
"\ \cpagerefrange (these commands expect two arguments)
    syn  match texCmdCRef
                \ "\\c\(page\)\?refrange\>"
                \ nextgroup=texCRefRangeArg
                \ skipwhite skipnl
                \ conceal

" \label[xxx]{asd}
    syn  match texCmdCRef
            \ "\\label\>"
            \ nextgroup=texCRefOpt,texRefArg
            \ skipwhite skipnl
            \ conceal

" \crefname
    syn  match texCmdCRName
                \ "\\[cC]refname\>"
                \ nextgroup=texCRNameArgType
                \ skipwhite skipnl
                \ conceal

" Argument and option groups
  call vimtex#syntax#core#new_arg('texCRefArg', { 'contains': 'texComment,@NoSpell'}   )
  call vimtex#syntax#core#new_arg('texCRefRangeArg', {
              \ 'next'      :  'texCRefArg'          ,
              \ 'contains'  :  'texComment,@NoSpell' ,
              \})
  call vimtex#syntax#core#new_opt('texCRefOpt', {
              \ 'next': 'texRefArg',
              \ 'opts': 'oneline',
              \})
  call vimtex#syntax#core#new_arg('texCRNameArgType', {
              \ 'next'      :  'texCRNameArgSingular' ,
              \ 'contains'  :  'texComment,@NoSpell'  ,
              \})
  call vimtex#syntax#core#new_arg('texCRNameArgSingular', {
              \ 'next'      :  'texCRNameArgPlural' ,
              \ 'contains'  :  'texComment,@NoSpell'
              \})
  call vimtex#syntax#core#new_arg('texCRNameArgPlural', {'contains': 'texComment,@NoSpell'})

hi def link texCRefArg           texRefArg
hi def link texCRefOpt           texRefOpt
hi def link texCRefRangeArg      texRefArg
hi def link texCmdCRef           texCmdRef
hi def link texCmdCRName         texCmd
hi def link texCRNameArgType     texArgNew
hi def link texCRNameArgSingular texArg
hi def link texCRNameArgPlural   texCRNameArgSingular

endf

