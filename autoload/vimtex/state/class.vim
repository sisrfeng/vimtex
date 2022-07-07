fun! vimtex#state#class#new(main, main_parser, preserve_root) abort
    let l:new = deepcopy(s:vimtex)

    let l:new.root = fnamemodify(a:main, ':h')
    let l:new.base = fnamemodify(a:main, ':t')
    let l:new.name = fnamemodify(a:main, ':t:r')
    let l:new.main_parser = a:main_parser

    if a:preserve_root && exists('b:vimtex')
        let l:new.root = b:vimtex.root
        let l:new.base = vimtex#paths#relative(a:main, l:new.root)
    en

    let l:ext = fnamemodify(a:main, ':e')
    let l:new.tex = index(['tex', 'dtx', 'tikz', 'ins'], l:ext) >= 0
                \ ? a:main : ''

    " Get preamble for some state parsing
    let l:preamble = !empty(l:new.tex)
                \ ? vimtex#parser#preamble(l:new.tex, {'root' : l:new.root})
                \ : []

    let l:new.documentclass = s:parse_documentclass(l:preamble)
    let l:new.packages = s:parse_packages(l:preamble)
    let l:new.graphicspath = s:parse_graphicspath(l:preamble, l:new.root)
    let l:new.sources = s:gather_sources(l:new.tex, l:new.root)

    " Update package list from fls file (if available)
    call l:new.update_packages()

    " Initialize state in submodules
    let l:new.disabled_modules = get(s:, 'disabled_modules', [])
    for l:mod in filter(
                \ ['view', 'compiler', 'qf', 'toc', 'fold', 'context'],
                \ 'index(l:new.disabled_modules, v:val) < 0')
        call vimtex#{l:mod}#init_state(l:new)
    endfor

    return l:new
endf


let s:vimtex = {}

fun! s:vimtex.__pprint() abort dict
    let l:items = [
                \ ['name', self.name],
                \ ['base', self.base],
                \ ['root', self.root],
                \ ['tex', self.tex],
                \ ['main parser', self.main_parser],
                \]

    if exists('self.documentclass')
        call add(l:items, ['document class', self.documentclass])
    en

    if !empty(self.packages)
        call add(l:items, ['packages', join(sort(keys(self.packages)))])
    en

    if len(self.sources) >= 2
        call add(l:items, ['source files', self.sources])
    en

    call add(l:items, ['compiler', get(self, 'compiler', {})])
    call add(l:items, ['viewer', get(self, 'viewer', {})])

    if exists('self.qf.name')
        call add(l:items, ['qf method', self.qf.name])
    en

    return [['VimTeX project', l:items]]
endf


fun! s:vimtex.cleanup() abort dict
    if exists('self.compiler.is_running')
                \ && self.compiler.is_running()
        call self.compiler.kill()
    en

    if exists('#User#VimtexEventQuit')
        if exists('b:vimtex')
            let b:vimtex_tmp = b:vimtex
        en
        let b:vimtex = self
        doautocmd <nomodeline> User VimtexEventQuit
        if exists('b:vimtex_tmp')
            let b:vimtex = b:vimtex_tmp
            unlet b:vimtex_tmp
        el
            unlet b:vimtex
        en
    en

    " Close quickfix window
    silent! cclose
endf


fun! s:vimtex.getftime() abort dict
    return max(map(copy(self.sources), 'getftime(self.root . ''/'' . v:val)'))
endf


fun! s:vimtex.update_packages() abort dict
    " Try to parse .fls file if present, as it is usually more complete. That is,
    " it contains a generated list of all the packages that are used.
    for l:line in vimtex#parser#fls(self.fls())
        let l:package = matchstr(l:line, '^INPUT \zs.\+\ze\.sty$')
        let l:package = fnamemodify(l:package, ':t')
        if !empty(l:package)
            let self.packages[l:package] = {}
        en
    endfor
endf


