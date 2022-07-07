fun! vimtex#parser#toc#include#new() abort
    return s:matcher
endf

let s:matcher = {
        \ 'in_preamble'    : 1,
        \ 'prefilter_cmds' : ['input', 'include', 'import', 'subfile'],
        \ 'priority'       : 0,
        \ 're'             : vimtex#re#tex_input . '\zs\f{-}\s*\ze\}',
        \}

fun! s:matcher.get_entry(context) abort dict
    let l:file = vimtex#parser#tex#input_parser(
                \ a:context.line, a:context.file, b:vimtex.root)

    let l:file = simplify(fnamemodify(l:file, ':~:.'))

    return {
     \ 'title': '  ' . (strlen(l:file) < 70
                \          ? l:file
                \          : l:file[0:30] . '...' . l:file[-36:]),
     \ 'number' : '',
     \ 'file'   : l:file,
     \ 'line'   : 1,
     \ 'level'  : a:context.max_level - a:context.level.current,
     \ 'rank'   : a:context.lnum_total,
     \ 'type'   : 'include',
     \ }
endf


