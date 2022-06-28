fun! vimtex#jobs#neovim#new(cmd) abort
    let l:job = deepcopy(s:job)
    let l:job.cmd = has('win32')
                \ ? 'cmd /s /c "' . a:cmd . '"'
                \ : ['sh', '-c', a:cmd]
    return l:job
endf


fun! vimtex#jobs#neovim#run(cmd) abort
    call s:neovim_{s:os}_run(a:cmd)
endf


fun! vimtex#jobs#neovim#capture(cmd) abort
    return s:neovim_{s:os}_capture(a:cmd)
endf



let s:os = has('win32') ? 'win' : 'unix'


let s:job = {}

fun! s:job.start() abort dict
    let l:options = {}

    if self.capture_output
        let self._output = []
        let l:options.on_stdout = function('s:__callback')
        let l:options.on_stderr = function('s:__callback')
        let l:options.stdout_buffered = v:true
        let l:options.stderr_buffered = v:true
        let l:options.output = self._output
    en
    if !empty(self.cwd)
        let l:options.cwd = self.cwd
    en

    let self.job = jobstart(self.cmd, l:options)

    return self
endf

fun! s:__callback(id, data, event) abort dict
    call extend(self.output, a:data)
endf


fun! s:job.stop() abort dict
    call jobstop(self.job)
endf


fun! s:job.wait() abort dict
    let l:retvals = jobwait([self.job], self.wait_timeout)
    if empty(l:retvals) | return | endif
    let l:status = l:retvals[0]
    if l:status >= 0 | return | endif

    if l:status == -1
        call vimtex#log#warning('Job timed out while waiting!', join(self.cmd))
        call self.stop()
    elseif l:status == -2
        call vimtex#log#warning('Job interrupted!', self.cmd)
    en
endf


fun! s:job.is_running() abort dict
    try
        let l:pid = jobpid(self.job)
        return l:pid > 0
    catch
        return v:false
    endtry
endf


fun! s:job.get_pid() abort dict
    if !has_key(self, 'pid')
        try
            let self.pid = jobpid(self.job)
        catch
            let self.pid = 0
        endtry
    en

    return self.pid
endf


fun! s:job.output() abort dict
    call self.wait()

    if !self.capture_output | return [] | endif

    " Trim output
    while len(self._output) > 0
        if !empty(self._output[0]) | break | endif
        call remove(self._output, 0)
    endwhile
    while len(self._output) > 0
        if !empty(self._output[-1]) | break | endif
        call remove(self._output, -1)
    endwhile

    return self._output
endf



fun! s:job.__pprint() abort dict
    let l:pid = self.get_pid()

    return [
                \ ['pid', l:pid ? l:pid : '-'],
                \ ['cmd', self.cmd_raw],
                \]
endf




fun! s:neovim_unix_run(cmd) abort
    call system(['sh', '-c', a:cmd])
endf


fun! s:neovim_unix_capture(cmd) abort
    return systemlist(['sh', '-c', a:cmd])
endf



fun! s:neovim_win_run(cmd) abort
    let s:saveshell = [&shell, &shellcmdflag, &shellslash]
    set shell& shellcmdflag& shellslash&

    call system('cmd /s /c "' . a:cmd . '"')

    let [&shell, &shellcmdflag, &shellslash] = s:saveshell
endf


fun! s:neovim_win_capture(cmd) abort
    let s:saveshell = [&shell, &shellcmdflag, &shellslash]
    set shell& shellcmdflag& shellslash&

    let l:output = systemlist('cmd /s /c "' . a:cmd . '"')

    let [&shell, &shellcmdflag, &shellslash] = s:saveshell

    return l:output
endf


