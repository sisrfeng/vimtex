if exists('current_compiler') | finish | endif
let current_compiler = 'vlty'

let s:cpo_save = &cpo
set cpo&vim

let s:python = executable('python3') ? 'python3' : 'python'
let s:vlty = g:vimtex_grammar_vlty

fun! s:installation_error(msg) abort
    call vimtex#log#error(
                \ ['vlty compiler - ' . a:msg,
                \  'Please see ":help vimtex-grammar-vlty" for more details.'])
endf


fun! s:check_python(code) abort
    call vimtex#jobs#run(printf('%s -c "%s"', s:python, a:code))
    return v:shell_error != 0
endf



if !executable(s:python)
    call s:installation_error('requires Python')
    finish
en

if s:check_python('import sys; assert sys.version_info >= (3, 6)')
    call s:installation_error('requires at least Python version 3.6')
    finish
en

if s:check_python('import yalafi')
    call s:installation_error('requires the Python module YaLafi')
    finish
en

if !exists('s:vlty.lt_command')
    let s:vlty.lt_command = ''
en

let s:vlty_lt_command = ''
if s:vlty.server !=# 'lt'
    if !executable('java')
        call s:installation_error('requires Java')
        finish
    en

    if !empty(s:vlty.lt_command)
        if !executable(s:vlty.lt_command)
            call s:installation_error('lt_command is not executable')
            finish
        en

        let s:vlty_lt_command = s:vlty.lt_command
    el
        let s:jarfile = fnamemodify(
                    \ s:vlty.lt_directory . '/languagetool-commandline.jar', ':p')

        if !filereadable(s:jarfile)
            call s:installation_error('lt_directory path not valid')
            finish
        en

        let s:vlty_lt_command = 'java -jar ' . fnamemodify(s:jarfile, ':S')
    en
en

let s:vimtex = get(
    \ b:,
    \ 'vimtex',
    \ {'documentclass': '', 'packages': {}},
   \ )

let s:documentclass = s:vimtex.documentclass
let s:packages = join(keys(s:vimtex.packages), ',')

" Guess language if it is not defined
if !exists('s:vlty.language')
    let s:vlty.language = vimtex#ui#choose(split(&spelllang, ','), {
                \ 'prompt': 'Multiple spelllang languages detected, please select one:',
                \ 'abort': v:false,
                \})
en

if empty(s:vlty.language)
    echohl WarningMsg
    echomsg 'Please set g:vimtex_grammar_vlty.language to enable more accurate'
    echomsg 'checks by LanguageTool. Reverting to --autoDetect.'
    echohl None
    let s:vlty_language = ' --autoDetect'
el
    let s:vlty.language = substitute(s:vlty.language, '_', '-', '')
    let s:vlty_language = ' --language ' . s:vlty.language
    if !exists('s:list')
        let s:list = vimtex#jobs#capture(s:vlty_lt_command . ' --list NOFILE')
        call map(s:list, {_, x -> split(x)[0]})
    en
    if !empty(s:list)
        if match(s:list, '\c^' . s:vlty.language . '$') == -1
            echohl WarningMsg
            echomsg "Language '" . s:vlty.language . "'"
                        \ . " not listed in output of the command "
                        \ . "'" . s:vlty_lt_command . " --list NOFILE'! "
                        \ . "Please check its output!"
            if match(s:vlty.language, '-') != -1
                let s:vlty.language = matchstr(s:vlty.language, '\v^[^-]+')
                echomsg "Trying '" . s:vlty.language . "' instead."
            el
                echomsg "Trying '" . s:vlty.language . "' anyway."
            en
            echohl None
        en
    en
en

let &l:makeprg =  s:python . ' -m yalafi.shell'
            \ . (!empty(s:vlty.lt_command)
             \    ? ' --lt-command '   . s:vlty.lt_command
             \    : ' --lt-directory ' . s:vlty.lt_directory
              \ )
            \ . (s:vlty.server ==# 'no'
              \    ? ''
              \    : ' --server ' . s:vlty.server
              \ )
            \ . ' --encoding '   . (s:vlty.encoding ==# 'auto'
                              \    ? (empty(&l:fileencoding) ? &l:encoding : &l:fileencoding)
                              \    : s:vlty.encoding
                              \ )
            \ . s:vlty_language
            \ . ' --disable "' . s:vlty.lt_disable . '"'
            \ . ' --enable "'  . s:vlty.lt_enable . '"'
            \
            \ . ' --disablecategories "' . s:vlty.lt_disablecategories . '"'
            \ . ' --enablecategories "'  . s:vlty.lt_enablecategories . '"'
            \
            \ . ' --documentclass "' . s:documentclass . '"'
            \ . ' --packages "'      . s:packages . '"'
            \ . ' ' . s:vlty.shell_options
            \ . ' %:S'

    "\ - By default, the vlty compiler passes names of all ¿necessary¿ LaTeX packages  to YaLafi,
      "\ which may result in annoying warnings.
        "\ In multi-file projects,
            "\ these are suppressed by `--packages "*"` (存在s:vlty.shell_options里)  that simply
            "\ loads all packages known to the filter.


"\ 可以不?
"\ let g:vimtex_lt_YaLafi_cmd = &l:makeprg
" nno <Leader>rv exe 'AsyncRun lmake ' . g:vimtex_vimtex_lt_YaLafi_cmd


silent CompilerSet makeprg
"\ 有这种用法:
       "\ CompilerSet makeprg=nmake


"\ 在zsh里输出为:
    "\ 1.) Line 15, column 10, Rule ID: UPPERCASE_SENTENCE_START
    "\ Message: This sentence does not start with an uppercase letter.
    "\ Suggestion: Dvipdfmx
    "\        dvipdfmx:config z 0                         refs     ...
    "\        ^^^^^^^^

    "\
    "\ === PasS.tex ===
    "\ 2.) Line 15, column 10, Rule ID: MORFOLOGIK_RULE_EN_US
    "\ Message: Possible spelling mistake found.
    "\ Suggestion:
    "\        dvipdfmx:config z 0                         refs     ...
    "\        ^^^^^^^^


let &l:errorformat = '%I=== %f ===,%C%*\d.) Line %l\, column %v\, Rule ID:%.%#'

let &l:errorformat .= s:vlty.show_suggestions
                \ ? ',%CMessage: %m,%ZSuggestion: %m'
                \ : ',%ZMessage: %m'

                "\ \ ? ',%CMessage: %m,%ZSuggestion: 建议%m'

" For compatibility with vim-dispatch we need duplicated '%-G%.%#'.
    " See issues #199 of vim-dispatch and #1854 of VimTeX.
    let &l:errorformat .= ',%-G%.%#,%-G%.%#'

silent CompilerSet errorformat

let &cpo = s:cpo_save
unlet s:cpo_save
