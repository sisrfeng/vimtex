fun! vimtex#parser#tex(file, ...) abort
    return vimtex#parser#tex#parse(a:file, a:0 > 0 ? a:1 : {})
endf


fun! vimtex#parser#preamble(file, ...) abort
    return vimtex#parser#tex#parse_preamble(a:file, a:0 > 0 ? a:1 : {})
endf


fun! vimtex#parser#auxiliary(file) abort
    return vimtex#parser#auxiliary#parse(a:file)
endf


fun! vimtex#parser#fls(file) abort
    return vimtex#parser#fls#parse(a:file)
endf


fun! vimtex#parser#toc(...) abort
    let l:vimtex = a:0 > 0 ? a:1 : b:vimtex

    let l:cache = vimtex#cache#open('parsertoc', {
                \ 'persistent': 0,
                \ 'default': {'entries': [], 'ftime': -1},
                \})
    let l:current = l:cache.get(l:vimtex.tex)

    " Update cache if relevant
    let l:ftime = l:vimtex.getftime()
    if l:ftime > l:current.ftime
        let l:cache.modified = 1
        let l:current.ftime = l:ftime
        let l:current.entries = vimtex#parser#toc#parse(l:vimtex.tex)
    en

    return deepcopy(l:current.entries)
endf


fun! vimtex#parser#bib(file, ...) abort
    return vimtex#parser#bib#parse(a:file, a:0 > 0 ? a:1 : {})
endf



fun! vimtex#parser#get_externalfiles() abort
    let l:preamble = vimtex#parser#preamble(b:vimtex.tex)

    let l:result = []
    for l:line in filter(l:preamble, 'v:val =~# ''\\externaldocument''')
        let l:name = matchstr(l:line, '{\zs[^}]*\ze}')
        call add(l:result, {
                    \ 'tex' : l:name . '.tex',
                    \ 'aux' : l:name . '.aux',
                    \ 'opt' : matchstr(l:line, '\[\zs[^]]*\ze\]'),
                    \ })
    endfor

    return l:result
endf


fun! vimtex#parser#selection_to_texfile(opts) range abort
    let l:opts = extend({
                    \ 'type'           :  'range'                   ,
                    \ 'range'          :  [0, 0]                    ,
                    \ 'name'           :  b:vimtex.name . '_Select' ,
                    \ 'template_name'  :  'vimtex-template.tex'     ,
                    \ }                                             ,
                    \ a:opts
                  \ )

    " Set range from selection type
    if l:opts.type ==# 'command'
        let l:opts.range = [a:firstline, a:lastline]

    elseif l:opts.type ==# 'visual'
        let l:opts.range = [line("'<"), line("'>")]

    elseif l:opts.type ==# 'operator'
        let l:opts.range = [line("'["), line("']")]
    en

    let l:lines = getline(l:opts.range[0], l:opts.range[1])

    " Restrict the selection to whatever is within the
    " \begin{document} ...
    " \end{document} environment
    let l:start = 0
    let l:end   = len(l:lines)
    for l:n in range(len(l:lines))
        if l:lines[l:n] =~# '\\begin\s*{document}'
            let l:start = l:n + 1
        elseif l:lines[l:n] =~# '\\end\s*{document}'
            let l:end = l:n - 1
            break
        en
    endfor

    " Check if the selection has any real content
    if l:start >= len(l:lines)
                \ || l:end < 0
                \ || empty( substitute(
                                    \ join(l:lines[l:start : l:end], ''),
                                    \ '\s*',
                                    \ '',
                                    \ '',
                                    \ )
                        \ )
        return {}
    en
    let l:lines = l:lines[l:start : l:end]

    " Load template (if available)
    let l:template = []
    for l:template_file in [
                        \ expand('%:r') . '-' . l:opts.template_name,
                        \ l:opts.template_name,
                        \]
        if filereadable(l:template_file)
            let l:template = readfile(l:template_file)
            break
        en
    endfor

    " Define the set of lines to compile
    if !empty(l:template)
        let l:i = index(l:template, '%%% VIMTEX PLACEHOLDER')
        let l:lines = l:template[:l:i-1] + l:lines + l:template[l:i+1:]
    el
        let l:lines = vimtex#parser#preamble(b:vimtex.tex)
                    \ + ['\begin{document}']
                    \ + l:lines
                    \ + ['\end{document}']
    en

    " Write content to temporary file
    let l:files = {}
    let l:files.root = b:vimtex.root
    let l:files.base = l:opts.name      "\  主文件名


    let l:files.tex  = l:files.root . '/' . b:vimtex.compiler.build_dir . '/' . l:files.base . '.tex'
    let l:files.pdf  = l:files.root . '/' . b:vimtex.compiler.build_dir . '/' . l:files.base . '.pdf'
    let l:files.log  = l:files.root . '/' . b:vimtex.compiler.build_dir . '/' . l:files.base . '.log'
    let l:files.base .= '.tex'
    call writefile(l:lines, l:files.tex)

    return l:files
endf


