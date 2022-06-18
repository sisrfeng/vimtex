fun! vimtex#matchparen#init_buffer() abort " {{{1
    "\ echom "g:vimtex_matchparen_enabled 是: "   g:vimtex_matchparen_enabled
    "\ 为0, 被它覆盖了  let g:matchup_override_vimtex = 1

    if !g:vimtex_matchparen_enabled | return | endif

    call vimtex#matchparen#enable()
endf

" }}}1

fun! vimtex#matchparen#enable() abort " {{{1
    call s:matchparen.enable()
endf

" }}}1
fun! vimtex#matchparen#disable() abort " {{{1
    call s:matchparen.disable()
endf

" }}}1
fun! vimtex#matchparen#popup_check(...) abort " {{{1
    if pumvisible()
        call s:matchparen.highlight()
    en
endf

" }}}1

let s:matchparen = {}

fun! s:matchparen.enable() abort dict " {{{1
    " vint: -ProhibitAutocmdWithNoGroup

    exe  'augroup vimtex_matchparen' . bufnr('%')
        au!
        au CursorMoved  <buffer> call s:matchparen.highlight()
        au CursorMovedI <buffer> call s:matchparen.highlight()
        au BufLeave     <buffer> call s:matchparen.clear()
        au WinLeave     <buffer> call s:matchparen.clear()
        au WinEnter     <buffer> call s:matchparen.highlight()
        try
            au TextChangedP <buffer> call s:matchparen.highlight()
        catch /E216/
            silent! let self.timer =
                        \ timer_start(50, 'vimtex#matchparen#popup_check', {'repeat' : -1})
        endtry
    aug  END

    call self.highlight()

    " vint: +ProhibitAutocmdWithNoGroup
endf

" }}}1
fun! s:matchparen.disable() abort dict " {{{1
    try
        call self.clear()
    catch
    endtry

    exe  'autocmd! vimtex_matchparen' . bufnr('%')
    silent! call timer_stop(self.timer)
endf

" }}}1
fun! s:matchparen.clear() abort dict " {{{1
    try
        silent! call matchdelete(w:vimtex_match_id1)
        silent! call matchdelete(w:vimtex_match_id2)
    catch
        echom 'wf:       vimtex#matchparen#clear() failed'
    endtry

    unlet! w:vimtex_match_id1
    unlet! w:vimtex_match_id2
endf

fun! s:matchparen.highlight() abort dict " {{{1
    call self.clear()

    if vimtex#syntax#in_comment() | return | endif

    " This is a hack to ensure that $ in visual block mode adhers to the rule
    " specified in :help v_$
    if mode() ==# "\<c-v>"
        let l:pos = vimtex#pos#get_cursor()
        if len(l:pos) == 5 && l:pos[-1] == 2147483647
            call feedkeys('$', 'in')
        en
    en

    let l:current = vimtex#delim#get_current('all', 'both')
    if empty(l:current) | return | endif

    let l:corresponding = vimtex#delim#get_matching(l:current)
    if empty(l:corresponding) | return | endif
    if empty(l:corresponding.match) | return | endif

    let [l:open, l:close] = l:current.is_open
                \ ? [l:current, l:corresponding]
                \ : [l:corresponding, l:current]

    let w:vimtex_match_id1 = matchaddpos('MatchParen',
                \ [[l:open.lnum, l:open.cnum, strlen(l:open.match)]])
    let w:vimtex_match_id2 = matchaddpos('MatchParen',
                \ [[l:close.lnum, l:close.cnum, strlen(l:close.match)]])
endf

" }}}1
