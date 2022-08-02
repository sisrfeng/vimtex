fun! vimtex#syntax#nested#include(name) abort
    let l:inc_name = 'vimtex_nested_' . a:name

    if !has_key(s:included, l:inc_name)
        let s:included[l:inc_name] = s:include(l:inc_name, a:name)
    en

    return s:included[l:inc_name]
            \ ? l:inc_name
            \ : ''
endf


fun! vimtex#syntax#nested#reset() abort
    let s:included = {'vimtex_nested_tex': 0}
endf

let s:included = {'vimtex_nested_tex': 0}



fun! s:include(cluster, name) abort
    let l:name = get(g:vimtex_syntax_nested.aliases, a:name, a:name)
    let l:path = 'syntax/' . l:name . '.vim'

    if empty(globpath(&runtimepath, l:path)) | return 0 | endif

    try
        call s:hooks_{l:name}_before()
    catch /E117/
    endtry

    unlet b:current_syntax
    exe  'syntax include @' . a:cluster l:path
    let b:current_syntax = 'tex'

    for l:ignored_group in get(g:vimtex_syntax_nested.ignored, l:name, [])
        exe  'syntax cluster' a:cluster 'remove=' . l:ignored_group
    endfor

    try
        call s:hooks_{l:name}_after()
    catch /E117/
    endtry

    return 1
endf



fun! s:hooks_dockerfile_before() abort
    " $VIMRUNTIME/syntax/dockerfile.vim
    " does something it should not do -
    " it sets the commentstring option
    " (which should rather be done within  a filetype-plugin).
    " We use the hooks to save then restore the option here.
    let s:commentstring = &l:commentstring
endf


fun! s:hooks_dockerfile_after() abort
    let &l:commentstring = s:commentstring
    syn  cluster vimtex_nested_dockerfile remove=dockerfileLinePrefix
endf


