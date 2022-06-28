fun! vimtex#qf#biblatex#addqflist(blg) abort
    if get(g:vimtex_quickfix_blgparser, 'disable') | return | endif

    try
        call s:qf.addqflist(a:blg)
    catch /biblatex Aborted/
    endtry
endf



let s:qf = {
    \ 'file' : '',
    \ 'types' : [],
    \ 'db_files' : [],
    \}

fun! s:qf.set_errorformat() abort dict "{{{1
    setl  errorformat=%+E%.%#\>\ ERROR%m
    setl  errorformat+=%+W%.%#\>\ WARN\ -\ Duplicate\ entry%m
    setl  errorformat+=%+W%.%#\>\ WARN\ -\ The\ entry%.%#cannot\ be\ encoded%m
    setl  errorformat+=%-G%.%#
endf


fun! s:qf.addqflist(blg) abort
    let self.file = a:blg
    let self.root = fnamemodify(a:blg, ':h')
    if empty(self.file) | throw 'biblatex Aborted' | endif

    let self.types = map(
                \ filter(items(s:), 'v:val[0] =~# ''^type_'''),
                \ 'v:val[1]')
    let self.db_files = []

    call vimtex#qf#u#caddfile(self, fnameescape(self.file))

    call self.fix_paths()
endf


fun! s:qf.fix_paths() abort
    let l:qflist = getqflist()
    try
        let l:title = getqflist({'title': 1})
    catch /E118/
        let l:title = 'VimTeX errors'
    endtry

    for l:qf in l:qflist
        for l:type in self.types
            if l:type.fix(self, l:qf) | break | endif
        endfor
    endfor

    call setqflist(l:qflist, 'r')

    " Set title if supported
    try
        call setqflist([], 'r', l:title)
    catch
    endtry
endf


fun! s:qf.get_db_files() abort
    if empty(self.db_files)
        let l:preamble = vimtex#parser#preamble(b:vimtex.tex, {
                    \ 'root' : b:vimtex.root,
                    \})
        let l:files = map(
                    \ filter(l:preamble, 'v:val =~# ''\\addbibresource'''),
                    \ 'matchstr(v:val, ''{\zs.*\ze}'')')
        let self.db_files = []
        for l:file in l:files
            if filereadable(l:file)
                let self.db_files += [l:file]
            elseif filereadable(expand(l:file))
                let self.db_files += [expand(l:file)]
            el
                let l:cand = vimtex#kpsewhich#run(l:file)
                if len(l:cand) == 1
                    let self.db_files += [l:cand[0]]
                en
            en
        endfor
    en

    return self.db_files
endf


fun! s:qf.get_filename(name) abort
    if !filereadable(a:name)
        for l:root in [self.root, b:vimtex.root]
            let l:candidate = fnamemodify(simplify(l:root . '/' . a:name), ':.')
            if filereadable(l:candidate)
                return l:candidate
            en
        endfor
    en

    return a:name
endf


fun! s:qf.get_key_pos(key) abort
    for l:file in self.get_db_files()
        let l:lnum = self.get_key_lnum(a:key, l:file)
        if l:lnum > 0
            return [l:file, l:lnum]
        en
    endfor

    return []
endf


fun! s:qf.get_key_lnum(key, filename) abort
    if !filereadable(a:filename) | return 0 | endif

    let l:lines = readfile(a:filename)
    let l:lnums = range(len(l:lines))
    let l:annotated_lines = map(l:lnums, '[v:val, l:lines[v:val]]')
    let l:matches = filter(l:annotated_lines,
                \ {_, x -> x[1] =~# '^\s*@\w*{\s*\V' . a:key})

    return len(l:matches) > 0 ? l:matches[-1][0]+1 : 0
endf


fun! s:qf.get_entry_key(filename, lnum) abort
    for l:file in self.get_db_files()
        if fnamemodify(l:file, ':t') !=# a:filename | continue | endif

        let l:entry = get(filter(readfile(l:file, 0, a:lnum), 'v:val =~# ''^@'''), -1)
        if empty(l:entry) | continue | endif

        return matchstr(l:entry, '{\v\zs.{-}\ze(,|$)')
    endfor

    return ''
endf



"
" Parsers for the various warning types
"

let s:type_parse_error = {}
fun! s:type_parse_error.fix(ctx, entry) abort
    if a:entry.text =~# 'ERROR - BibTeX subsystem.*expected end of entry'
        let l:matches = matchlist(a:entry.text, '\v(\S*\.bib).*line (\d+)')
        let a:entry.filename = a:ctx.get_filename(fnamemodify(l:matches[1], ':t'))
        let a:entry.lnum = l:matches[2]

        " Use filename and line number to get entry name
        let l:key = a:ctx.get_entry_key(a:entry.filename, a:entry.lnum)
        if !empty(l:key)
            let a:entry.text = 'biblatex: Error parsing entry with key "' . l:key . '"'
        en
        return 1
    en
endf



let s:type_duplicate = {}
fun! s:type_duplicate.fix(ctx, entry) abort
    if a:entry.text =~# 'WARN - Duplicate entry'
        let l:matches = matchlist(a:entry.text , '\v: ''(\S*)'' in file ''(.{-})''')
        let l:key     = l:matches[1]
        let a:entry.filename = a:ctx.get_filename(l:matches[2])
        let a:entry.lnum = a:ctx.get_key_lnum(l:key, a:entry.filename)
        let a:entry.text = 'biblatex: Duplicate entry key "' . l:key . '"'
        return 1
    en
endf



let s:type_no_driver = {}
fun! s:type_no_driver.fix(ctx, entry) abort
    if a:entry.text =~# 'No driver for entry type'
        let l:key = matchstr(a:entry.text, 'entry type ''\v\zs.{-}\ze''')
        let a:entry.text = 'biblatex: Using fallback driver for ''' . l:key . ''''

        let l:pos = a:ctx.get_key_pos(l:key)
        if !empty(l:pos)
            let a:entry.filename = a:ctx.get_filename(l:pos[0])
            let a:entry.lnum = l:pos[1]
            if has_key(a:entry, 'bufnr')
                unlet a:entry.bufnr
            en
        en

        return 1
    en
endf



let s:type_not_found = {}
fun! s:type_not_found.fix(ctx, entry) abort
    if a:entry.text =~# 'The following entry could not be found'
        let l:key = split(a:entry.text, ' ')[-1]
        let a:entry.text = 'biblatex: Entry with key ''' . l:key . ''' not found'

        for [l:file, l:lnum, l:line] in vimtex#parser#tex(b:vimtex.tex)
            if l:line =~# g:vimtex#re#not_comment . '\\\S*\V' . l:key
                let a:entry.lnum = l:lnum
                let a:entry.filename = l:file
                unlet a:entry.bufnr
                break
            en
        endfor

        return 1
    en
endf



let s:type_encoding = {}
fun! s:type_encoding.fix(ctx, entry) abort
    if a:entry.text =~# 'The entry .* has characters which cannot'
        let l:key = matchstr(a:entry.text, 'The entry ''\v\zs.{-}\ze''')
        let a:entry.text = 'biblatex: Entry with key ''' . l:key . ''' has non-ascii characters'

        let l:pos = a:ctx.get_key_pos(l:key)
        if !empty(l:pos)
            let a:entry.filename = a:ctx.get_filename(l:pos[0])
            let a:entry.lnum = l:pos[1]
            if has_key(a:entry, 'bufnr')
                unlet a:entry.bufnr
            en
        en

        return 1
    en
endf


