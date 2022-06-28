fun! vimtex#qf#init_buffer() abort
    if !g:vimtex_quickfix_enabled | return | endif

    com!     -buffer VimtexErrors  call vimtex#qf#toggle()

    nno      <buffer> <plug>(vimtex-errors)  :call vimtex#qf#toggle()<cr>
endf


fun! vimtex#qf#init_state(state) abort
    if !g:vimtex_quickfix_enabled | return | endif

    try
        let l:qf = vimtex#qf#{g:vimtex_quickfix_method}#new()
        call l:qf.init(a:state)
        unlet l:qf.init
        let a:state.qf = l:qf
    catch /VimTeX: Requirements not met/
        call vimtex#log#warning(
                    \ 'Quickfix state not initialized!',
                    \ 'Please see :help g:vimtex_quickfix_method')
    endtry
endf



fun! vimtex#qf#toggle() abort
    if vimtex#qf#is_open()
        cclose
    el
        call vimtex#qf#open(1)
    en
endf


fun! vimtex#qf#open(force) abort
    if !exists('b:vimtex.qf.addqflist') | return | endif

    try
        call vimtex#qf#setqflist()
    catch /VimTeX: No log file found/
        if a:force  | call vimtex#log#warning('No log file found')  | en

        if g:vimtex_quickfix_mode > 0  | cclose  | en

        return
    catch
        echom "v:exceptiov:exceptionn 是: "   v:exception
        call vimtex#log#error( 'parse log files 失败',  )

        if g:vimtex_quickfix_mode > 0  | cclose  | en
        return
    endtry

    if empty(getqflist())
        if a:force
            call vimtex#log#info('getqflist为空')
        en

        if g:vimtex_quickfix_mode > 0
            cclose
        en
        return
    en

    "
    " There are two options that determine when to open the quickfix window.  If
    " forced, the quickfix window is always opened when there are errors or
    " warnings (forced typically imply that the functions is called from the
    " normal mode mapping).  Else the behaviour is based on the settings.
    "
    let l:errors_or_warnings = s:qf_has_errors()
                       \ || g:vimtex_quickfix_open_on_warning

    if a:force || (g:vimtex_quickfix_mode > 0 && l:errors_or_warnings)
        let s:previous_window = win_getid()
        botright cwindow
        if g:vimtex_quickfix_mode == 2
            redraw
            call win_gotoid(s:previous_window)
        en
        if g:vimtex_quickfix_autoclose_after_keystrokes > 0
            aug  vimtex_qf_autoclose
                au!
                au CursorMoved,CursorMovedI * call s:qf_autoclose_check()
            aug  END
        en
        redraw
    en
endf


fun! vimtex#qf#setqflist(...) abort
    if !exists('b:vimtex.qf.addqflist') | return | endif

    if a:0 > 0 &&  !empty(a:1)
        let l:tex = a:1
        let l:log = fnamemodify(l:tex, ':r') . '.log'
        let l:blg = fnamemodify(l:tex, ':r') . '.blg'
        let l:jump = 0
    el
        let l:tex = b:vimtex.tex
        let l:log = b:vimtex.log()
           "\ echom "autoload/vimtex/qf.vim   log 是: "   l:log
              "\ /data2/wf2/tT/wf_tex/out_wf/PasS.log
              "\ 有时候为空, 那是因为latex没跑完? (报 "编不了"时, 不代表latex跑完了?)

        let l:blg = b:vimtex.ext('blg')
        let l:jump = g:vimtex_quickfix_autojump
    en

    try
        " Initialize the quickfix list
        "\ echo '改了qf的tittle'
        if get( getqflist( {'title': 1} ), 'title' ) =~# 'TeX的qf'
        "\ the current list is not a VimTeX qf list
            call setqflist([], 'r')  "\ clear the list
        el
            call setqflist([])
        en

        " Parse  errors
            "\ LaTeX
            call b:vimtex.qf.addqflist(l:tex,  l:log)

            " bibliography
            if has_key(b:vimtex.packages, 'biblatex')
                call vimtex#qf#biblatex#addqflist(l:blg)
            el
                call vimtex#qf#bibtex#addqflist(l:blg)
            en

        " Ignore entries if desired
        if !empty(g:vimtex_quickfix_ignore_filters)
            let l:qflist = getqflist()
                      "\ Returns a |List| with all the current quickfix errors.

            for l:re in g:vimtex_quickfix_ignore_filters
                call filter(
                    \ l:qflist,
                    \ 'v:val.text  !~#   l:re',
                   \ )
            endfor

            call setqflist(l:qflist, 'r')
                                "\ 'r' The items from the current quickfix list are replaced
                                    "\ with the items from l:qflist
        en

        " Set title if supported
        try
            call setqflist(
                    \ []                                          ,
                    \ 'r'                                         ,
                    \ {'title': 'TeX的qf : ' . b:vimtex.qf.name } ,
               \ )
                "\ If the optional {what} dictionary argument is supplied,
                "\     Only the items listed in {what} are set.
                "\     The first {list} argument is ignored.

        catch
        endtry

        " Jump to first error if wanted
        if l:jump
            try
                cfirst
            catch
                "\ echom 'aaaaaaaaaaa No errors found'
            endtry
        en
    catch /VimTeX: No log file found/
        throw 'VimTeX: No log file found'
    endtry
endf

fun! vimtex#qf#inquire(file) abort
    try
        call vimtex#qf#setqflist(a:file)
        echom "vimtex#qf#setqflist(a:file)"
        echom "a:file 是: "   a:file
        return s:qf_has_errors()
    catch
        return 0
    endtry
endf



fun! vimtex#qf#is_open() abort
    redir => l:bufstring
    silent! ls!
    redir END

    let l:buflist = filter(split(l:bufstring, '\n'), 'v:val =~# ''Quickfix''')

    for l:line in l:buflist
        let l:bufnr = str2nr(matchstr(l:line, '^\s*\zs\d\+'))
        if bufwinnr(l:bufnr) >= 0
                    \ && getbufvar(l:bufnr, '&buftype', '') ==# 'quickfix'
            return 1
        en
    endfor

    return 0
endf




fun! s:qf_has_errors() abort
    "\ echo getqflist() 空白
    return  0 <  len( filter(
                            \ getqflist(),
                           \ 'v:val.type ==# ''E''',
                          \ )
                  \ )
                           "\ 'E', 如果只有warning, 不弹窗
endf


fun! s:qf_autoclose_check() abort
    if get(s:, 'keystroke_counter') == 0
        let s:keystroke_counter = g:vimtex_quickfix_autoclose_after_keystrokes
    en

    let l:qf_winnr = map(
                \ filter(getwininfo(),
                \   {_, x -> x.tabnr == tabpagenr() && x.quickfix && !x.loclist}),
                \ {_, x -> x.winnr})

    if empty(l:qf_winnr)
        let s:keystroke_counter = 0
    elseif l:qf_winnr[0] == winnr()
        let s:keystroke_counter = g:vimtex_quickfix_autoclose_after_keystrokes + 1
    el
        let s:keystroke_counter -= 1
    en

    if s:keystroke_counter == 0
        cclose
        au! vimtex_qf_autoclose
        augroup! vimtex_qf_autoclose
    en
endf


