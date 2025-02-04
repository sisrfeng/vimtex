if exists('current_compiler') | finish | endif
let current_compiler = 'textidote'

let s:cpo_save = &cpo
set cpo&vim

fun! s:get_textidote_lang(lang)
    " Match specific language(s)
    if a:lang ==# 'en_gb'  | return 'en_UK'  | en

    " Convert normal lang strings to textidote format
    let l:matched = matchlist(a:lang, '^\v(\a\a)%(_(\a\a))?')
    let l:string = l:matched[1]
    if !empty(l:matched[2])  | let l:string .= '_' . toupper(l:matched[2])  | en
    return l:string
endf


let s:cfg = g:vimtex_grammar_textidote

if empty(s:cfg.jar)
|| !filereadable(fnamemodify(s:cfg.jar, ':p'))
    call vimtex#log#error([
                \ 'g:vimtex_grammar_textidote is not properly configured!',
                \ 'Please see ":help vimtex-grammar-textidote" for more details.'
                \])
    finish
en


"\ let s:language = vimtex#ui#choose(
"\   \ split(&spelllang, ','),
"\   \ {
"\     \ 'prompt': 'Multiple spelllang languages detected, please select one:',
"\     \ 'abort': v:false,
"\    \ },
"\  \ )

let s:language = 'en-us'

let &l:makeprg = 'java -jar '
            \ . shellescape(fnamemodify(s:cfg.jar, ':p'))
            \ . (has_key(s:cfg, 'args')
                \ ? ' ' . s:cfg.args
                \ : '')
            \ . ' --no-color --output singleline --check '
            \ . s:get_textidote_lang(s:language) . ' %:S'

            "\ 扔掉--output singleline会导致在vim里无法使用textidote

silent CompilerSet makeprg

setl  errorformat=
    "\ setl  errorformat+=(L%lC%c-L%\\d%\\+C%\\d%\\+):\ %m
                       "\ 没了%f导致报错, 这不是直接显示的, 而是传给qf
    setl  errorformat+=%f(L%lC%c-L%\\d%\\+C%\\d%\\+):\ %m
                             "\ ¿(L行号C列号-L\d\+C\d\+): ¿ 具体错误
    setl  errorformat+=%-G%.%#
                       "\ %-G 忽略当前message
                          "\ ¿%.%#¿表示regular expression ¿.*¿
    silent CompilerSet errorformat

let &cpo = s:cpo_save
unlet s:cpo_save
