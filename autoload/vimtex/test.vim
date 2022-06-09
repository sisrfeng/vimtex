" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

fun! vimtex#test#finished() abort " {{{1
    for l:error in v:errors
        let l:match = matchlist(l:error, '\(.*\) line \(\d\+\): \(.*\)')
        let l:file = fnamemodify(l:match[1], ':.')
        let l:lnum = l:match[2]
        let l:msg = l:match[3]

        if l:msg =~# 'Expected .*but got'
            echo printf("%s:%d\n", l:file, l:lnum)

            let l:intro = matchstr(l:msg, '.\{-}\ze\s*\(: \)\?Expected ')
            if !empty(l:intro)
                echo printf("  %s\n", l:intro)
            en

            let l:expect = matchstr(l:msg, 'Expected \zs.*\zebut got')
            let l:observe = matchstr(l:msg, 'Expected .*but got \zs.*')
            echo printf("  Expected: %s\n", l:expect)
            echo printf("  Observed: %s\n\n", l:observe)
        elseif l:msg =~# 'Pattern.*does\( not\)\? match'
            echo printf("%s:%d\n", l:file, l:lnum)

            let l:intro = matchstr(l:msg, '.\{-}\ze\s*\(: \)\?Pattern ')
            if !empty(l:intro)
                echo printf("  %s\n", l:intro)
            en

            let l:expect = matchstr(l:msg, 'Pattern.*does\( not\)\? match.*')
            echo printf("  %s\n", l:expect)
        el
            echo printf("%s:%d: %s\n", l:file, l:lnum, l:msg)
        en
    endfor

    if len(v:errors) > 0
        cquit
    el
        quitall!
    en
endf

" }}}1

fun! vimtex#test#completion(context, ...) abort " {{{1
    let l:base = a:0 > 0 ? a:1 : ''

    try
        silent execute 'normal GO' . a:context . "\<c-x>\<c-o>"
        silent normal! u
        return vimtex#complete#omnifunc(0, l:base)
    catch
        call assert_report(
                    \ printf("\n  Context: %s\n  Base: %s\n%s",
                    \        a:context, l:base, v:exception))
    endtry
endf

" }}}1
fun! vimtex#test#keys(keys, context, expect) abort " {{{1
    if type(a:context) == v:t_string
        let l:ctx = [a:context]
        let l:msg_context = printf("Context: %s", a:context)
    el
        let l:ctx = a:context
        let l:msg_context = printf("Context:\n%s", join(a:context, "\n"))
    en

    try
        norm! gg0dG
        call append(1, l:ctx)
        norm! ggdd
        silent execute 'normal' a:keys
    catch
        call assert_report(
                    \ printf("\n  Keys: %s\n  %s\n%s",
                    \        a:keys, l:msg_context, v:exception))
    endtry

    let l:observe = getline(1, line('$'))
    let l:observe = type(a:expect) == v:t_string
                \ ? join(l:observe)
                \ : l:observe

    call assert_equal(a:expect, l:observe,
                \ printf("Keys: %s\n  %s", a:keys, l:msg_context))
endf

" }}}1
fun! vimtex#test#main(file, expected, ...) abort " {{{1
    exe     'silent edit' fnameescape(a:file)

    " ToggleMain if extra arg supplied
    if a:0 > 0
        VimtexToggleMain
    en

    let l:expected = empty(a:expected) ? '' : fnamemodify(a:expected, ':p')
    call assert_true(exists('b:vimtex'))
    call assert_equal(fnamemodify(l:expected, ':.'), fnamemodify(b:vimtex.tex, ':.'))

    bwipeout!
endf

" }}}1
