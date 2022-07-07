function! vimtex#parser#toc#todo_comments#new() abort
  return s:matcher
endfunction



let s:matcher = {
      \ 'in_preamble' : 1,
      \ 'prefilter_re' : '\%\s*%('
      \   . join(keys(g:vimtex_toc_todo_labels), '|') . ')',
      \ 'priority' : 2,
      \ 're' : g:vimtex#re#not_bslash . '\%\s+('
      \   . join(keys(g:vimtex_toc_todo_labels), '|') . ')[ :]+\s*(.*)',
      \}
function! s:matcher.get_entry(context) abort dict
  let [l:type, l:text] = matchlist(a:context.line, self.re)[1:2]
  let l:label = g:vimtex_toc_todo_labels[toupper(l:type)]

  return {
        \ 'title'  : l:label . l:text,
        \ 'number' : '',
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'todo',
        \ }
endfunction


