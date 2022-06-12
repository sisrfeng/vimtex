" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

" This script has a lot of unicode characters (for conceals)
scriptencoding utf-8

fun! vimtex#syntax#core#init() abort "
    syn spell toplevel

    syn sync maxlines=500
    syn sync minlines=50
    syn iskeyword 48-57,a-z,A-Z,192-255

    " Define main syntax clusters
        syn cluster texClusterOpt contains=
                    \texCmd,
                    \texComment,
                    \texGroup,
                    \texLength,
                    \texOpt,
                    \texOptEqual,
                    \texOptSep,
                    \@NoSpell

        syn cluster texClusterMath contains=
                    \texCmdEnvM,
                    \texCmdFootnote,
                    \texCmdGreek,
                    \texCmdMinipage,
                    \texCmdParbox,
                    \texCmdRef,
                    \texCmdSize,
                    \texCmdStyle,
                    \texCmdTodo,
                    \texCmdVerb,
                    \texComment,
                    \texGroupError,
                    \texMathCmd,
                    \texMathCmdEnv,
                    \texMathCmdStyle,
                    \texMathCmdStyleBold,
                    \texMathCmdStyleItal,
                    \texMathCmdText,
                    \texMathDelim,
                    \texMathDelimMod,
                    \texMathGroup,
                    \texMathOper,
                    \texMathSuperSub,
                    \texMathSymbol,
                    \texSpecialChar,
                    \texTabularChar,
                    \@NoSpell


    " TeX symbols and special characters
        syn match texLigature     "--"
        syn match texLigature     "---"
        syn match texLigature     "\v%(``|''|,,)"
        syn match texTabularChar  "&"
        syn match texTabularChar  "\\\\"

                                    "  \$ \& \% \# \{ \} \_
        syn match texSpecialChar "\\[$&%#{}_]"           contains=texPartConcealed
        syn match texSpecialChar "\\[SP@]\ze[^a-zA-Z@]"  conceal
                                    " \S  花体S,
                                        " \P 旗帜
        syn match texSpecialChar "\\[,;:!]"
        syn match texSpecialChar "\v\^\^%(\S|[0-9a-f]{2})"
                                        " ^^A 在dtx里表示注释

        "\ 我的bye_tex搞定了
        " 不行:
            "\ syn match texDelim "{"  conceal contained containedin=ALL
            "\ syn match texDelim "}"  conceal contained containedin=ALL
            " syn match texBrace "{"  conceal contained containedin=ALL
            " syn match texBrace "}"  conceal contained containedin=ALL
    "
    " Commands: general
        " Unspecified TeX groups
        " Note: This is necessary to keep track of all nested ¿braces¿
        call vimtex#syntax#core#new_arg('texGroup', {'opts': ''})

        " Flag mismatching  ending brace delimiter
        syn match texGroupError "}"

        " Add generic option elements contained in common option groups
        syn match texOptEqual contained "="
        syn match texOptSep contained ",\s*"

        " TeX Lengths (matched in options and some arguments)
        syn match texLength contained "\<\d\+\([.,]\d\+\)\?\s*\(true\)\?\s*\(bp\|cc\|cm\|dd\|em\|ex\|in\|mm\|pc\|pt\|sp\)\>"

        " Match general commands first
            syn match texCmd   "\v\\[a-zA-Z@]+"   nextgroup=texOpt,texArg  skipwhite skipnl
            call vimtex#syntax#core#new_opt('texOpt', {'next': 'texArg'})
            call vimtex#syntax#core#new_arg('texArg', {'next': 'texArg',     'opts': 'contained transparent'})

        " Define separate "generic" commands inside math regions
            " Note: Defined here because order matters!
            syn match texMathCmd  "\v\\\a+"       nextgroup=texMathArg  contained  skipwhite skipnl
                                                                   " 没有Opt?
            call vimtex#syntax#core#new_arg('texMathArg', {'contains': '@texClusterMath'})

        " Commands: core set

        " Accents and ligatures
        syn match texCmdAccent "\\[bcdvuH]$"
        syn match texCmdAccent "\\[bcdvuH]\ze[^a-zA-Z@]"
        syn match texCmdAccent #\\[=^.~"`']#
        syn match texCmdAccent #\\['=t'.c^ud"vb~Hr]{\a}#
        syn match texCmdLigature "\v\\%([ijolL]|ae|oe|ss|AA|AE|OE)$"
        syn match texCmdLigature "\v\\%([ijolL]|ae|oe|ss|AA|AE|OE)\ze[^a-zA-Z@]"

        " Spacecodes (TeX'isms)
        " * See e.g. https://en.wikibooks.org/wiki/TeX/catcode
          " change the ¿cat¿egory ¿code¿ of a character
            " * \mathcode`\^^@ = "2201
            " * \delcode`\( = "028300
            " * \sfcode`\) = 0
            " * \uccode`X = `X
            " * \lccode`x = `x
        syn match texCmdSpaceCode "\v\\%(math|cat|del|lc|sf|uc)code`"me=e-1
                                \ nextgroup=texCmdSpaceCodeChar
        syn match texCmdSpaceCodeChar "\v`\\?.%(\^.)?\?%(\d|\"\x{1,6}|`.)" contained

        " Todo commands
        syn match texCmdTodo '\\todo\w*'

        " \author
        syn match texCmdAuthor nextgroup=texAuthorOpt,texAuthorArg skipwhite skipnl "\\author\>"
        call vimtex#syntax#core#new_opt('texAuthorOpt', {'next': 'texAuthorArg'})
        call vimtex#syntax#core#new_arg('texAuthorArg', {'contains': 'TOP,@Spell'})

        " \title
        syn match texCmdTitle nextgroup=texTitleArg skipwhite skipnl "\\title\>"
        call vimtex#syntax#core#new_arg('texTitleArg')

        " \footnote
        syn match texCmdFootnote nextgroup=texFootnoteArg skipwhite skipnl "\\footnote\>"
        call vimtex#syntax#core#new_arg('texFootnoteArg')

        " \if \else \fi
        syn match texCmdConditional nextgroup=texConditionalArg skipwhite skipnl "\\\(if[a-zA-Z@]\+\|fi\|else\)\>"
        call vimtex#syntax#core#new_arg('texConditionalArg')

        " \@ifnextchar
        syn match texCmdConditionalINC "\\\w*@ifnextchar\>"
                    \ nextgroup=texConditionalINCChar skipwhite skipnl
        syn match texConditionalINCChar "\S" contained

        " Various commands that take a file argument (or similar)
        syn match texCmdInput   nextgroup=texFileArg              skipwhite skipnl "\\input\>"
        syn match texCmdInput   nextgroup=texFileArg              skipwhite skipnl "\\include\>"
        syn match texCmdInput   nextgroup=texFilesArg             skipwhite skipnl "\\includeonly\>"
        syn match texCmdInput   nextgroup=texFileOpt,texFileArg   skipwhite skipnl "\\includegraphics\>"
        syn match texCmdBib     nextgroup=texFilesArg             skipwhite skipnl "\\bibliography\>"
        syn match texCmdBib     nextgroup=texFileArg              skipwhite skipnl "\\bibliographystyle\>"
        syn match texCmdClass   nextgroup=texFileOpt,texFileArg   skipwhite skipnl "\\document\%(class\|style\)\>"
        syn match texCmdPackage nextgroup=texFilesOpt,texFilesArg skipwhite skipnl "\\usepackage\>"
        syn match texCmdPackage nextgroup=texFilesOpt,texFilesArg skipwhite skipnl "\\RequirePackage\>"
        syn match texCmdPackage nextgroup=texFilesOpt,texFilesArg skipwhite skipnl "\\ProvidesPackage\>"
        call vimtex#syntax#core#new_arg('texFileArg', {'contains': '@NoSpell,texCmd,texComment'})
        call vimtex#syntax#core#new_arg('texFilesArg', {'contains': '@NoSpell,texCmd,texComment,texOptSep'})
        call vimtex#syntax#core#new_opt('texFileOpt', {'next': 'texFileArg'})
        call vimtex#syntax#core#new_opt('texFilesOpt', {'next': 'texFilesArg'})

        " LaTeX 2.09 type styles
            syn match texCmdStyle "\\rm\>"        conceal
            syn match texCmdStyle "\\em\>"        conceal
            syn match texCmdStyle "\\bf\>"        conceal
            syn match texCmdStyle "\\it\>"        conceal
            syn match texCmdStyle "\\sl\>"        conceal
            syn match texCmdStyle "\\sf\>"        conceal
            syn match texCmdStyle "\\sc\>"        conceal
            syn match texCmdStyle "\\tt\>"        conceal

        " LaTeX2E type styles
            syn match texCmdStyle "\\textbf\>"            conceal
            syn match texCmdStyle "\\textit\>"            conceal
            syn match texCmdStyle "\\textmd\>"            conceal
            syn match texCmdStyle "\\textrm\>"            conceal
            syn match texCmdStyle "\\texts[cfl]\>"        conceal
            syn match texCmdStyle "\\texttt\>"            conceal
            syn match texCmdStyle "\\textup\>"            conceal
            syn match texCmdStyle "\\textnormal\>"        conceal
            syn match texCmdStyle "\\emph\>"              conceal

            syn match texCmdStyle "\\rmfamily\>"          conceal
            syn match texCmdStyle "\\sffamily\>"          conceal
            syn match texCmdStyle "\\ttfamily\>"          conceal

            syn match texCmdStyle "\\itshape\>"           conceal
            syn match texCmdStyle "\\scshape\>"           conceal
            syn match texCmdStyle "\\slshape\>"           conceal
            syn match texCmdStyle "\\upshape\>"           conceal

            syn match texCmdStyle "\\bfseries\>"          conceal
            syn match texCmdStyle "\\mdseries\>"          conceal

        " Bold and italic commands
        call s:match_bold_italic()

        " Type sizes
            syn match texCmdSize "\\tiny\>"               conceal
            syn match texCmdSize "\\scriptsize\>"         conceal
            syn match texCmdSize "\\footnotesize\>"       conceal
            syn match texCmdSize "\\small\>"              conceal
            syn match texCmdSize "\\normalsize\>"         conceal
            syn match texCmdSize "\\large\>"              conceal
            syn match texCmdSize "\\Large\>"              conceal
            syn match texCmdSize "\\LARGE\>"              conceal
            syn match texCmdSize "\\huge\>"               conceal
            syn match texCmdSize "\\Huge\>"               conceal

        " \newcommand
        syn match texCmdNewcmd "\\\%(re\)\?newcommand\>\*\?"
                    \ nextgroup=texNewcmdArgName skipwhite skipnl
        syn match texNewcmdArgName "\\[a-zA-Z@]\+"
                    \ nextgroup=texNewcmdOpt,texNewcmdArgBody skipwhite skipnl
                    \ contained
        call vimtex#syntax#core#new_arg('texNewcmdArgName', {
                    \ 'next': 'texNewcmdOpt,texNewcmdArgBody',
                    \ 'contains': ''
                    \})
        call vimtex#syntax#core#new_opt('texNewcmdOpt', {
                    \ 'next': 'texNewcmdOpt,texNewcmdArgBody',
                    \ 'opts': 'oneline',
                    \})
        call vimtex#syntax#core#new_arg('texNewcmdArgBody')
        syn match texNewcmdParm contained "#\+\d" containedin=texNewcmdArgBody

        " \newenvironment
        syn match texCmdNewenv nextgroup=texNewenvArgName skipwhite skipnl "\\\%(re\)\?newenvironment\>"
        call vimtex#syntax#core#new_arg('texNewenvArgName', {'next': 'texNewenvArgBegin,texNewenvOpt'})
        call vimtex#syntax#core#new_opt('texNewenvOpt', {
                    \ 'next': 'texNewenvArgBegin,texNewenvOpt',
                    \ 'opts': 'oneline'
                    \})
        call vimtex#syntax#core#new_arg('texNewenvArgBegin', {'next': 'texNewenvArgEnd'})
        call vimtex#syntax#core#new_arg('texNewenvArgEnd')
        syn match texNewenvParm contained "#\+\d" containedin=texNewenvArgBegin,texNewenvArgEnd

        " Definitions/Commands
        " E.g. \def \foo #1#2 {foo #1 bar #2 baz}
        syn match texCmdDef "\\def\>" nextgroup=texDefArgName skipwhite skipnl
        syn match texDefArgName contained nextgroup=texDefParmPre,texDefArgBody skipwhite skipnl "\\[a-zA-Z@]\+"
        syn match texDefArgName contained nextgroup=texDefParmPre,texDefArgBody skipwhite skipnl "\\[^a-zA-Z@]"
        syn match texDefParmPre contained nextgroup=texDefArgBody skipwhite skipnl "#[^{]*"
        syn match texDefParm contained "#\+\d" containedin=texDefParmPre,texDefArgBody
        call vimtex#syntax#core#new_arg('texDefArgBody')

        " \let
        syn match texCmdLet "\\let\>" nextgroup=texLetArgName skipwhite skipnl
        syn match texLetArgName  contained nextgroup=texLetArgBody,texLetArgEqual skipwhite skipnl "\\[a-zA-Z@]\+"
        syn match texLetArgName  contained nextgroup=texLetArgBody,texLetArgEqual skipwhite skipnl "\\[^a-zA-Z@]"
        " Note: define texLetArgEqual after texLetArgBody; order matters
        " E.g. in '\let\eq==' we want: 1st = is texLetArgEqual, 2nd = is texLetArgBody
        " Reversing lines results in:  1st = is texLetArgBody,  2nd = is unmatched
        syn match texLetArgBody  contained "\\[a-zA-Z@]\+\|\\[^a-zA-Z@]\|\S" contains=TOP,@Nospell
        syn match texLetArgEqual contained nextgroup=texLetArgBody skipwhite skipnl "="

        " Reference and cite commands
            syn match texCmdRef nextgroup=texRefArg           skipwhite skipnl   "\v\\nocite>"
            "\ syn match texCmdRef nextgroup=texRefArg           skipwhite skipnl   "\v\\label>"
            syn match texCmdRef nextgroup=texRefArg           skipwhite skipnl   "\v\\(page|eq)ref>"
            syn match texCmdRef nextgroup=texRefArg           skipwhite skipnl   "\v\\v?ref>"
            syn match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl   "\v\\cite>"
            syn match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl   "\v\\cite[tp]>\*?"
            call vimtex#syntax#core#new_opt('texRefOpt', {'next': 'texRefOpt,texRefArg'})
            call vimtex#syntax#core#new_arg('texRefArg', {'contains': 'texComment,@NoSpell'})

        " \bibitem[label]{marker}
        syn match texCmdBibitem "\\bibitem\>"
                    \ nextgroup=texBibitemOpt,texBibitemArg skipwhite skipnl
        call vimtex#syntax#core#new_opt('texBibitemOpt', {
                    \ 'next': 'texBibitemArg'
                    \})
        call vimtex#syntax#core#new_arg('texBibitemArg',
                    \ {'contains': 'texComment,@NoSpell'})

        " Sections and parts
            syn match texCmdPart "\\\(front\|main\|back\)matter\>"                          conceal
            syn match texCmdPart "\\part\>"                    nextgroup=texPartArgTitle    conceal
            syn match texCmdPart "\\chapter\>\*\?"             nextgroup=texPartArgTitle    conceal
            syn match texCmdPart "\v\\%(sub)*section>\*?"      nextgroup=texPartArgTitle    conceal
            syn match texCmdPart "\v\\%(sub)?paragraph>"       nextgroup=texPartArgTitle    conceal
            syn match texCmdPart "\v\\add%(part|chap|sec)>\*?" nextgroup=texPartArgTitle    conceal
            call vimtex#syntax#core#new_arg('texPartArgTitle')

        " Item elements in lists
        syn match texCmdItem "\\item\>"

        " \begin \end environments
        " syn match texCmdEnv "\v\\%(begin|end)>" nextgroup=texEnvArgName
        " syn match texCmdEnv "\v\\begin" contained conceal cchar=⇒    nextgroup=texEnvArgName
        syn match texCmdEnv "\v\\begin" contained conceal cchar=     nextgroup=texEnvArgName
        syn match texCmdEnv "\v\\end"   contained conceal cchar=     nextgroup=texEnvArgName

        call vimtex#syntax#core#new_arg('texEnvArgName', {
                    \ 'contains': 'texComment,@NoSpell',
                    \ 'next': 'texEnvOpt',
                    \})
        call vimtex#syntax#core#new_opt('texEnvOpt')

        " Commands: \begin{tabular}

        syn match texCmdTabular "\\begin{tabular}"
                    \ skipwhite skipnl
                    \ nextgroup=texTabularOpt,texTabularArg
                    \ contains=texCmdEnv
        call vimtex#syntax#core#new_opt('texTabularOpt', {
                    \ 'next': 'texTabularArg',
                    \ 'contains': 'texComment,@NoSpell',
                    \})
        call vimtex#syntax#core#new_arg('texTabularArg', {
                    \ 'contains': '@texClusterTabular'
                    \})

        syn match texTabularCol   "[lcr]" contained
        syn match texTabularCol   "p"     contained nextgroup=texTabularLength
        syn match texTabularAtSep "@"     contained nextgroup=texTabularLength
        syn cluster texClusterTabular contains=texTabular.*

        call vimtex#syntax#core#new_arg('texTabularLength', {
                    \ 'contains': 'texLength,texCmd'
                    \})

        " Commands: \begin{minipage}[position][height][inner-pos]{width}

        " Reference: http://latexref.xyz/minipage.html

        syn match texCmdMinipage "\\begin{minipage}"
                    \ skipwhite skipnl
                    \ nextgroup=texMinipageOptPos,texMinipageArgWidth
                    \ contains=texCmdEnv

        call vimtex#syntax#core#new_opt('texMinipageOptPos', {
                    \ 'next': 'texMinipageOptHeight,texMinipageArgWidth',
                    \ 'contains': 'texBoxOptPosVal,texComment',
                    \})
        call vimtex#syntax#core#new_opt('texMinipageOptHeight', {
                    \ 'next': 'texMinipageOptIPos,texMinipageArgWidth',
                    \ 'contains': 'texLength,texCmd,texComment',
                    \})
        call vimtex#syntax#core#new_opt('texMinipageOptIPos', {
                    \ 'next': 'texMinipageArgWidth',
                    \ 'contains': 'texBoxOptIPosVal,texComment',
                    \})
        call vimtex#syntax#core#new_arg('texMinipageArgWidth', {
                    \ 'contains': 'texLength,texCmd,texComment',
                    \})

        " These are also used inside \parbox options
        syn match texBoxOptPosVal "[bcmt]" contained
        syn match texBoxOptIPosVal "[bcst]" contained

        " Commands: \parbox[position][height][inner-pos]{width}{contents}

        " Reference: http://latexref.xyz/_005cparbox.html

        syn match texCmdParbox "\\parbox\>"
                    \ skipwhite skipnl
                    \ nextgroup=texParboxOptPos,texParboxArgWidth

        call vimtex#syntax#core#new_opt('texParboxOptPos', {
                    \ 'next': 'texParboxOptHeight,texParboxArgWidth',
                    \ 'contains': 'texBoxOptPosVal,texComment',
                    \})
        call vimtex#syntax#core#new_opt('texParboxOptHeight', {
                    \ 'next': 'texParboxOptIPos,texParboxArgWidth',
                    \ 'contains': 'texLength,texCmd,texComment',
                    \})
        call vimtex#syntax#core#new_opt('texParboxOptIPos', {
                    \ 'next': 'texParboxArgWidth',
                    \ 'contains': 'texBoxOptIPosVal,texComment',
                    \})
        call vimtex#syntax#core#new_arg('texParboxArgWidth', {
                    \ 'next': 'texParboxArgContent',
                    \ 'contains': 'texLength,texCmd,texComment',
                    \})
        call vimtex#syntax#core#new_arg('texParboxArgContent')
    "
    " Commands: Theorems
    " Reference: LaTeX 2e Unofficial reference guide, section 12.9
    "            https://texdoc.org/serve/latex2e/0
        " \newtheorem
        syn match texCmdNewthm "\\newtheorem\>"
                    \ nextgroup=texNewthmArgName skipwhite skipnl
        call vimtex#syntax#core#new_arg('texNewthmArgName', {
                    \ 'next': 'texNewthmOptCounter,texNewthmArgPrinted',
                    \ 'contains': 'TOP,@Spell'
                    \})
        call vimtex#syntax#core#new_opt('texNewthmOptCounter',
                    \ {'next': 'texNewthmArgPrinted'}
                    \)
        call vimtex#syntax#core#new_arg('texNewthmArgPrinted',
                    \ {'next': 'texNewthmOptNumberby'}
                    \)
        call vimtex#syntax#core#new_opt('texNewthmOptNumberby')

        " \begin{mytheorem}[custom title]
        call vimtex#syntax#core#new_opt('texTheoremEnvOpt', {
                    \ 'contains': 'TOP,@NoSpell'
                    \})
    "
    " Comments
        if expand('%:e') ==# 'dtx'
            " In documented TeX Format,
              " actual comments are defined by leading "^^A".
                "   Almost all other lines start with one or more "%",
                "   which may be matched  as comment characters.
                "   ✌The remaining part of the line can be interpreted  as TeX syntax✌.
             "  For more info on dtx files, see  https://ctan.uib.no/info/dtxtut/dtxtut.pdf
            syn match texComment "\^\^A.*$"
            syn match texComment "^%\+"
        elseif g:vimtex_syntax_nospell_comments
            syn match texComment "%.*$" contains=@NoSpell,@In_fancY
        el
            syn match texComment "%.*$" contains=@Spell,@In_fancY
        en

        " Don't spell check magic comments/directives
        syn match texComment "^\s*%\s*!.*" contains=@NoSpell

        " Do not check URLs and acronyms in comments
        " Source: https://github.com/lervag/vimtex/issues/562
        syn match texCommentURL "\w\+:\/\/[^[:space:]]\+"
                    \ containedin=texComment contained contains=@NoSpell
        syn match texCommentAcronym '\v<(\u|\d){3,}s?>'
                    \ containedin=texComment contained contains=@NoSpell

        " Todo and similar within comments
        syn case ignore
        syn keyword texCommentTodo combak fixme todo xxx
                    \ containedin=texComment contained
        syn case match

        " Highlight \iffalse ... \fi blocks as comments
        syn region texComment   matchgroup=texCmdConditional
                    \ start="^\s*\\iffalse\>"
                    \ end="\\\%(fi\|else\)\>"
                    \ contains=texCommentConditionals,@In_fancY

        syn region texCommentConditionals matchgroup=texComment
                    \ start="\\if\w\+"
                    \ end="\\fi\>"
                    \ contained
                    \ transparent

        " Highlight \iftrue ... \else ... \fi   blocks as comments
        syn region texConditionalTrueZone matchgroup=texCmdConditional
                    \ start="^\s*\\iftrue\>"
                    \ end="\v\\fi>|%(\\else>)@="
                    \ contains=TOP
                    \ nextgroup=texCommentFalse
                    \ transparent

        syn region texConditionalNested matchgroup=texCmdConditional
                    \ start="\\if\w\+" end="\\fi\>"
                    \ contained contains=TOP
                    \ containedin=texConditionalTrueZone,texConditionalNested

        syn region texCommentFalse  matchgroup=texCmdConditional
                    \ start="\\else\>"
                    \ end="\\fi\>"
                    \ contained contains=texCommentConditionals

    " Zone: Verbatim
        " Verbatim environment
        call vimtex#syntax#core#new_region_env('texVerbZone', '[vV]erbatim')

        " Verbatim inline
        syn match texCmdVerb "\\verb\>\*\?" nextgroup=texVerbZoneInline
        call vimtex#syntax#core#new_arg('texVerbZoneInline', {
                    \ 'contains': '',
                    \ 'matcher': 'start="\z([^\ta-zA-Z]\)" end="\z1"'
                    \})

    " Zone: Expl3
        syn region texE3Zone matchgroup=texCmdE3
                    \ start="\\\%(ExplSyntaxOn\|ProvidesExpl\%(Package\|Class\|File\)\)"
                    \ end="\\ExplSyntaxOff\|\%$"
                    \ transparent
                    \ contains=TOP,@NoSpell

        call vimtex#syntax#core#new_arg('texE3Group', {
                    \ 'opts': 'contained containedin=@texClusterE3',
                    \})

        syn match texE3Cmd "\\\w\+"
                    \ contained containedin=@texClusterE3
                    \ nextgroup=texE3Opt,texE3Arg skipwhite skipnl
        call vimtex#syntax#core#new_opt('texE3Opt', {'next': 'texE3Arg'})
        call vimtex#syntax#core#new_arg('texE3Arg', {
                    \ 'next': 'texE3Arg',
                    \ 'opts': 'contained transparent'
                    \})

        syn match texE3CmdNestedZoneEnd '\\\ExplSyntaxOff'
                    \ contained containedin=texE3Arg,texE3Group

        syn match texE3Variable "\\[gl]_\%(\h\|@@_\@=\)*_\a\+"
                    \ contained containedin=@texClusterE3
        syn match texE3Constant "\\c_\%(\h\|@@_\@=\)*_\a\+"
                    \ contained containedin=@texClusterE3
        syn match texE3Function "\\\%(\h\|@@_\)\+:\a*"
                    \ contained containedin=@texClusterE3
                    \ contains=texE3Type

        syn match texE3Type ":[a-zA-Z]*" contained
        syn match texE3Parm "#\+\d" contained containedin=@texClusterE3

        syn cluster texClusterE3 contains=texE3Zone,texE3Arg,texE3Group,texE3Opt


    " Zone: Math
    " 封印begin end等
        " Define math region group
        call vimtex#syntax#core#new_arg('texMathGroup', {'contains': '@texClusterMath'})

        " Define math environment boundaries
        "
            " syn match texCmdMathEnv "\v\\%(begin|end)>" contained conceal   nextgroup=texMathEnvArgName
                                          " %():  Just like (), but without counting it as a sub-expression.
            syn match texCmdMathEnv "\v\\begin>" contained conceal cchar=      nextgroup=texMathEnvArgName
            syn match texCmdMathEnv "\v\\end>"   contained conceal cchar=      nextgroup=texMathEnvArgName
            " syn match texCmdMathEnv "\v\\end>"   contained conceal cchar=⇐     nextgroup=texMathEnvArgName
            call vimtex#syntax#core#new_arg('texMathEnvArgName',
                        \ {'contains': 'texComment,@NoSpell'})

        " Environments inside math zones
            " * This is used to restrict the whitespace between environment name and
            "   the option group (see https://github.com/lervag/vimtex/issues/2043).
            "
            " syn match texCmdEnvM "\v\\%(begin|end)>" contained nextgroup=texEnvMArgName
            syn match texCmdEnvM "\v\\begin>" contained conceal cchar=      nextgroup=texEnvMArgName
            syn match texCmdEnvM "\v\\end>"   contained conceal cchar=      nextgroup=texEnvMArgName
            " syn match texCmdEnvM "\v\\end>"   contained conceal cchar=⇐     nextgroup=texEnvMArgName
            call vimtex#syntax#core#new_arg('texEnvMArgName', {
                        \ 'contains': 'texComment,@NoSpell',
                        \ 'next': 'texEnvOpt',
                        \ 'skipwhite': v:false
                        \})

        " Math regions: environments
            call vimtex#syntax#core#new_region_math('displaymath')
            call vimtex#syntax#core#new_region_math('eqnarray')
            call vimtex#syntax#core#new_region_math('equation')
            call vimtex#syntax#core#new_region_math('math')

        " Math regions: Inline Math Zones
            let l:conceal = g:vimtex_syntax_conceal.math_bounds ? 'concealends' : ''
            exe   'syntax region texMathZone matchgroup=texMathDelimZone'
                          \ 'start="\v%(\\@<!)\zs\\\("'
                                                  "\ \(, 且前面不能紧贴着\
                          "\ \ 'start="\%(\\\@<!\)\@<=\\("'
                          \ 'end="\v%(\\@<!)\zs\\\)"'
                                                  "\ \), 且前面不能紧贴着\
                          \ 'contains=@texClusterMath,@In_fancY keepend'
                          \ l:conceal

            exe   'syntax region texMathZone matchgroup=texMathDelimZone'
                          \ 'start="\\\["'
                          \ 'end="\\]"'
                          \ 'contains=@texClusterMath,@In_fancY keepend'
                          \ l:conceal

            "\ 几个region里, 就它没有keepend
            exe   'syntax region texMathZoneX matchgroup=texMathDelimZone'
                          \ 'start="\$"'
                          \ 'skip="\\\\\|\\\$"'
                                    "\ 跳过¿\\¿ 或¿\¿结尾
                          \ 'end="\$"'
                          \ 'contains=@texClusterMath,@In_fancY'
                          \ 'nextgroup=texMathTextAfter'
                          \ l:conceal


            exe   'syntax region texMathZoneXX matchgroup=texMathDelimZone'
                            \ 'start="\$\$"'
                            \ 'end="\$\$"'
                            \ 'contains=@texClusterMath,@In_fancY keepend'
                            \ l:conceal

        " This is to disable spell check for text just after "$" (e.g. "$n$th")
        syn match texMathTextAfter "\w\+" contained contains=@NoSpell

        " Math regions: \ensuremath{...}
        syn match texCmdMath "\\ensuremath\>" nextgroup=texMathZoneEnsured
        call vimtex#syntax#core#new_arg('texMathZoneEnsured', {'contains': '@texClusterMath'})

        " Bad/Mismatched math
        syn match texMathError "\\[\])]"
        syn match texMathError "\\end\s*{\s*\(array\|[bBpvV]matrix\|split\|smallmatrix\)\s*}"

        " Operators and similar
        syn match texMathOper     "[/=+-]" contained
        syn match texMathSuperSub "[_^]" contained

        " Text Inside Math regions
        for l:re_cmd in [
                    \ 'text%(normal|rm|up|tt|sf|sc)?',
                    \ 'intertext',
                    \ '[mf]box',
                    \]
            exe  'syntax match texMathCmdText'
                     \ '"\v\\' . l:re_cmd . '>"'
                     \ 'contained
                      \ skipwhite
                      \ nextgroup=texMathTextArg'
        endfor
        call vimtex#syntax#core#new_arg('texMathTextArg')

        " Math style commands
            syn match texMathCmdStyle contained "\\mathbb\>"
            syn match texMathCmdStyle contained "\\mathbf\>"
            syn match texMathCmdStyle contained "\\mathcal\>"
            syn match texMathCmdStyle contained "\\mathfrak\>"
            syn match texMathCmdStyle contained "\\mathit\>"
            syn match texMathCmdStyle contained "\\mathnormal\>"
            syn match texMathCmdStyle contained "\\mathrm\>"
            syn match texMathCmdStyle contained "\\mathsf\>"
            syn match texMathCmdStyle contained "\\mathtt\>"

        " Bold and italic commands
        call s:match_bold_italic_math()

        " Support for array environment
        syn match texMathCmdEnv contained contains=texCmdMathEnv "\\begin{array}"
                    \ nextgroup=texMathArrayArg skipwhite skipnl

        syn match texMathCmdEnv contained contains=texCmdMathEnv "\\end{array}"

        call vimtex#syntax#core#new_arg('texMathArrayArg',
              \ { 'contains': '@texClusterTabular'  }
             \ )

        call s:match_math_sub_super()
        call s:match_math_delims()
        call s:match_math_symbols()
        call s:match_math_fracs()


    " Zone: SynIgnore
        syn region texSynIgnoreZone
                    \ matchgroup=texComment
                    \ start="^\c\s*% VimTeX: SynIgnore\%( on\| enable\)\?\s*$"
                    \ end="^\c\s*% VimTeX: SynIgnore\%( off\| disable\).*"
                    \ contains=texComment,texCmd

        " Also support Overleafs magic comment
            " https://www.overleaf.com/learn/how-to/Code_Check
            syn region texSynIgnoreZone matchgroup=texComment
                        \ start="^%%begin novalidate\s*$"
                        \ end="^%%end novalidate\s*$"
                        \ contains=texComment,texCmd


    " Conceal mode support
        " Add support for conceal with custom replacement (conceallevel = 2)
        if &encoding ==# 'utf-8'
            " Conceal various commands - be fancy
            if g:vimtex_syntax_conceal.fancy
                call s:match_conceal_fancy()
            en

            if g:vimtex_syntax_conceal.greek
                call s:match_conceal_greek()
            en

            " Conceal replace accented characters
            if g:vimtex_syntax_conceal.accents
                call s:match_conceal_accents()
            en

            if g:vimtex_syntax_conceal.ligatures
                call s:match_conceal_ligatures()
            en

            if g:vimtex_syntax_conceal.cites
                call s:match_conceal_cites_{g:vimtex_syntax_conceal_cites.type}()
            en

            if g:vimtex_syntax_conceal.sections
                call s:match_conceal_sections()
            en
        en


    " 自定义syntax conceal等
        for l:item in g:vimtex_syntax_custom_cmds
            call vimtex#syntax#core#new_cmd(l:item)
        endfor

    let b:current_syntax = 'tex'
