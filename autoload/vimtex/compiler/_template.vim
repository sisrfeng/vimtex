fun! vimtex#compiler#_template#new(opts) abort
    return extend(deepcopy(s:compiler),  a:opts)
endf

"\ s:compiler类似于python的base class
    "\ autoload/vimtex/compiler/latexmk.vim里的同名 东西 可以用这里的func
let s:compiler = {
            \ 'name'                   :  '__template__' ,
            \ 'build_dir'              :  ''             ,
            \ 'continuous'             :  0              ,
            \ 'hooks'                  :  []             ,
            \ 'output'                 :  tempname()     ,
            \ 'state'                  :  {}             ,
            \ 'status'                 :  -1             ,
            \ 'silence_next_callback'  :  0              ,
            \ }

fun! s:compiler.new(options) abort dict
    let l:compiler = extend(deepcopy(self), a:options)

    let l:backend  = has('nvim')
                \ ? 'nvim'
                \ : 'jobs'
    call extend(
        \ l:compiler,
        \ deepcopy(s:compiler_{l:backend}),
       \ )

    call l:compiler.__check_requirements()

    call s:build_dir_materialize(l:compiler)
    call l:compiler.__init()
    call s:build_dir_respect_envvar(l:compiler)

    " Remove init methods
        unlet l:compiler.new
        unlet l:compiler.__check_requirements
        unlet l:compiler.__init

    return l:compiler
endf



fun! s:compiler.__check_requirements() abort dict
endf


fun! s:compiler.__init() abort dict
endf


fun! s:compiler.__build_cmd() abort dict
    throw 'VimTeX: __build_cmd method must be defined!'
endf


fun! s:compiler.__pprint() abort dict
    let l:list = []

    if self.state.tex !=# b:vimtex.tex
        call add(l:list, ['root', self.state.root])
        call add(l:list, ['target', self.state.tex])
    en

    if has_key(self, 'get_engine')
        call add(l:list, ['engine', self.get_engine()])
    en

    if has_key(self, 'options')
        call add(l:list, ['options', self.options])
    en

    if !empty(self.build_dir)
        call add(l:list, ['build_dir', self.build_dir])
    en

    if has_key(self, '__pprint_append')
        call extend(l:list, self.__pprint_append())
    en

    if has_key(self, 'job')
        let l:job = []
        call add(l:job, ['jobid', self.job])
        call add(l:job, ['output', self.output])
        call add(l:job, ['cmd', self.cmd])
        if self.continuous
            call add(l:job, ['pid', self.get_pid()])
            echom "self.get_pid() 是: "   self.get_pid()
        en
        call add(l:list, ['job', l:job])
    en

    return l:list
endf



fun! s:compiler.clean(full) abort dict
    let l:files = ['synctex.gz', 'toc', 'out', 'aux', 'log']
    if a:full
        call extend(l:files, ['pdf'])
    en

    call map(l:files, {_, x -> printf('%s/%s.%s',
                \ self.build_dir, fnamemodify(self.state.tex, ':t:r:S'), x)})

    call vimtex#jobs#run('rm -f ' . join(l:files), {'cwd': self.state.root})
endf


fun! s:compiler.start(...) abort dict
    if self.is_running() | return | endif

    call self.create_build_dir()

    " Initialize output file
    call writefile([], self.output, 'a')

    " Prepare compile command
        let self.cmd = self.__build_cmd()
        let l:cmd = has('win32')
                    \ ? 'cmd /s /c "' . self.cmd . '"'
                    \ : ['sh', '-c', self.cmd]

                    "\ \ : ['zsh', '-c', self.cmd]
                        "\ echom 'sh被我改成zsh了'

    " Execute command and toggle status
        call self.exec(l:cmd)
        let self.status = 1

    " Use timer to check that compiler started properly
    if self.continuous
        let self.check_timer
            \ = timer_start(
                           \ 50,
                           \ function('s:check_if_running'),
                           \ {'repeat': 20},
                         \ )
        let self.vimtex_id = b:vimtex_id
        let s:check_timers[self.check_timer] = self
    en

    if exists('#User#VimtexEventCompileStarted')
        doautocmd <nomodeline> User VimtexEventCompileStarted
    en
endf


let s:check_timers = {}
fun! s:check_if_running(timer) abort
    if s:check_timers[a:timer].is_running() | return | endif

    call timer_stop(a:timer)
    let l:compiler = remove(s:check_timers, a:timer)
    unlet l:compiler.check_timer

    if l:compiler.vimtex_id == get(b:, 'vimtex_id', -1)
        call vimtex#compiler#output()
    en
    call vimtex#log#error('Compiler did not start successfully!')
endf




fun! s:compiler.start_single() abort dict
    let l:continuous = self.continuous
        let self.continuous = 0
        call self.start()
    let self.continuous = l:continuous
endf


