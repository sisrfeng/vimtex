" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

" 前戏
    if exists('b:did_indent')
        finish
    en

    call vimtex#options#init()

    if !g:vimtex_indent_enabled | finish | endif

    let b:did_vimtex_indent = 1
    let b:did_indent = 1

    let s:cpo_save = &cpoptions
    set cpoptions&vim


setlocal autoindent
setlocal indentexpr=VimtexIndentExpr()
setlocal indentkeys=!^F,
                    \o,
                    \O,
                    \0(,
                    \0),
                    \],
                    \},
                    \\&,
                    \0=\\item,
                    \0=\\else,
                    \0=\\fi

" Add standard closing math delimiters to indentkeys
for s:delim in [
            \ 'rangle',
            \ 'rbrace',
            \ 'rvert',
            \ 'rVert',
            \ 'rfloor',
            \ 'rceil',
            \ 'urcorner']
    let &l:indentkeys .= ',0=\' . s:delim
endfor


fun! VimtexIndentExpr() abort " {{{1
    return VimtexIndent(v:lnum)
endf

"}}}
fun! VimtexIndent(lnum) abort " {{{1
    let s:sw = shiftwidth()

    let [l:prev_lnum, l:prev_line] = s:get_prev_lnum(prevnonblank(a:lnum - 1))
    if l:prev_lnum == 0 | return indent(a:lnum) | endif
    let l:line = s:clean_line(getline(a:lnum))

    " Check for verbatim modes
    if s:is_verbatim(l:line, a:lnum)
        return empty(l:line) ? indent(l:prev_lnum) : indent(a:lnum)
    en

    " Use previous indentation for comments
    if l:line =~# '^\s*%'
        return indent(a:lnum)
    en

    " Align on ampersands
    let l:ind = s:indent_amps.check(a:lnum, l:line, l:prev_lnum, l:prev_line)
    if s:indent_amps.finished | return l:ind | endif
    let l:prev_lnum = s:indent_amps.prev_lnum
    let l:prev_line = s:indent_amps.prev_line

    " Indent environments, delimiters, and conditionals
    let l:ind += s:indent_envs(l:line, l:prev_line)
    let l:ind += s:indent_items(l:line, a:lnum, l:prev_line, l:prev_lnum)
    let l:ind += s:indent_delims(l:line, a:lnum, l:prev_line, l:prev_lnum)
    let l:ind += s:indent_conditionals(l:line, a:lnum, l:prev_line, l:prev_lnum)

    " Indent tikz commands
    if g:vimtex_indent_tikz_commands
        let l:ind += s:indent_tikz(l:prev_lnum, l:prev_line)
    en

    return l:ind < 0 ? 0 : l:ind
endf

"}}}

