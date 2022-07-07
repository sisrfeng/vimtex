fun! vimtex#view#zathura#new() abort
    return s:viewer.init()
endf


let s:viewer = vimtex#view#_template#new({
                        \ 'name'        : 'Zathura',
                        \ 'xwin_id'     : 0,
                        \ 'has_synctex' : 1,
                        \})

fun! s:viewer._check() dict abort
    " Check if Zathura is executable
    if !executable('zathura')
        call vimtex#log#error('Zathura is not executable!')
        return v:false
    en


    " Check if Zathura has libsynctex
    if g:vimtex_view_zathura_check_libsynctex && executable('ldd')
        let l:shared = vimtex#jobs#capture('ldd $(which zathura)')
        if v:shell_error == 0
        \ && empty(filter(l:shared, 'v:val =~# ''libsynctex'''))
                call vimtex#log#warning('Zathura is not linked to libsynctex!')
                let s:viewer.has_synctex = 0
        en
    en

    return v:true
endf


fun! s:viewer._exists() dict abort
    return self.xdo_exists()
    echom "self.xdo_exists 是: "   self.xdo_exists
endf


fun! s:viewer._start(outfile) dict abort
    let self.cmd_start = s:cmdline(a:outfile, self.has_synctex, 1)
    "\ echom "self.cmd_start 是: "   self.cmd_start
    "\ self.cmd_start 主要是:
        "\ zathura  -x
            " "nvim --headless -c \"VimtexInverseSearch %{line} '%{input}'\""
            "\ --synctex-forward 6:1:'data/adaptation.tex'   '../PasS_vimtex.pdf' &
                            "\ 行:列:

        "\ zathura  -x:  Set the synctex ¿editor¿ command.


    call vimtex#jobs#run(self.cmd_start)

    call self.xdo_get_id()
endf


fun! s:viewer._forward_search(outfile) dict abort
    if !self.has_synctex | return | endif

    let l:synctex_file = fnamemodify(a:outfile, ':r') . '.synctex.gz'
    if !filereadable(l:synctex_file) | return | endif

    let self.cmd_forward_search = s:cmdline(a:outfile, self.has_synctex, 0)

    call vimtex#jobs#run(self.cmd_forward_search)
    echom "self.cmd_forward_search 是: "   self.cmd_forward_search
endf



fun! s:viewer.get_pid() dict abort
    " First try to match full output file name
    let l:outfile = fnamemodify(get(self, 'outfile', self.out()), ':t')
    let l:output = vimtex#jobs#capture(
                \ 'pgrep -nf "^zathura.*' . escape(l:outfile, '~\%.') . '"')
    let l:pid = str2nr(join(l:output, ''))
    if !empty(l:pid) | return l:pid | endif

    " Now try to match correct servername as fallback
    let l:output = vimtex#jobs#capture(
                \ 'pgrep -nf "^zathura.+--servername ' . v:servername . '"')
    return str2nr(join(l:output, ''))
endf


fun! s:cmdline(outfile, synctex, start) abort
    let l:cmd  = 'zathura'

    if a:start
        let l:cmd .= ' ' . g:vimtex_view_zathura_options
        if a:synctex
            let l:cmd .= printf(
                        \ ' -x "%s -c \"VimtexInverseSearch %%{line} ''%%{input}''\""',
                        \ s:inverse_search_cmd)
        en
    en

    if a:synctex && (!a:start || g:vimtex_view_forward_search_on_start)
        let l:cmd .= printf(
                    \ ' --synctex-forward %d:%d:%s',
                    \ line('.'), col('.'),
                    \ vimtex#util#shellescape(
                    \   vimtex#paths#relative(expand('%:p'), b:vimtex.root)))
    en

    return l:cmd . ' '
          \ . vimtex#util#shellescape(vimtex#paths#relative(a:outfile, getcwd()))
          \ . '&'
endf




let s:inverse_search_cmd = get( g:,
                         \ 'vimtex_callback_progpath',
                         \ get( v:,
                            \ 'progpath',
                             \ get(
                                 \ v:,
                                 \ 'progname',
                                 \ '',
                                 \ ),
                             \ ),
                        \ )
                    \ . (has('nvim')
                    \   ? ' --headless'
                    \   : ' -T dumb --not-a-term -n')
