fun! vimtex#jobs#vim#new(cmd) abort " {{{1
    let l:job = deepcopy(s:job)
    let l:job.cmd = has('win32')
                \ ? 'cmd /s /c "' . a:cmd . '"'
                \ : ['sh', '-c', a:cmd]
    return l:job
endf

" }}}1
fun! vimtex#jobs#vim#run(cmd) abort " {{{1
    call s:vim_{s:os}_run(a:cmd)
endf

" }}}1
fun! vimtex#jobs#vim#capture(cmd) abort " {{{1
    return s:vim_{s:os}_capture(a:cmd)
endf

" }}}1

let s:os = has('win32') ? 'win' : 'unix'


let s:job = {}

fun! s:job.start() abort dict " {{{1
    let l:options = {}

    if self.capture_output
        let self._output = tempname()
        let l:options.out_io = 'file'
        let l:options.err_io = 'file'
        let l:options.out_name = self._output
        let l:options.err_name = self._output
    el
        let l:options.in_io = 'null'
        let l:options.out_io = 'null'
        let l:options.err_io = 'null'
    en
    if !empty(self.cwd)
        let l:options.cwd = self.cwd
    en

    let self.job = job_start(self.cmd, l:options)

    return self
endf

" }}}1
fun! s:job.stop() abort dict " {{{1
    call job_stop(self.job)
    for l:dummy in range(25)
        sleep 1m
        if !self.is_running() | return | endif
    endfor
endf

" }}}1
fun! s:job.wait() abort dict " {{{1
    for l:dummy in range(self.wait_timeout/10)
        sleep 10m
        if !self.is_running() | return | endif
    endfor

    call vimtex#log#warning('Job timed out while waiting!', join(self.cmd))
    call self.stop()
endf

" }}}1
fun! s:job.is_running() abort dict " {{{1
    return job_status(self.job) ==# 'run'
endf

" }}}1
fun! s:job.get_pid() abort dict " {{{1
    if !has_key(self, 'pid')
        try
            return get(job_info(self.job), 'process')
        catch
            return 0
        endtry
    en

    return self.pid
endf

" }}}1
fun! s:job.output() abort dict " {{{1
    call self.wait()
    return self.capture_output ? readfile(self._output) : []
endf

" }}}1

fun! s:job.__pprint() abort dict " {{{1
    let l:pid = self.get_pid()

    return [
                \ ['pid', l:pid ? l:pid : '-'],
                \ ['cmd', self.cmd_raw],
                \]
endf

" }}}1


fun! s:vim_unix_run(cmd) abort " {{{1
    let s:saveshell = [
                \ &shell,
                \ &shellcmdflag,
                \ &shellquote,
                \ &shellredir,
                \]
    let &shell = s:shell
    set shellcmdflag& shellquote& shellredir&

    silent! call system(a:cmd)

    let [   &shell,
                \ &shellcmdflag,
                \ &shellquote,
                \ &shellredir] = s:saveshell
endf

" }}}1
fun! s:vim_unix_capture(cmd) abort " {{{1
    let s:saveshell = [
                \ &shell,
                \ &shellcmdflag,
                \ &shellquote,
                \ &shellredir,
                \]
    let &shell = s:shell
    set shellcmdflag& shellquote& shellredir&

    silent! let l:output = systemlist(a:cmd)

    let [   &shell,
                \ &shellcmdflag,
                \ &shellquote,
                \ &shellredir] = s:saveshell

    return v:shell_error == 127 ? ['command not found'] : l:output
endf

let s:shell = executable('sh')
            \ ? 'sh'
            \ : (executable('/usr/bin/sh')
            \    ? '/usr/bin/sh' : '/bin/sh')

" }}}1

fun! s:vim_win_run(cmd) abort " {{{1
    let s:saveshell = [
                \ &shell,
                \ &shellcmdflag,
                \ &shellquote,
                \ &shellxquote,
                \ &shellredir,
                \ &shellslash
                \]
    set shell& shellcmdflag& shellquote& shellxquote& shellredir& shellslash&

    silent! call system('cmd /s /c "' . a:cmd . '"')

    let [   &shell,
                \ &shellcmdflag,
                \ &shellquote,
                \ &shellxquote,
                \ &shellredir,
                \ &shellslash] = s:saveshell
endf

" }}}1
fun! s:vim_win_capture(cmd) abort " {{{1
    let s:saveshell = [
                \ &shell,
                \ &shellcmdflag,
                \ &shellquote,
                \ &shellxquote,
                \ &shellredir,
                \ &shellslash
                \]
    set shell& shellcmdflag& shellquote& shellxquote& shellredir& shellslash&

    silent! let l:output = systemlist('cmd /s /c "' . a:cmd . '"')

    let [   &shell,
                \ &shellcmdflag,
                \ &shellquote,
                \ &shellxquote,
                \ &shellredir,
                \ &shellslash] = s:saveshell

    return l:output
endf

" }}}1
