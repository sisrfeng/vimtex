" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

fun! vimtex#misc#init_buffer() abort
    com!  -buffer                VimtexReload call vimtex#misc#reload()
    com!  -buffer -bang -range=% VimtexCountWords
                \ call vimtex#misc#wordcount_display({
                \   'range' : [<line1>, <line2>],
                \   'detailed' : <q-bang> == '!',
                \   'count_letters' : 0,
                \ })
    com!  -buffer -bang -range=% VimtexCountLetters
                \ call vimtex#misc#wordcount_display({
                \   'range' : [<line1>, <line2>],
                \   'detailed' : <q-bang> == '!',
                \   'count_letters' : 1,
                \ })

    nno  <buffer> <plug>(vimtex-reload) :VimtexReload<cr>
endf



fun! vimtex#misc#get_graphicspath(fname) abort
    for l:root in b:vimtex.graphicspath + ['.']
        let l:candidate = simplify(b:vimtex.root . '/' . l:root . '/' . a:fname)
        for l:suffix in ['', '.jpg', '.png', '.pdf']
            if filereadable(l:candidate . l:suffix)
                return l:candidate . l:suffix
            en
        endfor
    endfor

    return a:fname
endf


fun! vimtex#misc#wordcount(...) abort
    let l:opts = a:0 > 0 ? a:1 : {}

    let l:range = get(l:opts, 'range', [1, line('$')])
    if l:range == [1, line('$')]
        let l:file = b:vimtex
    el
        let l:file = vimtex#parser#selection_to_texfile({'range': l:range})
    en

    let l:cmd = 'texcount -nosub -sum '
                \ . (get(l:opts, 'count_letters') ? '-letter ' : '')
                \ . (get(l:opts, 'detailed') ? '-inc ' : '-q -1 -merge ')
                \ . g:vimtex_texcount_custom_arg . ' '
                \ . vimtex#util#shellescape(l:file.base)
    let l:lines = vimtex#jobs#capture(l:cmd, {'cwd': l:file.root})

    if l:file.base !=# b:vimtex.base
        call delete(l:file.tex)
    en

    if get(l:opts, 'detailed')
        return l:lines
    el
        call filter(l:lines, 'v:val !~# ''ERROR\|^\s*$''')
        return join(l:lines, '')
    en
endf


fun! vimtex#misc#wordcount_display(opts) abort
    let output = vimtex#misc#wordcount(a:opts)

    if !get(a:opts, 'detailed')
        call vimtex#log#info('Counted '
                    \ . (get(a:opts, 'count_letters') ? 'letters: ' : 'words: ')
                    \ . output)
        return
    en

    " Create wordcount window
    if bufnr('TeXcount') >= 0
        bwipeout TeXcount
    en
    split TeXcount

    " Add lines to buffer
    for line in output
        call append('$', printf('%s', line))
    endfor
    0delete _

    " Set mappings
    nno  <silent><buffer><nowait> q :bwipeout<cr>

    " Set buffer options
    setl  bufhidden=wipe
    setl  buftype=nofile
    setl  cursorline
    setl  nobuflisted
    setl  nolist
    setl  nospell
    setl  noswapfile
    setl  nowrap
    setl  tabstop=8
    setl  nomodifiable

    " Set highlighting
    syn  match TexcountText  /^.*:.*/ contains=TexcountValue
    syn  match TexcountValue /.*:\zs.*/
    hi link TexcountText  VimtexMsg
    hi link TexcountValue Constant
endf


" {{{1 function! vimtex#misc#reload()
if get(s:, 'reload_guard', 1)
    fun! vimtex#misc#reload() abort
        let s:reload_guard = 0

        for l:file in glob(fnamemodify(s:file, ':h') . '/../**/*.vim', 0, 1)
            exe  'source' l:file
        endfor

        " Temporarily unset b:current_syntax (if active)
        let l:reload_syntax = get(b:, 'current_syntax', '') ==# 'tex'
        if l:reload_syntax
            unlet b:current_syntax
        en

        call vimtex#init()

        " Reload syntax
        if l:reload_syntax
            syn  clear
            runtime! syntax/tex.vim
        en

        " Reload indent file
        if exists('b:did_vimtex_indent')
            unlet b:did_indent
            runtime indent/tex.vim
        en

        call vimtex#log#info('The plugin has been reloaded!')
        unlet s:reload_guard
    endf
en




let s:file = expand('<sfile>')
