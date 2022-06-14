scriptencoding utf-8

fun! vimtex#syntax#p#amsmath#load(cfg) abort " {{{1
    call vimtex#syntax#core#new_region_math('align')
    call vimtex#syntax#core#new_region_math('alignat')
    call vimtex#syntax#core#new_region_math('flalign')
    call vimtex#syntax#core#new_region_math('gather')
    call vimtex#syntax#core#new_region_math('mathpar')
    call vimtex#syntax#core#new_region_math('multline')
    call vimtex#syntax#core#new_region_math('xalignat')
    call vimtex#syntax#core#new_region_math('xxalignat', {'starred': 0})

    syn  match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathArrayArg skipwhite skipnl "\\begin{subarray}"
    syn  match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathArrayArg skipwhite skipnl "\\begin{x\?alignat\*\?}"
    syn  match texMathCmdEnv contained contains=texCmdMathEnv nextgroup=texMathArrayArg skipwhite skipnl "\\begin{xxalignat}"
    syn  match texMathCmdEnv contained contains=texCmdMathEnv                                            "\\end{subarray}"
    syn  match texMathCmdEnv contained contains=texCmdMathEnv                                            "\\end{x\?alignat\*\?}"
    syn  match texMathCmdEnv contained contains=texCmdMathEnv                                            "\\end{xxalignat}"

    " \numberwithin
    syn  match texCmdNumberWithin "\\numberwithin\>"
                \ nextgroup=texNumberWithinArg1 skipwhite skipnl
    call vimtex#syntax#core#new_arg('texNumberWithinArg1', {
                \ 'next': 'texNumberWithinArg2',
                \ 'contains': 'TOP,@Spell'
                \})
    call vimtex#syntax#core#new_arg('texNumberWithinArg2', {
                \ 'contains': 'TOP,@Spell'
                \})

    " \subjclass
    syn  match texCmdSubjClass "\\subjclass\>"
                \ nextgroup=texSubjClassOpt,texSubjClassArg skipwhite skipnl
    call vimtex#syntax#core#new_opt('texSubjClassOpt', {
                \ 'next': 'texSubjClassArg',
                \ 'contains': 'TOP,@Spell'
                \})
    call vimtex#syntax#core#new_arg('texSubjClassArg', {
                \ 'contains': 'TOP,@Spell'
                \})

    " DeclareMathOperator
    syn  match texCmdDeclmathoper nextgroup=texDeclmathoperArgName skipwhite skipnl "\\DeclareMathOperator\>\*\?"
    call vimtex#syntax#core#new_arg('texDeclmathoperArgName', {
                \ 'next': 'texDeclmathoperArgBody',
                \ 'contains': ''
                \})
    call vimtex#syntax#core#new_arg('texDeclmathoperArgBody', {'contains': 'TOP,@Spell'})

    " \operatorname
    syn  match texCmdOpname nextgroup=texOpnameArg skipwhite skipnl "\\operatorname\>"
    call vimtex#syntax#core#new_arg('texOpnameArg', {
                \ 'contains': 'TOP,@Spell'
                \})

    " \tag{label} or \tag*{label}
    syn  match texMathCmd "\\tag\>\*\?" contained nextgroup=texMathTagArg
    call vimtex#syntax#core#new_arg('texMathTagArg', {'contains': 'TOP,@Spell'})

    " Add conceal rules
    if g:vimtex_syntax_conceal.math_delimiters
        " Conceal the command and delims of "\operatorname{ ... }"
        syn  region texMathConcealedArg contained matchgroup=texMathCmd
                    \ start="\\operatorname\*\?\s*{" end="}"
                    \ concealends
        syn  cluster texClusterMath add=texMathConcealedArg

        " Conceal "\eqref{ ... }" as "( ... )"
        syn  match texCmdRefEq nextgroup=texRefEqConcealedArg
                    \ conceal skipwhite skipnl "\\eqref\>"
        call vimtex#syntax#core#new_arg('texRefEqConcealedArg', {
                    \ 'contains': 'texComment,@NoSpell,texRefEqConcealedDelim',
                    \ 'opts': 'keepend contained',
                    \ 'matchgroup': '',
                    \})
        syn  match texRefEqConcealedDelim contained "{" cchar=( conceal
        syn  match texRefEqConcealedDelim contained "}" cchar=) conceal

        " Amsmath [lr][vV]ert
        if &encoding ==# 'utf-8'
            syn  match texMathDelim contained conceal cchar=| "\\\%([bB]igg\?l\|left\)\\lvert"
            syn  match texMathDelim contained conceal cchar=| "\\\%([bB]igg\?r\|right\)\\rvert"
            syn  match texMathDelim contained conceal cchar=‖ "\\\%([bB]igg\?l\|left\)\\lVert"
            syn  match texMathDelim contained conceal cchar=‖ "\\\%([bB]igg\?r\|right\)\\rVert"
        en
    en

    hi def link texCmdDeclmathoper     texCmdNew
    hi def link texCmdNumberWithin     texCmd
    hi def link texCmdOpName           texCmd
    hi def link texCmdSubjClass        texCmd
    hi def link texCmdRefEq            texCmdRef
    hi def link texRefEqConcealedArg   texRefArg
    hi def link texRefEqConcealedDelim texDelim
    hi def link texDeclmathoperArgName texArgNew
    hi def link texDeclmathoperArgBody texMathZone
    hi def link texMathConcealedArg    texMathTextArg
    hi def link texNumberWithinArg1    texArg
    hi def link texNumberWithinArg2    texArg
    hi def link texOpnameArg           texMathZone
    hi def link texSubjClassArg        texArg
    hi def link texSubjClassOpt        texOpt
endf

" }}}1
