fun! vimtex#ui#choose(container, ...) abort
    if empty(a:container) | return '' | endif

    let l:options = extend(
                \ {
                \   'abort': v:true,
                \   'prompt': '选一个吧:',
                \   'return': 'value',
                \ },
                \ a:0 > 0 ? a:1 : {}
               \ )

    let [l:index, l:value] = s:choose_from(
        \ type(a:container) == v:t_dict
            \ ? values(a:container)
            \ : a:container,
        \ l:options,
       \ )
    sleep 75m
    redraw!

    if l:options.return ==# 'value'  | return l:value  | en

    if type(a:container) == v:t_dict
        return l:index >= 0
        \ ? keys(a:container)[l:index]
        \ : ''
    en

    return l:index
endf


fun! vimtex#ui#menu(actions) abort
    " Argument: The 'actions' argument is a dictionary/object which contains
    "   a list of menu items and corresponding actions (dict functions).
    "   Something like this:
    "
    "   let a:actions = {
    "         \ 'prompt': 'Prompt string for menu',
    "         \ 'menu': [
    "         \   {'name': 'My first action',
    "         \    'func': 'action1'},
    "         \   {'name': 'My second action',
    "         \    'func': 'action2'},
    "         \   ...
    "         \ ],
    "         \ 'action1': Func,
    "         \ 'action2': Func,
    "         \ ...
    "         \}
    if empty(a:actions) | return | endif

    let l:choice = vimtex#ui#choose(a:actions.menu, {
                \ 'prompt': a:actions.prompt,
                \})
    if empty(l:choice) | return | endif

    try
        call a:actions[l:choice.func]()
    catch
        " error here
    endtry
endf



fun! s:choose_from(list, options) abort
    let l:length = len(a:list)
    let l:digits = len(l:length)
    if l:length == 1 | return [0, a:list[0]] | endif

    " Create the menu
    let l:menu = []
    let l:format = printf('%%%dd', l:digits)
    let l:i = 0
    for l:x in a:list
        let l:i += 1
        call add(l:menu, [
                    \ ['VimtexWarning', printf(l:format, l:i) . ': '],
                    \ type(l:x) == v:t_dict ? l:x.name : l:x
                    \])
    endfor
    if a:options.abort
        call add(l:menu, [
                    \ ['VimtexWarning', repeat(' ', l:digits - 1) . 'x: '],
                    \ 'Abort'
                    \])
    en

    " Loop to get a valid choice
    while 1
        redraw!

        call vimtex#echo#echo(a:options.prompt)
        for l:line in l:menu
            call vimtex#echo#formatted(l:line)
        endfor

        try
            let l:choice = s:get_number(l:length, l:digits, a:options.abort)
            if a:options.abort && l:choice == -2
                return [-1, '']
            en

            if l:choice >= 0 && l:choice < len(a:list)
                return [l:choice, a:list[l:choice]]
            en
        endtry
    endwhile
endf


fun! s:get_number(max, digits, abort) abort
    let l:choice = ''
    echo '> '

    while len(l:choice) < a:digits
        if len(l:choice) > 0 && (l:choice . '0') > a:max
            return l:choice - 1
        en

        let l:input = nr2char(getchar())

        if a:abort && l:input ==# 'x'
            echon l:input
            return -2
        en

        if len(l:choice) > 0 && l:input ==# "\<cr>"
            return l:choice - 1
        en

        if l:input !~# '\d' | continue | endif

        if (l:choice . l:input) > 0
            let l:choice .= l:input
            echon l:input
        en
    endwhile

    return l:choice - 1
endf


