fun! vimtex#info#init_buffer() abort
    com!  -buffer -bang VimtexInfo call vimtex#info#open(<q-bang> == '!')

    nno  <buffer> <plug>(vimtex-info)      :VimtexInfo<cr>
    nno  <buffer> <plug>(vimtex-info-full) :VimtexInfo!<cr>
endf

let s:info = {
        \ 'name' : 'VimtexInfo',
        \ 'global' : 0,
      \}


fun! vimtex#info#open(global) abort
    let s:info.global = a:global
    call vimtex#scratch#new(s:info)
endf


fun! s:info.print_content() abort dict
    for l:line in self.gather_system_info()
        call append('$', l:line)
    endfor

    call append('$', '')
    call append('$', '')
    for l:line in self.gather_state_info()
        call append('$', l:line)
    endfor
endf


fun! s:info.gather_system_info() abort dict
    let l:lines = [
            \ 'System info:',
            "\ \ '  OS: ' . s:get_os_info(),
            "\ \ '  Vim version: ' . s:get_vim_info(),
            \]

    if has('clientserver') || has('nvim')
        call add(l:lines, '  Has clientserver: true')
        call add(l:lines, '  Servername: '
                            \ . (empty(v:servername)
                                \ ? 'undefined (nvim启动时没加--servername吧)'
                                \ : v:servername))
    el
        call add(l:lines, '  Has clientserver: false')
    en

    return l:lines
endf


fun! s:info.gather_state_info() abort dict
    if self.global
        let l:lines = []
        for l:data in vimtex#state#list_all()
            let l:lines += s:get_info(l:data)
            let l:lines += ['']
        endfor
        call remove(l:lines, -1)
    el
        let l:lines = s:get_info(b:vimtex)
    en

    return l:lines
endf


fun! s:info.syntax() abort dict
    syn  match VimtexInfoOther /.*/
    syn  match VimtexInfoKey /^.\{-}:/ nextgroup=VimtexInfoValue
    syn  match VimtexInfoValue /.*/ contained
    syn  match VimtexInfoTitle /VimTeX project:/ nextgroup=VimtexInfoValue
    syn  match VimtexInfoTitle /System info/
endf



"
" Functions to parse the VimTeX state data
"
fun! s:get_info(item, ...) abort
    if empty(a:item) | return [] | endif
    let l:indent = a:0 > 0 ? a:1 : 0

    if type(a:item) == v:t_dict
        return s:parse_dict(a:item, l:indent)
    en

    if type(a:item) == v:t_list
        let l:entries = []
        for [l:title, l:Value] in a:item
            if type(l:Value) == v:t_dict
                call extend(l:entries, s:parse_dict(l:Value, l:indent, l:title))
            elseif type(l:Value) == v:t_list
                call extend(l:entries, s:parse_list(l:Value, l:indent, l:title))
            el
                call add(l:entries,
                            \ repeat('  ', l:indent) . printf('%s: %s', l:title, l:Value))
            en
            unlet l:Value
        endfor
        return l:entries
    en
endf


fun! s:parse_dict(dict, indent, ...) abort
    if empty(a:dict) | return [] | endif
    let l:dict = a:dict
    let l:indent = a:indent
    let l:entries = []

    if a:0 > 0
        let l:title = a:1
        let l:name = ''
        if has_key(a:dict, 'name')
            let l:dict = deepcopy(a:dict)
            let l:name = remove(l:dict, 'name')
        en
        call add(l:entries,
                    \ repeat('  ', l:indent) . printf('%s: %s', l:title, l:name))
        let l:indent += 1
    en

    let l:items = has_key(l:dict, '__pprint')
                \ ? l:dict.__pprint() : items(l:dict)

    return extend(l:entries, s:get_info(l:items, l:indent))
endf


fun! s:parse_list(list, indent, title) abort
    if empty(a:list) | return [] | endif

    let l:entries = []
    let l:indent = repeat('  ', a:indent)
    if type(a:list[0]) == v:t_list
        let l:name = ''
        let l:index = 0

        " l:entry[0] == title
        " l:entry[1] == value
        for l:entry in a:list
            if l:entry[0] ==# 'name'
                let l:name = l:entry[1]
                break
            en
            let l:index += 1
        endfor

        if empty(l:name)
            let l:list = a:list
        el
            let l:list = deepcopy(a:list)
            call remove(l:list, l:index)
        en

        call add(l:entries, l:indent . printf('%s: %s', a:title, l:name))
        call extend(l:entries, s:get_info(l:list, a:indent+1))
    el
        call add(l:entries, l:indent . printf('%s:', a:title))
        for l:value in a:list
            call add(l:entries, l:indent . printf('  %s', l:value))
        endfor
    en

    return l:entries
endf



"
" Other utility functions
"
fun! s:get_os_info() abort
    let l:os = vimtex#util#get_os()

    if l:os ==# 'linux'
        let l:result = executable('lsb_release')
                \ ? vimtex#jobs#cached('lsb_release -d')[0][12:]
                \ : vimtex#jobs#cached('uname -sr')[0]
        return substitute(l:result, '^\s*', '', '')
    elseif l:os ==# 'mac'
        let l:name = vimtex#jobs#cached('sw_vers -productName')[0]
        let l:version = vimtex#jobs#cached('sw_vers -productVersion')[0]
        let l:build = vimtex#jobs#cached('sw_vers -buildVersion')[0]
        return l:name . ' ' . l:version . ' (' . l:build . ')'
    el
        if !exists('s:win_info')
            let s:win_info = vimtex#jobs#cached('systeminfo')
        en

        try
            let l:name = vimtex#util#trim(matchstr(s:win_info[1], ':\s*\zs.*'))
            let l:version = vimtex#util#trim(matchstr(s:win_info[2], ':\s*\zs.*'))
            return l:name . ' (' . l:version . ')'
        catch
            return 'Windows (' . string(s:win_info) . ')'
        endtry
    en
endf


fun! s:get_vim_info() abort
    let l:info = vimtex#util#command('version')

    if has('nvim')
        return l:info[0]
    el
        let l:version = 'VIM ' . strpart(l:info[0], 18, 3) . ' ('
        let l:index = 2 - (l:info[1] =~# ':\s*\d')
        let l:version .= matchstr(l:info[l:index], ':\s*\zs.*') . ')'
        return l:version
    en
endf


