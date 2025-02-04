fun! vimtex#compiler#init_buffer() abort
    if !g:vimtex_compiler_enabled | return | endif

    " Define commands
        com!     -buffer        VimtexCompile                          call vimtex#compiler#compile()
        com!     -buffer        VimtexCompileSS                        call vimtex#compiler#compile_ss()
        "\ com!     -buffer -bang  VimtexCompileSS                        call vimtex#compiler#compile_ss()
        com!     -buffer -range VimtexCompileSelected   <line1>,<line2>call vimtex#compiler#compile_selected('command')
        com!     -buffer        VimtexCompileOutput        call vimtex#compiler#output()
        com!     -buffer        VimtexStop                 call vimtex#compiler#stop()
        com!     -buffer        VimtexStopAll              call vimtex#compiler#stop_all()
        com!     -buffer -bang  VimtexClean                call vimtex#compiler#clean(<q-bang> == "!")
        com!     -buffer -bang  VimtexStatus               call vimtex#compiler#status(<q-bang> == "!")

    " Define mappings
      nno  <buffer> <plug>(vimtex-compile)              :call vimtex#compiler#compile()<cr>
      nno  <buffer> <plug>(vimtex-compile-ss)           :call vimtex#compiler#compile_ss()<cr>

      nno  <buffer> <plug>(vimtex-compile-selected)    :set opfunc=vimtex#compiler#compile_selected<cr>g@
      xn   <buffer> <plug>(vimtex-compile-selected)    :<c-u>call vimtex#compiler#compile_selected('visual')<cr>

      nno  <buffer> <plug>(vimtex-compile-output)       :call vimtex#compiler#output()<cr>
      nno  <buffer> <plug>(vimtex-stop)                 :call vimtex#compiler#stop()<cr>
      nno  <buffer> <plug>(vimtex-stop-all)             :call vimtex#compiler#stop_all()<cr>
      nno  <buffer> <plug>(vimtex-clean)                :call vimtex#compiler#clean(0)<cr>
      nno  <buffer> <plug>(vimtex-clean-full)           :call vimtex#compiler#clean(1)<cr>
      nno  <buffer> <plug>(vimtex-status)               :call vimtex#compiler#status(0)<cr>
      nno  <buffer> <plug>(vimtex-status-all)           :call vimtex#compiler#status(1)<cr>
endf


fun! vimtex#compiler#init_state(state) abort
    if !g:vimtex_compiler_enabled | return | endif

    let a:state.compiler = s:init_compiler({'state': a:state})
endf



"\ 给 `latexmk` 调用
fun! vimtex#compiler#callback(status) abort
    " Status:
        " 1: Compilation cycle has started
        " 2: Compilation complete - Success
        " 3: Compilation complete - Failed

    "\ 被这堆东西相关的家伙调用
                "\ \ 'on_stdout'  :  function('s:callback_nvim_stdout') ,
                "\ \ 'on_stderr'  :  function('s:callback_nvim_err') ,

                "\ callback_nvim_err里有:
                "\ call vimtex#compiler#callback(2 + vimtex#qf#inquire(l:target))


    if !exists('b:vimtex.compiler') | return | endif
    silent! call s:output.pause()

    if b:vimtex.compiler.silence_next_callback
        if g:vimtex_compiler_silent
            let b:vimtex.compiler.silence_next_callback = 0
        el
            call vimtex#log#set_silent()
        en
    en

    let b:vimtex.compiler.status = a:status

    if a:status == 1
        if exists('#User#VimtexEventCompiling')  | doautocmd <nomodeline> User VimtexEventCompiling  | en
        silent! call s:output.resume()
        return
    en

    if a:status == 2
        if !g:vimtex_compiler_silent |  call vimtex#log#info('在compile') | endif

        "\ echo "b:vimtex 是: "   b:vimtex
        "\ echom "b:vimtex 是: "   b:vimtex
            "\ echom b:一般会报错, 因为buffer变了?
        if exists('b:vimtex')
            call b:vimtex.update_packages()
            call vimtex#syntax#packages#init()
        en

        if exists('#User#VimtexEventCompileSuccess')  | doautocmd <nomodeline> User VimtexEventCompileSuccess  | en

    elseif a:status == 3
        if !g:vimtex_compiler_silent                 | call vimtex#log#warning('编不了')  | en
        if exists('#User#VimtexEventCompileFailed')  | doautocmd <nomodeline> User VimtexEventCompileFailed  | en
    en

    if b:vimtex.compiler.silence_next_callback
        call vimtex#log#set_silent_restore()
        let b:vimtex.compiler.silence_next_callback = 0
    en

    call vimtex#qf#open(0)
    silent! call s:output.resume()