fun! s:get_prev_lnum(lnum) abort " {{{1
    let l:lnum = a:lnum
    let l:line = getline(l:lnum)

    while l:lnum != 0 && (l:line =~# '^\s*%' || s:is_verbatim(l:line, l:lnum))
        let l:lnum = prevnonblank(l:lnum - 1)
        let l:line = getline(l:lnum)
    endwhile

    return [
                \ l:lnum,
                \ l:lnum > 0 ? s:clean_line(l:line) : '',
                \]
endf

" }}}1
fun! s:clean_line(line) abort " {{{1
    return substitute(a:line, '\s*\\\@<!%.*', '', '')
endf

" }}}1
fun! s:is_verbatim(line, lnum) abort " {{{1
    return a:line !~# s:verbatim_re_envdelim
                \ && vimtex#env#is_inside(s:verbatim_re_list)[0]
endf

    let s:verbatim_envs = ['lstlisting', 'verbatim', 'minted', 'markdown']
    let s:verbatim_re_list = '\%(' . join(s:verbatim_envs, '\|') . '\)'
    let s:verbatim_re_envdelim = '\v\\%(begin|end)\{%('
                \ . join(s:verbatim_envs, '|') . ')'

" }}}1

let s:indent_amps = {}
fun! s:indent_amps.check(lnum, cline, plnum, pline) abort dict " {{{1
    let self.finished = 0
    let self.amp_ind = -1
    let self.init_ind = -1
    let self.prev_lnum = a:plnum
    let self.prev_line = a:pline
    let self.prev_ind = a:plnum > 0 ? indent(a:plnum) : 0
    if !g:vimtex_indent_on_ampersands | return self.prev_ind | endif

    if a:cline =~# s:re_align
                \ || a:cline =~# s:re_amp
                \ || a:cline =~# '^\v\s*\\%(end|])'
        call self.parse_context(a:lnum, a:cline)
    en

    if a:cline =~# s:re_align
        let self.finished = 1
        let l:ind_diff =
                    \   strdisplaywidth(strpart(a:cline, 0, match(a:cline, s:re_amp)))
                    \ - strdisplaywidth(strpart(a:cline, 0, match(a:cline, '\S')))
        return self.amp_ind - l:ind_diff
    en

    if self.amp_ind >= 0
                \ && (a:cline =~# '^\v\s*\\%(end|])' || a:cline =~# s:re_amp)
        let self.prev_lnum = self.init_lnum
        let self.prev_line = self.init_line
        return self.init_ind
    en

    return self.prev_ind
endf

    let s:re_amp = g:vimtex#re#not_bslash . '\&'
    let s:re_align = '^[ \t\\]*' . s:re_amp
" }}}1
fun! s:indent_amps.parse_context(lnum, line) abort dict " {{{1
    let l:depth = 1
    let l:lnum = prevnonblank(a:lnum - 1)

    while l:lnum >= 1
        let l:line = getline(l:lnum)

        if l:line =~# s:re_depth_end
            let l:depth += 1
        en

        if l:line =~# s:re_depth_beg
            let l:depth -= 1
            if l:depth == 0
                let self.init_lnum = l:lnum
                let self.init_line = l:line
                let self.init_ind = indent(l:lnum)
                break
            en
        en

        if l:depth == 1 && l:line =~# s:re_amp
            if self.amp_ind < 0
                let self.amp_ind = strdisplaywidth(
                            \ strpart(l:line, 0, match(l:line, s:re_amp)))
            en
            if l:line !~# s:re_align
                let self.init_lnum = l:lnum
                let self.init_line = l:line
                let self.init_ind = indent(l:lnum)
                break
            en
        en

        let l:lnum = prevnonblank(l:lnum - 1)
    endwhile
endf

let s:re_depth_beg = g:vimtex#re#not_bslash . '\\%(begin\s*\{|[|\w+\{\s*$)'
let s:re_depth_end = g:vimtex#re#not_bslash . '\\end\s*\{\w+\*?}|^\s*%(}|\\])'

" }}}1

fun! s:indent_envs(line, prev_line) abort " {{{1
    let l:ind = 0

    " First for general environments
    let l:ind += s:sw*(
                \    a:prev_line =~# s:envs_begin
                \ && a:prev_line !~# s:envs_end
                \ && a:prev_line !~# s:envs_ignored)
    let l:xx = l:ind
    let l:ind -= s:sw*(
                \    a:line !~# s:envs_begin
                \ && a:line =~# s:envs_end
                \ && a:line !~# s:envs_ignored)

    return l:ind
endf

let s:envs_begin = '\\begin{.*}\|\\\@<!\\\['
let s:envs_end = '\\end{.*}\|\\\]'
let s:envs_ignored = '\v<%(' . join(g:vimtex_indent_ignored_envs, '|') . ')>'

" }}}1
fun! s:indent_items(line, lnum, prev_line, prev_lnum) abort " {{{1
    if a:prev_line =~# s:envs_item && a:line !~# s:envs_enditem
        return s:sw
    elseif a:line =~# s:envs_endlist && a:prev_line !~# s:envs_begitem
        return -s:sw
    elseif a:line =~# s:envs_item && a:prev_line !~# s:envs_item
        let l:prev_lnum = a:prev_lnum
        let l:prev_line = a:prev_line
        while l:prev_lnum >= 1
            if l:prev_line =~# s:envs_begitem
                return -s:sw*(l:prev_line =~# s:envs_item)
            en
            let l:prev_lnum = prevnonblank(l:prev_lnum - 1)
            let l:prev_line = getline(l:prev_lnum)
        endwhile
    en

    return 0
endf

let s:envs_lists = join(g:vimtex_indent_lists, '\|')
let s:envs_item = '^\s*\\item\>'
let s:envs_beglist = '\\begin{\%(' . s:envs_lists . '\)'
let s:envs_endlist =   '\\end{\%(' . s:envs_lists . '\)'
let s:envs_begitem = s:envs_item . '\|' . s:envs_beglist
let s:envs_enditem = s:envs_item . '\|' . s:envs_endlist

" }}}1
fun! s:indent_delims(line, lnum, prev_line, prev_lnum) abort " {{{1
    if s:re_delim_trivial | return 0 | endif

    if s:re_opt.close_indented
        return s:sw*(vimtex#util#count(a:prev_line, s:re_open)
                    \ - vimtex#util#count(a:prev_line, s:re_close))
    el
        return s:sw*(vimtex#util#count_open(a:prev_line, s:re_open, s:re_close)
                    \      - vimtex#util#count_close(a:line, s:re_open, s:re_close))
    en
endf

let s:re_opt = extend({
            \ 'open' : ['{'],
            \ 'close' : ['}'],
            \ 'close_indented' : 0,
            \ 'include_modified_math' : 1,
            \}, g:vimtex_indent_delims)
let s:re_open = join(s:re_opt.open, '\|')
let s:re_close = join(s:re_opt.close, '\|')
if s:re_opt.include_modified_math
    let s:re_open .= (empty(s:re_open) ? '' : '\|') . g:vimtex#delim#re.delim_mod_math.open
    let s:re_close .= (empty(s:re_close) ? '' : '\|') . g:vimtex#delim#re.delim_mod_math.close
en
let s:re_delim_trivial = empty(s:re_open) || empty(s:re_close)

" }}}1
fun! s:indent_conditionals(line, lnum, prev_line, prev_lnum) abort " {{{1
    if !exists('s:re_cond')
        let s:re_cond = g:vimtex_indent_conditionals
    en

    if empty(s:re_cond) | return 0 | endif

    if get(s:, 'conditional_opened')
        if a:line =~# s:re_cond.close
            silent! unlet s:conditional_opened
            return a:prev_line =~# s:re_cond.open ? 0 : -s:sw
        elseif a:line =~# s:re_cond.else
            return -s:sw
        elseif a:prev_line =~# s:re_cond.else
            return s:sw
        elseif a:prev_line =~# s:re_cond.open
            return s:sw
        en
    en

    if a:line =~# s:re_cond.open
                \ && a:line !~# s:re_cond.close
        let s:conditional_opened = 1
    en

    return 0
endf

" }}}1
fun! s:indent_tikz(lnum, prev) abort " {{{1
    if !has_key(b:vimtex.packages, 'tikz') | return 0 | endif

    let l:env_pos = vimtex#env#is_inside('tikzpicture')
    if l:env_pos[0] > 0 && l:env_pos[0] < a:lnum
        let l:prev_starts = a:prev =~# s:tikz_commands
        let l:prev_stops  = a:prev =~# ';\s*$'

        " Increase indent on tikz command start
        if l:prev_starts && ! l:prev_stops
            return s:sw
        en

        " Decrease indent on tikz command end, i.e. on semicolon
        if ! l:prev_starts && l:prev_stops
            let l:context = join(getline(l:env_pos[0], a:lnum-1), '')
            return -s:sw*(l:context =~# s:tikz_commands)
        en
    en

    return 0
endf

let s:tikz_commands = '\v\\%(' . join([
                \ 'draw',
                \ 'fill',
                \ 'path',
                \ 'node',
                \ 'coordinate',
                \ 'clip',
                \ 'add%(legendentry|plot)',
            \ ], '|') . ')'

" }}}1

let &cpoptions = s:cpo_save
unlet s:cpo_save
