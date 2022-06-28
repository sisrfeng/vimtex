" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

fun! vimtex#echo#echo(message) abort
    echohl VimtexMsg
        echo a:message
    echohl None
endf


fun! vimtex#echo#input(opts) abort
    if g:vimtex_echo_verbose_input
                \ && has_key(a:opts, 'info')
        call vimtex#echo#formatted(a:opts.info)
    en

    let l:args = [get(a:opts, 'prompt', '> ')]
    let l:args += [get(a:opts, 'default', '')]
    if has_key(a:opts, 'complete')
        let l:args += [a:opts.complete]
    en

    echohl VimtexMsg
    let l:reply = call('input', l:args)
    echohl None
    return l:reply
endf


fun! vimtex#echo#formatted(parts) abort
    echo ''
    try
        for part in a:parts
            if type(part) != v:t_string
                exe  'echohl' part[0]
                echon part[1]
            el
                echohl VimtexMsg
                echon part
            en
            unlet part
        endfor
    finally
        echohl None
    endtry
endf