endf

fun! vimtex#syntax#core#init_post() abort
    if exists('b:vimtex_syntax_did_postinit') | return | endif
    let b:vimtex_syntax_did_postinit = 1

    " Add texTheoremEnvBgn for custom theorems
    for l:envname in s:gather_newtheorems()
        exe  'syntax match texTheoremEnvBgn'
                 \ printf('"\\begin{%s}"', l:envname)
                 \ 'nextgroup=texTheoremEnvOpt skipwhite skipnl'
                 \ 'contains=texCmdEnv'
    endfor

    call vimtex#syntax#packages#init()
endf


" See :help group-name for list of conventional group names
fun! vimtex#syntax#core#init_highlights() abort

    " Primitive TeX highlighting groups
        hi link texDelim Conceal
        "\ syn list texDelim为空, 它只出现在:
                "\ matchgroup=texDelim

        hi def link texArg                Ignore

        hi def link texCmd                Ignore
        hi def link texCmdSpaceCodeChar   Ignore
        hi def link texCmdTodo            Ignore
        hi def link texCmdType            Ignore

        hi def link texCommentTodo        Ignore

        " hi def link texDelim              Delimiter
        hi link texDelim              HidE
        " hi texDelim guifg=none guibg=none gui=none
            " 大括号的fg还受其他位置控制

        hi def link texEnvArgName         Ignore

        hi def link texIgnore              Ignore
        hi def link texLength             Ignore

        hi def link texMathDelim          Ignore
        hi def link texMathEnvArgName     Ignore
        hi def link texMathOper           Ignore
        hi def link texMathZone           Ignore

        hi def link texOpt                Ignore
        hi def link texOptSep             Ignore

        hi def link texParm               Ignore
        hi def link texPartArgTitle       Ignore
        hi def link texRefArg             Ignore
        hi def link texZone               Ignore

        hi def link texSpecialChar        Ignore
        hi def link texSymbol             Ignore

        hi def link texTitleArg           Ignore




        hi def texMathStyleBold         gui=bold
        hi def texMathStyleItal         gui=bold
        " hi def texMathStyleItal         gui=italic

        hi def texStyleBold             gui=bold
        hi def texStyleItal             gui=bold
        " hi def texStyleItal             gui=italic
        hi def texStyleBoth             gui=bold,italic
        hi def texStyleUnder            gui=underline
        hi def texStyleBoldUnder        gui=bold,underline
        hi def texStyleItalUnder        gui=italic,underline
        hi def texStyleBoldItalUnder    gui=bold,italic,underline
    "
    "
    " " Inherited groups
        hi def link texCmdGreek           texMathCmd
        hi def link texCmdMath            texCmd
        hi def link texCmdLigature        texSpecialChar
        hi def link texCmdPart            texCmd
        hi def link texCmdRef             texCmd
        hi def link texCmdRefConcealed    texCmdRef
        hi def link texCmdStyleItal       texCmd
        hi def link texCommentAcronym     texComment
        hi def link texCommentFalse       texComment
        hi def link texCommentURL         texComment
        hi def link texE3Delim            texDelim
        hi def link texRefConcealedDelim  texDelim
        hi def link texMathDelimZone      texDelim
        hi def link texGroupError         texError
        hi def link texMathCmdStyle       texMathCmd
        hi def link texPartConcealed      texCmdPart
endf


