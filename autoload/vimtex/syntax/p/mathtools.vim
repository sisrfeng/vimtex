" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#mathtools#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'mathtools') | return | endif
  let b:vimtex_syntax.mathtools = 1

  call vimtex#syntax#p#amsmath#load()

  " Support for various envionrments with option groups
  syntax match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathToolsOptPos1 "\\begin{aligned}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathToolsOptPos1 "\\begin{[lr]gathered}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathToolsOptPos1 "\\begin{[pbBvV]\?\%(small\)\?matrix\*}"
  syntax match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathToolsOptPos2 "\\begin{multlined}"
  call vimtex#syntax#core#new_opt('texMathToolsOptPos1', {'contains': ''})
  call vimtex#syntax#core#new_opt('texMathToolsOptPos2', {'contains': '', 'next': 'texMathToolsOptWidth'})
  call vimtex#syntax#core#new_opt('texMathToolsOptWidth', {'contains': 'texLength'})

  highlight def link texMathToolsOptPos1  texOpt
  highlight def link texMathToolsOptPos2  texOpt
  highlight def link texMathToolsOptWidth texOpt
endfunction

" }}}1