fun! s:vimtex.get_tex_program() abort dict
    let l:tex_program_re =
                \ '\v^\c\s*\%\s*!?\s*tex\s+%(ts-)?program\s*\=\s*\zs.*\ze\s*$'

    let l:lines = vimtex#parser#preamble(self.tex, {'root' : self.root})[:20]
    call map(l:lines, 'matchstr(v:val, l:tex_program_re)')
    call filter(l:lines, '!empty(v:val)')
    return tolower(get(l:lines, -1, '_'))
endf



fun! s:vimtex.ext(ext, ...) abort dict
    " Check for various output directories
    " * Environment variable VIMTEX_OUTPUT_DIRECTORY. Note that this overrides
    "   any VimTeX settings like g:vimtex_compiler_latexmk.build_dir!
    " * Compiler settings,
        "  g:vimtex_compiler_latexmk.build_dir
        "  b:vimtex.compiler.build_dir
    " * Fallback to the main root directory
    for l:root in [
                \ $VIMTEX_OUTPUT_DIRECTORY,
                \ get(get(self, 'compiler', {}), 'build_dir', ''),
                \ self.root
                \]
        if empty(l:root) | continue | endif

        let l:cand = printf('%s/%s.%s', l:root, self.name, a:ext)
        if !vimtex#paths#is_abs(l:root)
            let l:cand = self.root . '/' . l:cand
        en

        if a:0 > 0 || filereadable(l:cand)
            return fnamemodify(l:cand, ':p')
        en
    endfor

    return ''
endf


fun! s:vimtex.log() abort dict
    return self.ext('log')
endf


fun! s:vimtex.aux() abort dict
    return self.ext('aux')
endf


fun! s:vimtex.fls() abort dict
    return self.ext('fls')
endf


fun! s:vimtex.out(...) abort dict
    return call(self.ext, ['pdf'] + a:000, self)
endf




fun! s:parse_documentclass(preamble) abort
    let l:preamble_lines = filter(copy(a:preamble), {_, x -> x !~# '^\s*%'})
    return matchstr(join(l:preamble_lines, ''),
                \ '\\documentclass[^{]*{\zs[^}]\+\ze}')
endf


fun! s:parse_packages(preamble) abort
    let l:usepackages = filter(copy(a:preamble),
                \ 'v:val =~# ''\v%(usep|RequireP)ackage''')
    let l:pat = g:vimtex#re#not_comment . g:vimtex#re#not_bslash
            \ . '\v\\%(usep|RequireP)ackage\s*%(\[[^[\]]*\])?\s*\{\s*\zs%([^{}]+)\ze\s*\}'
    call map(l:usepackages, {_, x -> split(matchstr(x, l:pat), '\s*,\s*')})

    let l:parsed = {}
    for l:packages in l:usepackages
        for l:package in l:packages
            let l:parsed[l:package] = {}
        endfor
    endfor

    return l:parsed
endf


fun! s:parse_graphicspath(preamble, root) abort
    " Combine the preamble as one long string of commands
    let l:preamble = join(map(copy(a:preamble),
                \ {_, x -> substitute(x, '\\\@<!%.*', '', '')}))

    " Extract the graphicspath command from this string
    let l:graphicspath = matchstr(l:preamble,
                    \ g:vimtex#re#not_bslash
                    \ . '\\graphicspath\s*\{\s*\{\s*\zs.{-}\ze\s*\}\s*\}'
                    \)

    " Add all parsed graphicspaths
    let l:paths = []
    for l:path in split(l:graphicspath, '\s*}\s*{\s*')
        let l:path = substitute(l:path, '\/\s*$', '', '')
        call add(l:paths, vimtex#paths#is_abs(l:path)
                    \ ? l:path
                    \ : simplify(a:root . '/' . l:path))
    endfor

    return l:paths
endf


fun! s:gather_sources(texfile, root) abort
    let l:sources = vimtex#parser#tex#parse_files(
                \ a:texfile, {'root' : a:root})

    return map(l:sources, 'vimtex#paths#relative(v:val, a:root)')
endf


