fun! vimtex#qf#latexlog#new() abort " {{{1
    return deepcopy(s:qf)
endf

" }}}1


let s:qf = {
            \ 'name' : 'LaTeX logfile',
            \}

fun! s:qf.init(state) abort dict "{{{1
    let self.types = map(
                \ filter(items(s:), 'v:val[0] =~# ''^type_'''),
                \ 'v:val[1]')
endf

" }}}1
fun! s:qf.set_errorformat() abort dict "{{{1
    "
    " note that The errorformat assumes we're using the -file-line-error with
"       [pdf]latex.  see |errorformat-LaTeX|.
    "

    " Push file to file stack
        setl  errorformat=%-P**%f
        setl  errorformat+=%-P**\"%f\"

    " Match errors
        setl  errorformat+=%E!\ LaTeX\ %trror:\ %m
        setl  errorformat+=%E%f:%l:\ %m
        setl  errorformat+=%+ERunaway\ argument?
        setl  errorformat+=%+C{%m
        setl  errorformat+=%C!\ %m

    " More info for undefined control sequences
        setl  errorformat+=%Z<argument>\ %m

    " More info for some errors
        setl  errorformat+=%Cl.%l\ %m

    "
    " Define general warnings
    "
        setl  errorformat+=%+WLaTeX\ Font\ Warning:\ %.%#line\ %l%.%#
        setl  errorformat+=%-CLaTeX\ Font\ Warning:\ %m
        setl  errorformat+=%-C(Font)%m

        setl  errorformat+=%+WLaTeX\ %.%#Warning:\ %.%#line\ %l%.%#
        setl  errorformat+=%+WLaTeX\ %.%#Warning:\ %m

        setl  errorformat+=%+WOverfull\ %\\%\\hbox%.%#\ at\ lines\ %l--%*\\d
        setl  errorformat+=%+WOverfull\ %\\%\\hbox%.%#\ at\ line\ %l
        setl  errorformat+=%+WOverfull\ %\\%\\vbox%.%#\ at\ line\ %l

        setl  errorformat+=%+WUnderfull\ %\\%\\hbox%.%#\ at\ lines\ %l--%*\\d
        setl  errorformat+=%+WUnderfull\ %\\%\\vbox%.%#\ at\ line\ %l

    "
    " Define package related warnings
    "
        setl  errorformat+=%+WPackage\ natbib\ Warning:\ %m\ on\ input\ line\ %l.

        setl  errorformat+=%+WPackage\ biblatex\ Warning:\ %m
        setl  errorformat+=%-C(biblatex)%.%#in\ t%.%#
        setl  errorformat+=%-C(biblatex)%.%#Please\ v%.%#
        setl  errorformat+=%-C(biblatex)%.%#LaTeX\ a%.%#
        setl  errorformat+=%-C(biblatex)%m

        setl  errorformat+=%+WPackage\ babel\ Warning:\ %m
        setl  errorformat+=%-Z(babel)%.%#input\ line\ %l.
        setl  errorformat+=%-C(babel)%m

        setl  errorformat+=%+WPackage\ hyperref\ Warning:\ %m
        setl  errorformat+=%-C(hyperref)%m\ on\ input\ line\ %l.
        setl  errorformat+=%-C(hyperref)%m

        setl  errorformat+=%+WPackage\ scrreprt\ Warning:\ %m
        setl  errorformat+=%-C(scrreprt)%m

        setl  errorformat+=%+WPackage\ fixltx2e\ Warning:\ %m
        setl  errorformat+=%-C(fixltx2e)%m

        setl  errorformat+=%+WPackage\ titlesec\ Warning:\ %m
        setl  errorformat+=%-C(titlesec)%m

        setl  errorformat+=%+WPackage\ %.%#\ Warning:\ %m\ on\ input\ line\ %l.
        setl  errorformat+=%+WPackage\ %.%#\ Warning:\ %m
        setl  errorformat+=%-Z(%.%#)\ %m\ on\ input\ line\ %l.
        setl  errorformat+=%-C(%.%#)\ %m

    " Ignore unmatched lines
    setl  errorformat+=%-G%.%#
endf

" }}}1
fun! s:qf.addqflist(tex, log) abort dict "{{{1
    if empty(a:log) || !filereadable(a:log)
        throw 'VimTeX: No log file found'
    en

    call vimtex#qf#u#caddfile(self, fnameescape(a:log))

    " Apply some post processing of the quickfix list
    let self.main = a:tex
    let self.root = b:vimtex.root
    call self.fix_paths(a:log)
endf

" }}}1
fun! s:qf.fix_paths(log) abort dict " {{{1
    let l:qflist = getqflist()
    let l:lines = readfile(a:log)

    for l:qf in l:qflist
        " Handle missing buffer/filename: Fallback to the main file (this is always
        " correct in single-file projects and is thus a good fallback).
        if l:qf.bufnr == 0
            let l:bufnr_main = bufnr(self.main)
            if bufnr(self.main) < 0
                exe  'badd' self.main
                let l:bufnr_main = bufnr(self.main)
            en
            let l:qf.bufnr = l:bufnr_main
        en

        " Try to parse the filename from logfile for certain errors
        if s:fix_paths_hbox_warning(l:qf, l:lines, self.root)
            continue
        en

        " Check and possibly fix invalid file from file:line type entries
        call s:fix_paths_invalid_bufname(l:qf, self.root)
    endfor

    call setqflist(l:qflist, 'r')
endf

" }}}1

fun! s:fix_paths_hbox_warning(qf, log, root) abort " {{{1
    if a:qf.text !~# 'Underfull\|Overfull' | return v:false | endif

    let l:index = match(a:log, '\V' . escape(a:qf.text, '\'))
    if l:index < 0 | return v:false | endif

    " Search for a line above the Overflow/Underflow message that specifies the
    " correct source filename
    let l:file = ''
    let l:level = 1
    for l:lnum in range(l:index - 1, 1, -1)
        let l:level += vimtex#util#count(a:log[l:lnum], ')')
        let l:level -= vimtex#util#count(a:log[l:lnum], '(')
        if l:lnum < l:index - 1 && l:level > 0 | continue | endif

        let l:file = matchstr(a:log[l:lnum], '\v\(\zs\f+\ze\)?\s*%(\[\d+]?)?$')
        if !empty(l:file) | break | endif
    endfor

    if empty(l:file) | return v:false | endif

    " Do some simple parsing and cleanup of the filename
    if !vimtex#paths#is_abs(l:file)
        let l:file = simplify(a:root . '/' . l:file)
    en

    if !filereadable(l:file) | return v:false | endif

    let l:bufnr = bufnr(l:file)
    if l:bufnr > 0
        let a:qf.bufnr = bufnr(l:file)
    el
        let a:qf.bufnr = 0
        let a:qf.filename = fnamemodify(l:file, ':.')
    en

    return v:true
endf

" }}}1
fun! s:fix_paths_invalid_bufname(qf, root) abort " {{{1
    " First check if the entry bufnr is already valid
    let l:file = getbufinfo(a:qf.bufnr)[0].name
    if filereadable(l:file) | return | endif

    " The file names of all file:line type entries in the log output are listed
    " relative to the root of the main LaTeX file. The quickfix mechanism adds
    " the buffer with the file string. Thus, if the current buffer is not
    " correct, we can fix by prepending the root to the filename.
    let l:file = fnamemodify(
                \ simplify(a:root . '/' . bufname(a:qf.bufnr)), ':.')
    if !filereadable(l:file) | return | endif

    let l:bufnr = bufnr(l:file)
    if l:bufnr > 0
        let a:qf.bufnr = bufnr(l:file)
    el
        let a:qf.bufnr = 0
        let a:qf.filename = l:file
    en
endf

" }}}1
