fun! vimtex#view#_template#new(viewer) abort
    return extend(
        \ deepcopy(s:viewer),
        \ a:viewer,
       \ )
endf

let s:viewer = {}

fun! s:viewer.init() abort dict
    let l:viewer = deepcopy(self)
    unlet l:viewer.init
    return l:viewer
endf


fun! s:viewer.check() abort
    if !has_key(self, '_check_value')
        let self._check_value = self._check()
    en

    return self._check_value
endf


fun! s:viewer.out() dict abort
    if g:vimtex_view_use_temp_files
        " Copy pdf
            let l:out = b:vimtex.root . '/' . b:vimtex.name . '_bk.pdf'

            if getftime(b:vimtex.out())   >   getftime(l:out)
                call writefile(
                        \ readfile(b:vimtex.out(), 'b'),
                        \ l:out,
                        \ 'b',
                    \ )
            en

        " Copy synctex file
            let l:old = b:vimtex.ext('synctex.gz')
            let l:new = fnamemodify(l:out, ':r') . '.synctex.gz'
            if getftime(l:old)   >    getftime(l:new)  | call rename(l:old, l:new)  | en
    el
        let l:out = b:vimtex.out(1)
    en

    return filereadable(l:out)
        \ ? l:out
        \ : ''
endf


fun! s:viewer.view(file) dict abort
    if !self.check() | return | endif

    if !empty( fnameescape(a:file) )
        "\ echom "a:file 是: "   a:file
        let l:outfile = fnameescape(a:file)
    el
        let l:outfile = self.out()
    en

    if !filereadable(l:outfile)
        if l:outfile == ''
            "\ let g:vimtex_view_use_temp_files = 0会导致进入这里?
            echom  'l:outfile为空,pdf不存在吧,  现在调用compile_ss()'
            call vimtex#compiler#compile_ss()

        el
            "\ pdf就算能打开 filereadable也为0?
            "\ call vimtex#log#warning('此PDF不满足 filereadable(): ', l:outfile)
            "\ echom  '此PDF不满足 filereadable(): ' . l:outfile
        en
        return
    en

    if self._exists()
        call self._forward_search(l:outfile)
    el
        call self._start(l:outfile)
    en

    if exists('#User#VimtexEventView')
        doautocmd <nomodeline> User VimtexEventView
    en
endf


fun! s:viewer.compiler_callback(outfile) dict abort
    if !g:vimtex_view_automatic
    \ || has_key(self, 'started_through_callback')
        return
    el
        call self._start(a:outfile)
        let self.started_through_callback = 1
    en

endf


fun! s:viewer.compiler_stopped() dict abort
    if has_key(self, 'started_through_callback')
        unlet self.started_through_callback
    en
endf



fun! s:viewer._exists() dict abort
    return v:false
endf



fun! s:viewer.__pprint() abort dict
    let l:list = []

    if has_key(self, 'xwin_id')
        call add(l:list, ['xwin id', self.xwin_id])
    en

    if has_key(self, 'job')
        call add(l:list, ['job', self.job])
    en

    for l:key in filter(keys(self), 'v:val =~# ''^cmd''')
        call add(l:list, [l:key, self[l:key]])
    endfor

    return l:list
endf


"\ Only relevant for those that has the "xwin_id" attribute.
"\ (though these are made available to all viewers)
" Methods that rely on xdotool.
    fun! s:viewer.xdo_check() dict abort
        return executable('xdotool') && has_key(self, 'xwin_id')
    endf


    fun! s:viewer.xdo_get_id() dict abort
        if !self.xdo_check() | return 0 | endif

        if self.xwin_id <= 0
            " Allow some time for the viewer to start properly
            sleep 500m

            let l:xwin_ids = vimtex#jobs#capture('xdotool search --class ' . self.name)
            if len(l:xwin_ids) == 0
                call vimtex#log#warning('Viewer cannot find ' . self.name . ' window ID!')
                let self.xwin_id = 0
            el
                let self.xwin_id = l:xwin_ids[-1]
            en
        en

        return self.xwin_id
    endf


    fun! s:viewer.xdo_exists() dict abort
        if !self.xdo_check() | return v:false | endif

        " If xwin_id is already set, check if it still exists
        if self.xwin_id > 0
            let xwin_ids = vimtex#jobs#capture('xdotool search --class ' . self.name)
            if index(xwin_ids, self.xwin_id) < 0
                let self.xwin_id = 0
            en
        en

        " If xwin_id is unset, check if matching viewer windows exist
        if self.xwin_id == 0
            let l:pid = has_key(self, 'get_pid') ? self.get_pid() : 0
            if l:pid > 0
                let xwin_ids = vimtex#jobs#capture(
                            \   'xdotool search --all --pid ' . l:pid
                            \ . ' --name ' . fnamemodify(self.out(), ':t'))
                let self.xwin_id = get(xwin_ids, 0)
            el
                let xwin_ids = vimtex#jobs#capture(
                            \ 'xdotool search --name ' . fnamemodify(self.out(), ':t'))
                let ids_already_used = filter(map(
                            \   deepcopy(vimtex#state#list_all()),
                            \   {_, x -> get(get(x, 'viewer', {}), 'xwin_id')}),
                            \ 'v:val > 0')
                for id in xwin_ids
                    if index(ids_already_used, id) < 0
                        let self.xwin_id = id
                        break
                    en
                endfor
            en
        en

        return self.xwin_id > 0
    endf


    fun! s:viewer.xdo_send_keys(keys) dict abort
        if !self.xdo_check() || empty(a:keys) || self.xwin_id <= 0 | return | endif

        call vimtex#jobs#run('xdotool key --window ' . self.xwin_id . ' ' . a:keys)
    endf


    fun! s:viewer.xdo_focus_viewer() dict abort
        if !self.xdo_check() || self.xwin_id <= 0 | return | endif

        call vimtex#jobs#run('xdotool windowactivate ' . self.xwin_id . ' --sync')
        call vimtex#jobs#run('xdotool windowraise ' . self.xwin_id)
    endf


    fun! s:viewer.xdo_focus_vim() dict abort
        if !executable('xdotool') | return | endif
        if !executable('pstree') | return | endif

        " The idea is to use xdotool to focus the window ID of the relevant windowed
        " process. To do this, we need to check the process tree. Inside TMUX we need
        " to check from the PID of the tmux client. We find this PID by listing the
        " PIDS of the corresponding pty.
        if empty($TMUX)
            let l:current_pid = getpid()
        el
            let l:output = vimtex#jobs#capture('tmux display-message -p "#{client_tty}"')
            let l:pts = split(trim(l:output[0]), '/')[-1]
            let l:current_pid = str2nr(vimtex#jobs#capture('ps o pid t ' . l:pts)[1])
        en

        let l:output = join(vimtex#jobs#capture('pstree -s -p ' . l:current_pid))
        let l:pids = split(l:output, '\D\+')
        let l:pids = l:pids[: index(l:pids, string(l:current_pid))]

        for l:pid in reverse(l:pids)
            let l:output = vimtex#jobs#capture(
                        \ 'xdotool search --onlyvisible --pid ' . l:pid)
            let l:xwinids = filter(reverse(l:output), '!empty(v:val)')

            if !empty(l:xwinids)
                call vimtex#jobs#run('xdotool windowactivate ' . l:xwinids[0] . ' &')
                call feedkeys("\<c-l>", 'tn')
                return l:xwinids[0]
                break
            en
        endfor
    endf

