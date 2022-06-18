" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

fun! vimtex#text_obj#targets#enabled() abort " {{{1
    return exists('g:loaded_targets')
                \ && (   (type(g:loaded_targets) == v:t_number && g:loaded_targets)
                \     || (type(g:loaded_targets) == v:t_string && !empty(g:loaded_targets)))
                \ && (   g:vimtex_text_obj_variant ==# 'auto'
                \     || g:vimtex_text_obj_variant ==# 'targets')
endf

" }}}1
fun! vimtex#text_obj#targets#init() abort " {{{1
    let g:vimtex_text_obj_variant = 'targets'

    " Create intermediate mappings
    omap <expr> <plug>(vimtex-targets-i) targets#e('o', 'i', 'i')
    xmap <expr> <plug>(vimtex-targets-i) targets#e('x', 'i', 'i')
    omap <expr> <plug>(vimtex-targets-a) targets#e('o', 'a', 'a')
    xmap <expr> <plug>(vimtex-targets-a) targets#e('x', 'a', 'a')

    aug  vimtex_targets
        au!
        au User targets#sources         call s:init_sources()
        au User targets#mappings#plugin call s:init_mappings()
    aug  END
endf

" }}}1

fun! s:init_mappings() abort " {{{1
    call targets#mappings#extend({'e': {'tex_env': [{}]}})
    call targets#mappings#extend({'c': {'tex_cmd': [{}]}})
endf

" }}}1
fun! s:init_sources() abort " {{{1
    call targets#sources#register('tex_env', function('vimtex#text_obj#envtargets#new'))
    call targets#sources#register('tex_cmd', function('vimtex#text_obj#cmdtargets#new'))
endf

" }}}1