fun! s:compiler.stop() abort dict
    if !self.is_running() | return | endif

    silent! call timer_stop(self.check_timer)
    let self.status = 0
    call self.kill()

    if exists('#User#VimtexEventCompileStopped')
        doautocmd <nomodeline> User VimtexEventCompileStopped
    en
endf



fun! s:compiler.create_build_dir() abort dict
    " Create build dir if it does not exist
    " Note: This may need to create a hierarchical structure!
    if empty(self.build_dir) | return | endif

    if has_key(self.state, 'sources')
        let l:dirs = copy(self.state.sources)
        call filter(map(
                    \ l:dirs, "fnamemodify(v:val, ':h')"),
                    \ {_, x -> x !=# '.'})
        call filter(l:dirs, {_, x -> stridx(x, '../') != 0})
    el
        let l:dirs = glob(self.state.root . '/**/*.tex', v:false, v:true)
        call map(l:dirs, "fnamemodify(v:val, ':h')")
        call map(l:dirs, 'strpart(v:val, strlen(self.state.root) + 1)')
    en
    call uniq(sort(filter(l:dirs, '!empty(v:val)')))

    call map(l:dirs, {_, x ->
                \ (vimtex#paths#is_abs(self.build_dir) ? '' : self.state.root . '/')
                \ . self.build_dir . '/' . x})
    call filter(l:dirs, '!isdirectory(v:val)')
    if empty(l:dirs) | return | endif

    " Create the non-existing directories
    call vimtex#log#warning(["Creating build_dir directorie(s):"]
                \ + map(copy(l:dirs), {_, x -> '* ' . x}))

    for l:dir in l:dirs
        call mkdir(l:dir, 'p')
    endfor
endf


fun! s:compiler.remove_build_dir() abort dict
    " Remove auxilliary output directories (only if they are empty)
    if empty(self.build_dir) | return | endif

    if vimtex#paths#is_abs(self.build_dir)
        let l:build_dir = self.build_dir
    el
        let l:build_dir = self.state.root . '/' . self.build_dir
    en

    let l:tree = glob(l:build_dir . '/**/*', 0, 1)
    let l:files = filter(copy(l:tree), 'filereadable(v:val)')

    if empty(l:files)
        for l:dir in sort(l:tree) + [l:build_dir]
            call delete(l:dir, 'd')
        endfor
    en
endf


fun! s:callback(ch, msg) abort
    if !exists('b:vimtex.compiler')  | return | endif
    if b:vimtex.compiler.status == 0 | return | endif
                                 "\ status只有1 2 3

    try
        call vimtex#compiler#callback(2 + vimtex#qf#inquire(s:cb_target))
            "\                           没有errors时, 它是0, 否则是1
    catch /E565:/
        " In some edge cases,
        " the callback seems to be issued while executing code
        " in a protected context where "cclose"
        " is not allowed with the resulting  error code
        " from compiler#callback->qf#open.
        " The reported error message  is:
        "
        "   E565: Not allowed to change text or change window:       cclose
        "
        " See https://github.com/lervag/vimtex/issues/2225
    endtry
endf


fun! s:callback_continuous_output(channel, msg) abort
    if exists('b:vimtex.compiler.output')
  \ && filewritable(b:vimtex.compiler.output)

        call writefile(
            \ [a:msg],
            \ b:vimtex.compiler.output,
            \ 'aS',
           \ )
    en

    call s:check_callback(a:msg)

    if !exists('b:vimtex.compiler.hooks') | return | endif

    try
        for l:Hook in b:vimtex.compiler.hooks
            call l:Hook(a:msg)
            echom "l:Hook 是: "   l:Hook
        endfor
    catch /E716/
    endtry
endf


let s:compiler_nvim = {}
fun! s:compiler_nvim.exec(cmd) abort dict
    let l:job_opts = {
                \ 'stdin'      :  'null'                             ,
                \ 'on_stdout'  :  function('s:callback_nvim_stdout') ,
                "\ \ 'on_stderr'  :  function('s:callback_nvim_stdout') ,
                \ 'on_stderr'  :  function('s:callback_nvim_err') ,
                \ 'cwd'        :  self.state.root                ,
                \ 'tex'        :  self.state.tex                 ,
                \ 'output'     :  self.output                    ,
                \}

    "\ "\ {
        "\ \ 'output': '/tmp/nvimyQik0w/2',
        "\ \ 'cwd': '/home/wf/d/tT/wf_tex',
        "\ \ 'tex': '/home/wf/d/tT/wf_tex/PasS.tex',
        "\ \ 'stdin': 'null',
        "\ \ 'on_stdout': function('<SNR>224_callback_nvim_output'),
        "\ \ 'on_stderr': function('<SNR>224_callback_nvim_output'),
        "\ \ }

    if !self.continuous
        let l:job_opts.on_exit = function('s:callback_nvim_exit')
    en

    let s:saveshell = [&shell, &shellcmdflag]
        set   shell&   shellcmdflag&
        let self.job = jobstart(a:cmd, l:job_opts)
        "\ echom "self.job 是: "   self.job
                                "\ 一个id, 逐步加1
    let [&shell, &shellcmdflag] = s:saveshell
endf


fun! s:compiler_nvim.kill() abort dict
    call jobstop(self.job)
endf


fun! s:compiler_nvim.wait() abort dict
    let l:retvals = jobwait([self.job], 5000)
    if empty(l:retvals) | return | endif
    let l:status = l:retvals[0]
    if l:status >= 0 | return | endif

    if l:status == -1 | call self.stop() | endif
endf


fun! s:compiler_nvim.is_running() abort dict
    try
        let pid = jobpid(self.job)
        return l:pid > 0
    catch
        return v:false
    endtry
endf


fun! s:compiler_nvim.get_pid() abort dict
    try
        return jobpid(self.job)
    catch
        return 0
    endtry
endf


fun! s:callback_nvim_stdout(id, data, event) abort dict
    " Filter out unwanted newlines
    let l:data = split(substitute(
                           \ join(a:data, 'QQ'),
                           \ '^QQ\|QQ$',
                           \ '',
                           \ '',
                         \ ), '
              \ QQ'
              \ )

    if !empty(l:data) && filewritable(self.output)
        call writefile(l:data, self.output, 'a')
    en

    call s:check_callback(
                \ get(
                    \ filter(
                           \ copy(a:data),
                           \ { _, x -> x =~# '^vimtex_compiler_callback'},
                          \ ),
                    \ -1,
                    \ '',
                   \ )
               \ )

    if !exists('b:vimtex.compiler.hooks') | return | endif

    try
        for l:Hook in b:vimtex.compiler.hooks
            call l:Hook(join(a:data, "\n"))
        endfor
    catch /E716/
    endtry
endf


"\ 改编自 楼上
fun! s:callback_nvim_err(id, data, event) abort dict

    "\ echo 'lucy saids:  在调用callback_nvim_err_______'
                         "\ a:data是个list
    " Filter out unwanted newlines
    let l:data = split(substitute(
                           \ join(a:data, 'QQ'),
                           \ '^QQ\|QQ$',
                           \ '',
                           \ '',
                         \ ), '
              \ QQ'
              \ )

    if !empty(l:data) && filewritable(self.output)
        call writefile(l:data, self.output, 'a')
    en

    call s:check_callback(
                \ get(
                    \ filter(
                           \ copy(a:data),
                           \ { _, x -> x =~# '^vimtex_compiler_callback'},
                          \ ),
                    \ -1,
                    \ '',
                   \ )
               \ )

    if !exists('b:vimtex.compiler.hooks') | return | endif

    try
        for l:Hook in b:vimtex.compiler.hooks
            call l:Hook(join(a:data, "\n"))
        endfor
    catch /E716/
    endtry
endf


fun! s:callback_nvim_exit(id, data, event) abort dict
    "\ echom "event是: "   a:event
                        "\ exit

    if !exists('b:vimtex.compiler')  | return | endif
    if b:vimtex.compiler.status == 0 | return | endif

    let l:target = self.tex !=# b:vimtex.tex ? self.tex : ''
        "\ echom "l:target 是: "   l:target
        "\ 空白
    call vimtex#compiler#callback(2 + vimtex#qf#inquire(l:target))
                                 "\ 没有error时 就是0, 否则是1
endf




fun! s:build_dir_materialize(compiler) abort
    if type(a:compiler.build_dir) != v:t_func | return | endif

    try
        let a:compiler.build_dir = a:compiler.build_dir()
    catch
        call vimtex#log#error(
                    \ 'Could not expand build_dir function!',
                    \ v:exception)
        let a:compiler.build_dir = ''
    endtry
endf


fun! s:build_dir_respect_envvar(compiler) abort
    " Specifying the build_dir by environment variable should override the
    " current value.
    if empty($VIMTEX_OUTPUT_DIRECTORY) | return | endif

    if !empty(a:compiler.build_dir)
                \ && (a:compiler.build_dir !=# $VIMTEX_OUTPUT_DIRECTORY)
        call vimtex#log#warning(
                    \ 'Setting VIMTEX_OUTPUT_DIRECTORY overrides build_dir!',
                    \ 'Changed build_dir from: ' . a:compiler.build_dir,
                    \ 'Changed build_dir to: ' . $VIMTEX_OUTPUT_DIRECTORY)
    en

    let a:compiler.build_dir = $VIMTEX_OUTPUT_DIRECTORY
endf



fun! s:check_callback(line) abort
    if a:line ==# 'vimtex_compiler_callback_compiling'
        call vimtex#compiler#callback(1)

    elseif a:line ==# 'vimtex_compiler_callback_success'
        call vimtex#compiler#callback(2)

    elseif a:line ==# 'vimtex_compiler_callback_failure'
        call vimtex#compiler#callback(3)
    en
endf