endf



fun! vimtex#compiler#compile() abort
    if b:vimtex.compiler.is_running()
        call vimtex#compiler#stop()
    el
        call vimtex#compiler#start()
    en
endf


fun! vimtex#compiler#compile_ss() abort
    if b:vimtex.compiler.is_running()
        call vimtex#log#info(
                    \ '想Stop?')
        return
    en

    call b:vimtex.compiler.start_single()

    if g:vimtex_compiler_silent
        return
    el
        "\ call vimtex#log#info('单次compile')
    endif

endf


fun! vimtex#compiler#compile_selected(type) abort range
    " Values of a:firstline  and a:lastline are not available in ¿nested¿ function  calls,
        " so we must handle them here.
    let l:opts = a:type ==# 'command'
                    \ ? {
                        \ 'type': 'range',
                        \ 'range': [a:firstline, a:lastline],
                      \ }
                    \ : {'type':  a:type =~# '\vline|char|block'
                                    \? 'operator'
                                    \: a:type
                       \}

    let l:files = vimtex#parser#selection_to_texfile(l:opts)

    if empty(l:files) | return | endif

    let l:tex_program = b:vimtex.get_tex_program()
    let l:files.get_tex_program = {-> l:tex_program}

    " Create and initialize temporary compiler
    let l:compiler = s:init_compiler({
                            \ 'state'       :  l:files ,
                            \ 'continuous'  :  0      ,
                            \ 'callback'    :  0      ,
                            \})

    if empty(l:compiler) | return | endif

    call vimtex#log#info('Compiling selected lines ...')
    call vimtex#log#set_silent()
    call l:compiler.start()
    call l:compiler.wait()

    " Check if successful
    if vimtex#qf#inquire(l:files.base)
        call vimtex#log#set_silent_restore()
        call vimtex#log#warning('Compiling selected lines ... failed!')
        botright cwindow
        "\ 有错误时,弹出quickfix
        return
    el
        call l:compiler.clean(0)
        call b:vimtex.viewer.view(l:files.pdf)
        call vimtex#log#set_silent_restore()
        call vimtex#log#info('Compiling selected lines ... done')
    en
endf


fun! vimtex#compiler#output() abort
    if !exists('b:vimtex.compiler.output')
 \ || !filereadable(b:vimtex.compiler.output)

        echom "b:vimtex.compiler.output 是: "   b:vimtex.compiler.output
        call vimtex#log#warning('No output exists!')
        return
    en

    " If relevant output is open,
    " then reuse it
    if exists('s:output')
        if s:output.name ==# b:vimtex.compiler.output
        echom "s:output.name 是: "   s:output.name
            if bufwinnr(b:vimtex.compiler.output) == s:output.winnr
                exe     s:output.winnr . 'wincmd w'
            en
            return
        el
            call s:output.destroy()
        en
    en

    call s:output_factory.create(b:vimtex.compiler.output)
endf


fun! vimtex#compiler#start() abort
    if b:vimtex.compiler.is_running()
        call vimtex#log#warning(
                    \ 'Compiler is already running for `' . b:vimtex.base . "'")
        return
    en

    call b:vimtex.compiler.start()

    if g:vimtex_compiler_silent | return | endif

    redraw
        " We add a redraw here to clear messages (e.g. file written).
        " This is useful  to avoid the "Press ENTER" prompt in some cases, see e.g.
            " https://github.com/lervag/vimtex/issues/2149

    if b:vimtex.compiler.continuous
        call vimtex#log#info('开启连续编译')
    el
        call vimtex#log#info('后台已开始编译')
    en
endf


fun! vimtex#compiler#stop() abort

    if !b:vimtex.compiler.is_running()
        call vimtex#log#warning( 'There is no process to stop (' . b:vimtex.base . ')')
        return
    en

    call b:vimtex.compiler.stop()

    if g:vimtex_compiler_silent | return | endif
    call vimtex#log#info('编译停止' )
    "\ call vimtex#log#info('不编了 b:vimtex.base是: ' . b:vimtex.base )
                                                      "\ tex主文件名
endf


fun! vimtex#compiler#stop_all() abort
    for l:state in vimtex#state#list_all()
        if exists('l:state.compiler.is_running')
      \ && l:state.compiler.is_running()
            call l:state.compiler.stop()
            call vimtex#log#info('Compiler stopped (' . l:state.compiler.state.base . ')')
        en
    endfor
endf


