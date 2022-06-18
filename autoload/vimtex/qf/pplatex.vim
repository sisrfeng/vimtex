fun! vimtex#qf#pplatex#new() abort " {{{1
    return deepcopy(s:qf)
endf

" }}}1


let s:qf = {
            \ 'name' : 'LaTeX logfile using pplatex',
            \}

fun! s:qf.init(state) abort dict "{{{1
    if !executable('pplatex')
        call vimtex#log#error('pplatex is not executable!')
        throw 'VimTeX: Requirements not met'
    en

    " Automatically remove the -file-line-error option if we use the latexmk
    " backend (for convenience)
    if a:state.compiler.name ==# 'latexmk'
        let l:index = index(a:state.compiler.options, '-file-line-error')
        if l:index >= 0
            call remove(a:state.compiler.options, l:index)
        en
    en
endf

fun! s:qf.set_errorformat() abort dict "{{{1
    " Each new item starts with two asterics followed by the file, potentially
    " a line number and sometimes even the message itself is on the same line.
    " Please note that the trailing whitspaces in the error formats are
    " intentional as pplatex produces these.

    " Start of new items with file and line number, message on next line(s).
    setl  errorformat=%E**\ Error\ \ \ in\ %f\\,\ Line\ %l:%m
    setl  errorformat+=%W**\ Warning\ in\ %f\\,\ Line\ %l:%m
    setl  errorformat+=%I**\ BadBox\ \ in\ %f\\,\ Line\ %l:%m

    " Start of items with with file, line and message on the same line. There are
    " no BadBoxes reported this way.
    setl  errorformat+=%E**\ Error\ \ \ in\ %f\\,\ Line\ %l:%m
    setl  errorformat+=%W**\ Warning\ in\ %f\\,\ Line\ %l:%m

    " Start of new items with only a file.
    setl  errorformat+=%E**\ Error\ \ \ in\ %f:%m
    setl  errorformat+=%W**\ Warning\ in\ %f:%m
    setl  errorformat+=%I**\ BadBox\ \ in\ %f:%m

    " Start of items with with file and message on the same line. There are
    " no BadBoxes reported this way.
    setl  errorformat+=%E**\ Error\ in\ %f:%m
    setl  errorformat+=%W**\ Warning\ in\ %f:%m

    " Undefined reference warnings
    setl  errorformat+=%W**\ Warning:\ %m\ on\ input\ line\ %#%l.
    setl  errorformat+=%W**\ Warning:\

    " Some errors are difficult even for pplatex
    setl  errorformat+=%E**\ Error\ \ :%m

    " Anything that starts with three spaces is part of the message from a
    " previously started multiline error item.
    setl  errorformat+=%C\ %#%m\ on\ input\ line\ %#%l.
    setl  errorformat+=%C\ %#%m

    " Items are terminated with two newlines.
    setl  errorformat+=%-Z

    " Skip statistical results at the bottom of the output.
    setl  errorformat+=%-GResult%.%#
    setl  errorformat+=%-G%.%#
endf

" }}}1
fun! s:qf.addqflist(tex, log) abort dict " {{{1
    if empty(a:log) || !filereadable(a:log)
        throw 'VimTeX: No log file found'
    en

    let l:tmp = fnamemodify(a:log, ':r') . '.pplatex'

    call vimtex#jobs#run(printf('pplatex -i "%s" >"%s"', a:log, l:tmp))
    call vimtex#paths#pushd(b:vimtex.root)
    call vimtex#qf#u#caddfile(self, l:tmp)
    call vimtex#paths#popd()
    call delete(l:tmp)
endf

" }}}1
