" VimTeX - LaTeX plugin for Vim
" Maintainer: Karl Yngve Lervåg

" some check:
    if !get(g:, 'vimtex_enabled', 1)
        " *g:vimtex_enabled*
        "     Set to 0 to disable VimTeX.
        "     Default value: Undefined.
        finish
    endif

    if exists('b:did_ftplugin')
      finish
    endif
    let b:did_ftplugin = 1

call vimtex#init()
" echom '来自TeX/ftplugin  的tex.vim     call vimtex#init()'
