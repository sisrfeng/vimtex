" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg

" Some checK
    if !get(g:, 'vimtex_enabled', 1)
        " *g:vimtex_enabled*
            " Set to 0 to disable VimTeX.
            " Default value: Undefined.
        " 默认情况, 不会在这里finish
      finish
    endif

    if exists('b:did_ftplugin_vimtex')
        " b:did_ftplugin常见, 加_vimtex等形式 独此一家
        finish
    endif
    let b:did_ftplugin_vimtex = 1

    " 覆盖插件里的此文件

    " Check for plugin clashes.
    " Note: This duplicates the code in health/vimtex.vim:s:check_plugin_clash()
    let s:scriptnames = vimtex#util#command('scriptnames')

    let s:latexbox = !empty(filter(copy(s:scriptnames), "v:val =~# 'latex-box'"))
    if s:latexbox
        call vimtex#log#warning([
                    \ 'Conflicting plugin detected: LaTeX-Box',
                    \ 'VimTeX does not work as expected when LaTeX-Box is installed!',
                    \ 'Please disable or remove it to use VimTeX!',
                    \])
    endif

nno <buffer> go <cmd>VimtexTocToggle<CR>