fun! vimtex#compiler#clean(full) abort
    let l:restart = b:vimtex.compiler.is_running()
    if l:restart  | call b:vimtex.compiler.stop()  | en


    call b:vimtex.compiler.clean(a:full)
    "\ 100m 需要调大?
    sleep 100m
    call b:vimtex.compiler.remove_build_dir()

    call vimtex#log#info('Compiler clean finished'
                        \ . (a:full ?
                            \ ' (full)' :
                            \ ''
                          \ )
                  \ )


    if l:restart
        let b:vimtex.compiler.silence_next_callback = 1
        silent call b:vimtex.compiler.start()
    en
endf


fun! vimtex#compiler#status(detailed) abort
    if a:detailed
        let l:running = []
        for l:data in vimtex#state#list_all()
            if l:data.compiler.is_running()
                let l:name = l:data.tex
                if len(l:name) >= winwidth('.') - 20
                    let l:name = '...' . l:name[-winwidth('.')+23:]
                en
                call add(l:running, printf('%-6s %s',
                            \ string(l:data.compiler.get_pid()) . ':', l:name))
            en
        endfor

        if empty(l:running)
            call vimtex#log#info('Compiler is not running!')
        el
            call vimtex#log#info('Compiler is running', l:running)
        en
    el
        if exists('b:vimtex.compiler')
      \ && b:vimtex.compiler.is_running()
            call vimtex#log#info('Compiler is running')
        el
            call vimtex#log#info('Compiler is not running!')
        en
    en
endf


fun! s:init_compiler(options) abort
    try
        let l:options =  get(
                        \ g:,
                        \ 'vimtex_compiler_' . g:vimtex_compiler_method,
                        \ {},
                    \ )
            "\要搜 vimtex_compiler_latexmk 就来这里

        let l:options = extend(deepcopy(l:options),   a:options)
        let l:compiler   = vimtex#compiler#{g:vimtex_compiler_method}#init(l:options)
        return l:compiler

    catch /VimTeX: Requirements not met/
        call vimtex#log#error('Compiler was not initialized!')
    catch /E117/
        call vimtex#log#error(
                    \ 'Invalid compiler: ' . g:vimtex_compiler_method,
                    \ 'Please see :h g:vimtex_compiler_method')
    endtry

    return {}
endf




let s:output_factory = {}
fun! s:output_factory.create(file) dict abort
    let l:vimtex = b:vimtex
    silent execute 'split' a:file
    let b:vimtex = l:vimtex

    setl     autoread
    setl     nomodifiable
    setl     bufhidden=wipe

    nno      <silent><buffer><nowait> q :bwipeout<cr>
    if has('nvim') || has('gui_running')
        nno      <silent><buffer><nowait> <esc> :bwipeout<cr>
    en

    let s:output = deepcopy(self)
    unlet s:output.create

    let s:output.name = a:file
    let s:output.ftime = -1
    let s:output.paused = v:false
    let s:output.bufnr = bufnr('%')
    let s:output.winnr = bufwinnr('%')
    let s:output.timer = timer_start(100,
                \ {_ -> s:output.update()},
                \ {'repeat': -1})

    aug  vimtex_output_window
        au!
        au BufDelete <buffer> call s:output.destroy()
        au BufEnter     *     call s:output.update()
        au FocusGained  *     call s:output.update()
        au CursorHold   *     call s:output.update()
        au CursorHoldI  *     call s:output.update()
        au CursorMoved  *     call s:output.update()
        au CursorMovedI *     call s:output.update()
    aug  END
endf


fun! s:output_factory.pause() dict abort
    let self.paused = v:true
endf


fun! s:output_factory.resume() dict abort
    let self.paused = v:false
endf


fun! s:output_factory.update() dict abort
    if self.paused | return | endif

    let l:ftime = getftime(self.name)
    if self.ftime >= l:ftime
                \ || mode() ==? 'v' || mode() ==# "\<c-v>"
        return
    en
    let self.ftime = getftime(self.name)

    if bufwinnr(self.name) != self.winnr
        let self.winnr = bufwinnr(self.name)
    en

    let l:swap = bufwinnr('%') != self.winnr
    if l:swap
        let l:return = bufwinnr('%')
        exe     'keepalt' self.winnr . 'wincmd w'
    en

    " Force reload file content
    silent edit

    if l:swap
        " Go to last line of file if it is not the current window
        norm! Gzb
        exe     'keepalt' l:return . 'wincmd w'
        redraw
    en
endf


fun! s:output_factory.destroy() dict abort
    call timer_stop(self.timer)
    au! vimtex_output_window
    augroup! vimtex_output_window
    unlet s:output
endf




" Initialize module

if !get(g:, 'vimtex_compiler_enabled') | finish | endif

aug  vimtex_compiler
    au!
    au VimLeave * call vimtex#compiler#stop_all()
aug  END


