" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg

" 改了此文件要重启 因为
" let b:did_ftplugin_vimtex = 1太靠后?

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

let g:old_new_list = {
    \ 'use'                                          : 'utilize'                                     ,
    \ 'To our knowledge, no prior work has'          : 'From the our best knowledge'                 ,
    \ 'used'                                         : 'utilized'                                    ,
    \ 'Please note that'                             : 'It should be figured out that'               ,
    \ 'we show that'                                 : 'from our experiment, we conclude that'       ,
    \ 'MLP'                                          : 'multilayer perceptron'                       ,
    "\ \ 'as suggested in'                              : 'following ??'                                ,
    \ 'learning signal'                              : 'supervision'                                 ,
    \ 'in other words'                               : 'put differently'                             ,
    \ 'it is important to emphasise the fact that'   : 'Importantly'                                 ,
    \ 'as a further extension, the most recent work' : 'More recently'                               ,
    \ 'not easy'                                     : 'usually difficult'                           ,
    \ 'without any bells and whistles'               : 'with few additional complex tricks or hacks' ,
    \ 'Nevertheless'                                 : 'however'                                     ,
    \ 'moreover'                                     : "what's more"                                 ,
    \ 'rather than' : 'instead of',
    \ 'difficult'   : 'formidable',
    \ 'as a result' : 'consiquently',
    \ 'orthogonal'  : 'independent'
    \ }

" 降重: decrease same..
    " a.k.a.
    "  To overcome these difficulties
    "  among other changes.
    " Furthermore,
    " It is worth noting that
    " significant   obvious
    " as since because   as the result of
    " elimination
    " Additionally
    " Despite the simplicity
    " without any bells and whistles
    " Specifically,
    " we observe that
    " by means of
    " assume that
    " reduce the occurrence of      decrease/lessen
    " Given that
    " In particular

fun! g:Same_meaninG() abort
    for [old,new] in items(g:old_new_list)
        echom '% subs #\v<'..old..'>#'..new..'#gec'
        exe '% subs #\v<'..old..'>#'..new..'#gec'
    endfor
endf

nno  <buffer>  <leader>Sa    <cmd>call Same_meaninG()<cr>

" au AG BufRead *.tex /abstract<cr>

let g:vimtex_mappings_enabled = 1


