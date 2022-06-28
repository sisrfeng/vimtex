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
    "\ 在下面也有, 设了conceal的
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
        hi def link texGroupError In_backticK
        "\ 经常误报, 等编译失败时再检查?  debug buggy !!!!!!!!

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
        call vimtex#syntax#core#new_arg('texFileArg'  , {'contains': '@NoSpell,texCmd,texComment'})
        call vimtex#syntax#core#new_arg('texFilesArg' , {'contains': '@NoSpell,texCmd,texComment,texOptSep'})
        call vimtex#syntax#core#new_opt('texFileOpt'  , {'next': 'texFileArg'})
        call vimtex#syntax#core#new_opt('texFilesOpt' , {'next': 'texFilesArg'})

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
            syn match texCmdNewcmd "\v\\%(re)?newcommand>\*?"
                        \ nextgroup=texNewcmdArgName
                        \ skipwhite skipnl

            syn match texNewcmdArgName "\\[a-zA-Z@]\+"
                        \ nextgroup=texNewcmdOpt,texNewcmdArgBody
                        \ skipwhite skipnl
                        \ contained

            "\ 用到syn region
            call vimtex#syntax#core#new_arg('texNewcmdArgName',
                  \ {
                    \ 'next'     : 'texNewcmdOpt,texNewcmdArgBody',
                    \ 'contains' : ''
                   \}
                 \ )

            call vimtex#syntax#core#new_opt('texNewcmdOpt',
                   \ {
                    \ 'next': 'texNewcmdOpt,texNewcmdArgBody',
                    \ 'opts': 'oneline',
                    \}
                 \ )

            call vimtex#syntax#core#new_arg('texNewcmdArgBody')

            syn match  texNewcmdParm   contained   "\v#+\d" containedin=texNewcmdArgBody

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
            syn match texCmdDef     "\v\\def>"
                    \ nextgroup=texDefArgName
                    \ skipwhite skipnl

            syn match texDefArgName "\v\\[a-zA-Z@]+"
                    \ nextgroup=texDefParmPre,texDefArgBody
                    \ skipwhite skipnl
                    \ contained

            syn match texDefArgName "\\[^a-zA-Z@]"
                    \ nextgroup=texDefParmPre,texDefArgBody
                    \ skipwhite skipnl
                    \ contained
            syn match texDefParmPre "#[^{]*"
                    \ nextgroup=texDefArgBody
                    \ skipwhite skipnl
                    \ contained

            syn match texDefParm    "\v#+\d"
                    \ contained
                    \ containedin=texDefParmPre,texDefArgBody

            call vimtex#syntax#core#new_arg('texDefArgBody')

        " \let
            syn match texCmdLet      "\\let\>"
                            \ nextgroup=texLetArgName
                            \ skipwhite skipnl

            syn match texLetArgName  "\v\\[a-zA-Z@]+"
                            \ nextgroup=texLetArgBody,texLetArgEqual
                            \ skipwhite skipnl
                            \ contained

            syn match texLetArgName  "\\[^a-zA-Z@]"
                            \ contained
                            \ nextgroup=texLetArgBody,texLetArgEqual
                            \ skipwhite skipnl

            " Define texLetArgEqual after texLetArgBody
            " Order matters:
                " E.g. in
                    " '\let\eq=='
                    " we want:
                    " 1st = is texLetArgEqual,
                    " 2nd = is texLetArgBody

                " Reversing lines results in:
                    " 1st = is texLetArgBody,
                    " 2nd = is unmatched
                syn match texLetArgBody  "\v\\[a-zA-Z@]+|\\[^a-zA-Z@]|\S"
                        \ contained
                        \ contains=TOP,@Nospell

                syn match texLetArgEqual "="
                        \ contained
                        \ nextgroup=texLetArgBody
                        \ skipwhite skipnl

        " Reference and cite commands
            syn match texCmdRef nextgroup=texRefArg            #\v\\nocite>#        skipwhite skipnl
            syn match texCmdRef nextgroup=texRefArg            #\v\\label>#         skipwhite skipnl
            syn match texCmdRef nextgroup=texRefArg            #\v\\v?ref>#         skipwhite skipnl
            syn match texCmdRef nextgroup=texRefArg            #\v\\(page|eq)ref>#  skipwhite skipnl
            syn match texCmdRef nextgroup=texRefOpt,texRefArg  #\v\\cite>#          skipwhite skipnl
            syn match texCmdRef nextgroup=texRefOpt,texRefArg  #\v\\cite[tp]>\*?#   skipwhite skipnl
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
            syn match texComment "%.*$"   contains=@Spell,@In_fancY
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
                    \ start="\v\\if\w+"
                    \ end="\v\\fi>"
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

            syn match texCmdMathEnv "\v\\begin>"
                        \ contained
                        \ conceal
                        \ cchar=      nextgroup=texMathEnvArgName

            syn match texCmdMathEnv "\v\\end>"
                        \ contained
                        \ conceal
                        \ cchar=      nextgroup=texMathEnvArgName

            call vimtex#syntax#core#new_arg('texMathEnvArgName',
                  \ {'contains': 'texComment,@NoSpell'}
                 \ )

        " Environments inside math zones
            " * This is used to restrict the whitespace between environment name and
            "   the option group (see https://github.com/lervag/vimtex/issues/2043).
            "
            " syn match texCmdEnvM "\v\\%(begin|end)>" contained nextgroup=texEnvMArgName
            syn match texCmdEnvM "\v\\begin>" contained conceal cchar=      nextgroup=texEnvMArgName
            syn match texCmdEnvM "\v\\end>"   contained conceal cchar=      nextgroup=texEnvMArgName

            call vimtex#syntax#core#new_arg('texEnvMArgName',
                        \ {
                        \ 'contains': 'texComment,@NoSpell',
                        \ 'next': 'texEnvOpt',
                        \ 'skipwhite': v:false
                        \}
                \ )

        " Math regions: environments
            call vimtex#syntax#core#new_region_math('displaymath')
           "\  Use any of this to typeset maths in ¿display mode¿ (单独成行):
                        "\ \[...\]
                        "\ \begin{displaymath}...\end{displaymath}
                        "\ \begin{equation}...\end{equation}

            call vimtex#syntax#core#new_region_math('eqnarray')
            call vimtex#syntax#core#new_region_math('equation')
            call vimtex#syntax#core#new_region_math('math')

        " Math regions: Inline Math Zones
            "\ use any of these "delimiters" to typeset your math in inline mode:
                "\ \(...\)
                "\ $...$
                "\ \begin{math}...\end{math}.

            let l:conceal = g:vimtex_syntax_conceal.math_bounds
                          \ ? 'concealends'
                          \ : ''

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

            "\ 几个region里, 就它没有keepend, 我自己加了
            exe   'syntax region texMathZoneX matchgroup=texMathDelimZone'
                          \ 'start="\$"'
                          \ 'skip="\\\\\|\\\$"'
                                    "\ 跳过¿\\¿ 或¿\¿结尾
                          \ 'end="\$"'
                          \ 'contains=@texClusterMath,@In_fancY keepend'
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
            syn match texCmdMath
                        \ "\\ensuremath\>"
                        \ nextgroup=texMathZoneEnsured

            call vimtex#syntax#core#new_arg('texMathZoneEnsured', {'contains': '@texClusterMath'})

        " Bad/Mismatched math
            syn match texMathError "\\[\])]"

            syn match texMathError
                        \ #\\end\s*{\s*\v(array|[bBpvV]matrix|split|smallmatrix)\s*}#

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
        "\ 我删掉了contained
            syn match texMathCmdStyle           "\\mathbb\>"          conceal
            syn match texMathCmdStyle           "\\mathbf\>"          conceal
            syn match texMathCmdStyle           "\\mathcal\>"         conceal
            syn match texMathCmdStyle           "\\mathfrak\>"        conceal
            syn match texMathCmdStyle           "\\mathit\>"          conceal
            syn match texMathCmdStyle           "\\mathnormal\>"      conceal
            syn match texMathCmdStyle           "\\mathrm\>"          conceal
            syn match texMathCmdStyle           "\\mathsf\>"          conceal
            syn match texMathCmdStyle           "\\mathtt\>"          conceal




        " Bold and italic commands
        call s:match_bold_italic_math()

        " Support for array environment
        syn match texMathCmdEnv
                    \ "\\begin{array}"
                    \ contained
                    \ contains=texCmdMathEnv
                    \ nextgroup=texMathArrayArg
                    \ skipwhite skipnl

        syn match texMathCmdEnv
                    \ "\\end{array}"
                    \ contained
                    \ contains=texCmdMathEnv

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
        for l:a_custom in g:vimtex_syntax_custom_cmds
            call vimtex#syntax#core#new_cmd(l:a_custom)
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
        "\ syn list texDelim为空, 它只出现在:
                "\ matchgroup=texDelim

        "\ 在这个文件 /home/wf/dotF/cfg/nvim/after/syntax/tex.vim
        "\ 的这个函数里改:  fun! s:Tex_hi(group, fg, bg, gui)

        hi def link texArg                Ignore

        hi def link texCmd                Ignore
        hi def link texCmdSpaceCodeChar   Ignore
        hi def link texCmdTodo            Ignore
        hi def link texCmdType            Ignore

        hi def link texCommentTodo        Ignore
        hi def link texEnvArgName         Ignore

        hi def link texIgnore             Ignore
        hi def link texLength             Ignore

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
        hi def link texMathCmdStyle       texMathCmd
        hi def link texCmdGreek           texMathCmd

        hi def link texCmdMath            texCmd   "\ \ "\\ensuremath\>"
        hi def link texCmdPart            texCmd
        hi def link texCmdRef             texCmd
        hi def link texCmdStyleItal       texCmd

        hi def link texCmdLigature        texSpecialChar
        hi def link texCmdRefConcealed    texCmdRef

        hi def link texComment            Comment
        hi def link texCommentAcronym     texComment
        hi def link texCommentFalse       texComment
        hi def link texCommentURL         texComment

        hi def link texE3Delim            texDelim
        hi def link texRefConcealedDelim  texDelim
        hi def link texMathDelimZone      texDelim

        hi def link texMathError          HidE

        hi def link texPartConcealed      texCmdPart
endf


fun! s:gather_newtheorems() abort
    let l:lines = vimtex#parser#preamble(b:vimtex.tex)

    call filter(l:lines, {_, x -> x =~# '^\s*\\newtheorem\>'})
    call map(l:lines, {_, x -> matchstr(x, '^\s*\\newtheorem\>\*\?{\zs[^}]*')})

    return l:lines
endf



"\ new系列函数
    fun! vimtex#syntax#core#new_arg(grp, ...) abort
        let l:cfg = extend(
                     \ {
                       \ 'matchgroup' : 'matchgroup=texDelim'                ,
                       \ 'matcher'    : 'start="{" skip="\\\\\|\\}" end="}"' ,
                       \ 'opts'       : 'contained'                          ,
                       \ 'contains'   : 'TOP,@NoSpell'                       ,
                       \ 'next'       : ''                                   ,
                       \ 'skipwhite'  : v:true                               ,
                      \},
                     \ a:0 > 0   ?   a:1    : {}
                    \ )

        exe   'syntax region' a:grp
                  \ l:cfg.matchgroup
                  \ l:cfg.matcher
                  \ l:cfg.opts
                  \ ( empty(l:cfg.contains)
                    \ ?   ''
                    \ :   'contains=' . l:cfg.contains
                  \ )
                  \ ( empty(l:cfg.next)
                    \ ? ''
                  \   : 'nextgroup=' . l:cfg.next . (l:cfg.skipwhite ? ' skipwhite skipnl' : '')
                  \ )
    endf

    fun! vimtex#syntax#core#new_opt(grp, ...) abort
        let l:cfg = extend({
                    \ 'opts': '',
                    \ 'next': '',
                    \ 'contains': '@texClusterOpt',
                    \}, a:0 > 0 ? a:1 : {})

        exe     'syntax region' a:grp
                    \ 'contained    matchgroup=texDelim'
                    \ 'start="\["   skip="\\\\\|\\\]"   end="\]"'
                    \ l:cfg.opts
                    \ (empty(l:cfg.contains) ? '' : 'contains=' . l:cfg.contains)
                    \ (empty(l:cfg.next) ? '' : 'nextgroup=' . l:cfg.next . ' skipwhite skipnl')
    endf

    fun! vimtex#syntax#core#new_cmd(your_cfg) abort "
        if empty(get(a:your_cfg, 'name')) | return | endif

        " Parse options/config
        let l:cfg = extend({
                        \ 'mathmode'    : v:false ,
                        \ 'conceal'     : v:false ,
                        \ 'concealchar' : ''      ,
                        \ 'opt'         : v:true  ,
                        \ 'arg'         : v:true  ,
                        \ 'hide_arg'    : v:false  ,
                        \ 'argstyle'    : ''      ,
                        \ 'argspell'    : v:true  ,
                        \ 'arggreedy'   : v:false ,
                        \ 'nextgroup'   : ''      ,
                        \ 'hlgroup'     : ''      ,
                     \},
                    \ a:your_cfg)
                      "\ a:your_cfg可以扩展或覆盖前面的dict


        " Intuitive handling of concealchar
        if !empty(l:cfg.concealchar)
            let l:cfg.conceal = v:true
            if empty(l:cfg.argstyle)
                let l:cfg.opt = v:false
                let l:cfg.arg = v:false
            en
        en

        " Conceal optional group unless otherwise specified
        if !has_key(l:cfg, 'optconceal')
            let l:cfg.optconceal = l:cfg.conceal
        en

        " Define group names
            let l:name = 'wf_' . toupper(l:cfg.name[0]) . l:cfg.name[1:]
                    "\ C: 表示Custom 貌似可以随意改, 稳妥起见, 不改
                   "\ 'C'
            let l:pre = l:cfg.mathmode . 'tex'
                        \ ? 'Math'
                        \ : ''
            let l:group_cmd = l:pre . l:name . 'Cmd'
            let l:group_opt = l:pre . l:name . 'Opt'
            let l:group_arg = l:pre . l:name . 'Arg'

        " Specify rules for next groups
            if !empty(l:cfg.nextgroup)
                let l:nextgroups = 'skipwhite nextgroup=' . l:cfg.nextgroup
            el

            " Add syntax rules for the optional group [xxxxx]
            let l:nextgroups = []
            if l:cfg.opt
                let l:nextgroups += [l:group_opt]

                let l:opt_cfg = {'opts': l:cfg.optconceal ? 'conceal' : ''}
                if l:cfg.arg
                    let l:opt_cfg.next = l:group_arg
                en
                call vimtex#syntax#core#new_opt(l:group_opt, l:opt_cfg)

                exe     'highlight def link' l:group_opt 'texOpt'
            en

            " Add syntax rules for the argument group {xxxxx}
            if l:cfg.arg
                let l:nextgroups += [l:group_arg]

                "\ arg.opts:
                let l:set_arg = {'opts': 'contained'}
                    if l:cfg.conceal && empty(l:cfg.concealchar)
                        let l:set_arg.opts .= ' concealends'
                    en
                    "\ 我加的
                    if l:cfg.hide_arg
                        let l:set_arg.opts .= ' conceal'
                    en

                if l:cfg.mathmode
                    let l:set_arg.contains    = '@texClusterMath'
                elseif !l:cfg.argspell
                    let l:set_arg.contains = 'TOP,@Spell'
                en

                if l:cfg.arggreedy
                    let l:set_arg.next = l:group_arg
                en
                call vimtex#syntax#core#new_arg(l:group_arg, l:set_arg)

                let l:style = get({
                            \ 'bold'          : 'texStyleBold'          ,
                            \ 'ital'          : 'texStyleItal'          ,
                            \ 'under'         : 'texStyleUnder'         ,
                            \ 'boldital'      : 'texStyleBoth'          ,
                            \ 'boldunder'     : 'texStyleBoldUnder'     ,
                            \ 'italunder'     : 'texStyleItalUnder'     ,
                            \ 'bolditalunder' : 'texStyleBoldItalUnder' ,
                            \},
                            \ l:cfg.argstyle,
                            \ l:cfg.mathmode ?
                            \ 'texMathArg'
                            \: '')
                if !empty(l:style)
                    exe     'highlight def link' l:group_arg l:style
                en
            en

            let l:nextgroups = !empty(l:nextgroups)
                        \ ? 'skipwhite nextgroup=' . join(l:nextgroups, ',')
                        \ : ''
        en

        " Add to cluster if necessary
        if l:cfg.mathmode
            exe     'syntax cluster texClusterMath add=' . l:group_cmd
        en

        " 核心:  finally  Create the  syntax rule
                        " use ¿match¿
            exe     'syntax match' l:group_cmd
                    \ '"\v\\' . get(l:cfg, 'cmdre', l:cfg.name) . '"'
                    "\ \ '"\v\\' . get(l:cfg, 'cmdre', l:cfg.name . "\ze(\d|>)") . '"'
                    "\ \ '"\v\\' . get(l:cfg, 'cmdre', l:cfg.name . '>') . '"'
                                                                    "\ 这会导致2\times3无法变成x
                                                "\ cmdre: cmd regex吧  (之前这行 用`"` 而非 `"\` 注释 导致出错)
                    \ l:cfg.conceal
                    \ ? 'conceal'
                    \ : ''
                    \
                    \ !empty(l:cfg.concealchar)
                    \ ? 'cchar=' . l:cfg.concealchar
                    \ : ''
                    \
                    \ l:nextgroups
                    \ l:cfg.mathmode
                    \ ? 'contained'
                    \ : ''

            "\ echom     'syntax match' l:group_cmd
            "\             \ '"\v\\' . get(l:cfg, 'cmdre', l:cfg.name) . '"'
            "\             "\ \ '"\v\\' . get(l:cfg, 'cmdre', l:cfg.name . "\ze(\d|>)") . '"'
            "\             "\ \ '"\v\\' . get(l:cfg, 'cmdre', l:cfg.name . '>') . '"'
            "\                                                            "\ 这会导致2\times3无法变成x
            "\                                       "\ cmdre: cmd regex吧
            "\             \ l:cfg.conceal ?
            "\                 \ 'conceal'
            "\                 \ : ''
            "\             \ !empty(l:cfg.concealchar) ?
            "\                 \ 'cchar=' . l:cfg.concealchar
            "\                 \ : ''
            "\             \ l:nextgroups
            "\             \ l:cfg.mathmode ?
            "\                 \ 'contained'
            "\                 \ : ''

        " Define default highlight rule
        exe     'hi def link' l:group_cmd
                    \ !empty(l:cfg.hlgroup)
                      \ ?  l:cfg.hlgroup
                    \   :  l:pre . 'Cmd'
    endf


    fun! vimtex#syntax#core#new_region_env(grp, envname, ...) abort
        let l:cfg = extend({
                    \ 'contains': '',
                    \ 'opts': '',
                    \ 'transparent': 0,
                    \}, a:0 > 0 ? a:1 : {})

        let l:contains = 'contains=texCmdEnv'
        if !empty(l:cfg.contains)
            let l:contains .= ',' . l:cfg.contains
        en

        let l:options = 'keepend'
        if l:cfg.transparent
            let l:options .= ' transparent'
        en
        if !empty(l:cfg.opts)
            let l:options .= ' ' . l:cfg.opts
        en

        exe     'syntax region' a:grp
                    \ 'start="\\begin{' . a:envname .'}"'
                    \ 'end="\\end{' . a:envname .'}"'
                    \ l:contains
                    \ l:options
    endf

    fun! vimtex#syntax#core#new_region_math(mathzone, ...) abort
        let l:cfg = extend(
                        \ { 'starred' : 1, 'next' : ''  },
                        \ a:0 > 0 ? a:1 : {},
                    \ )

        let l:envname = a:mathzone . (l:cfg.starred ? '\*\?' : '')

        exe     'syntax match texMathError  "\\end{' . l:envname . '}"  '

        exe     'syntax match texMathEnvBgnEnd  "\v\\%(begin|end)>\{' .  l:envname . '\}"  contained'
                    \ ' contains=texCmdMathEnv'
                    \ ( empty(l:cfg.next)
                        \ ?  ''
                        \ :  'nextgroup=' . l:cfg.next . ' skipwhite skipnl' )

                                      " \z(aaabbb):
                                          "  用于syn-region 里的¿start=¿ ¿skip=¿, ¿end=¿的特殊的sub-expression

        exe     'syntax region texMathZoneEnv'
                    \ 'start="\\begin{\z(' . l:envname . '\)}"'
                    \ 'end="\\end{\z1}"'
                    \ 'contains=texMathEnvBgnEnd,@texClusterMath,texCmdGreek'
                    \ 'keepend'

                       "\ keepend导致@texClusterMath里的cmd不会被匹配? 应该不会
    endf

" conceal 太长, 以后用xX代替? x像封条
" 貌似是改了这个,导致git bisect了半天, 还是少改插件源码吧
" fun! vimtex#syntax#core#xX_math_cmd(cmd, pairs) abort
fun! vimtex#syntax#core#conceal_math_cmd(cmd, pairs) abort

    for [l:from, l:to] in a:pairs
        exe   'syntax match texMathSymbol'
                  \ '"\\' . a:cmd . '\%({\s*' . l:from . '\s*}\|\s\+' . l:from . '\)"'
                  \ 'contained conceal cchar=' . l:to
    endfor
endf


"\ match系列
    fun! s:match_bold_italic() abort
        let [l:conceal, l:concealends] =
                \ (g:vimtex_syntax_conceal.styles ?
                \ ['conceal', 'concealends'] :
                \ ['', ''])

        syn cluster texClusterBold     contains=TOP,@NoSpell,texCmdStyleItal,texCmdStyleBold,texCmdStyleItalBold
        syn cluster texClusterItal     contains=TOP,@NoSpell,texCmdStyleItal,texCmdStyleBold,texCmdStyleBoldItal
        syn cluster texClusterItalBold contains=TOP,@NoSpell,texCmdStyleItal,texCmdStyleBold,texCmdStyleItalBold,
                                                    \ texCmdStyleBoldItal

        let l:map = {
                \ 'texCmdStyleBold'     : 'texStyleBold',
                \ 'texCmdStyleBoldItal' : 'texStyleBoth',
                \ 'texCmdStyleItal'     : 'texStyleItal',
                \ 'texCmdStyleItalBold' : 'texStyleBoth',
            \}

        for [l:group, l:pattern] in [
        \ ['texCmdStyleBoldItal' , 'emph']   ,
        \ ['texCmdStyleBoldItal' , 'textit'] ,
        \ ['texCmdStyleBoldItal' , 'textsl'] ,
        \ ['texCmdStyleItalBold' , 'textbf'] ,
        \ ['texCmdStyleBold'     , 'textbf'] ,
        \ ['texCmdStyleItal'     , 'emph']   ,
        \ ['texCmdStyleItal'     , 'textit'] ,
        \ ['texCmdStyleItal'     , 'textsl'] ,
                                \]
            " 处理\emph 等
            exe     'syntax match' l:group
                    \ '"\\' . l:pattern . '\>"'
                    \ 'skipwhite skipnl nextgroup=' . l:map[l:group]
                    \ l:conceal
        endfor

        exe     'syntax region texStyleBold
                \ matchgroup=texDelim
                \ start="{"
                \ end="}"
                \ contained
                \ contains=@texClusterBold'
                \ l:concealends

        exe     'syntax region texStyleItal
                \ matchgroup=texDelim
                \ start="{"
                \ end="}"
                \ contained
                \ contains=@texClusterItal'
                \ l:concealends

        exe     'syntax region texStyleBoth
                \ matchgroup=texDelim
                \ start="{"
                \ end="}"
                \ contained
                \ contains=@texClusterItalBold'
                \ l:concealends

        if g:vimtex_syntax_conceal.styles
            syn match texCmdStyle "\v\\text%(rm|tt|up|normal|sf|sc)>"
                                \ conceal
                                \ skipwhite
                                \ skipnl
                                \ nextgroup=texStyleArgConc

            syn region texStyleArgConc
                                \ matchgroup=texDelim
                                \ start="{"
                                \ end="}"
                                \ contained
                                \ contains=TOP,@NoSpell
                                \ concealends
        en
    endf


    fun! s:match_bold_italic_math() abort
        let [l:conceal, l:concealends] =
                    \ (g:vimtex_syntax_conceal.styles ? ['conceal', 'concealends'] : ['', ''])

        let l:map = {
                    \ 'texMathCmdStyleBold': 'texMathStyleBold',
                    \ 'texMathCmdStyleItal': 'texMathStyleItal',
                    \}

        for [l:group, l:pattern] in [
                    \ ['texMathCmdStyleBold', 'bm'],
                    \ ['texMathCmdStyleBold', 'mathbf'],
                    \ ['texMathCmdStyleItal', 'mathit'],
                    \]
            exe     'syntax match' l:group '"\\' . l:pattern . '\>"'
                        \ 'contained skipwhite nextgroup=' . l:map[l:group]
                        \ l:conceal
        endfor

        exe   'syntax region texMathStyleBold'
                  \ 'matchgroup=texDelim'
                  \ 'start="{"   end="}" '
                  \ 'contained'
                  \ 'contains=@texClusterMath'
                  \ l:concealends

        exe   'syntax region texMathStyleItal'
                  \ 'matchgroup=texDelim'
                  \ 'start="{"    end="}"'
                  \ 'contained'
                  \ 'contains=@texClusterMath'
                  \ l:concealends

        if g:vimtex_syntax_conceal.styles
            syn match Tex_Math           "\v\\math>"
            syn match texMathCmdStyle    "\v\\math%(rm|tt|normal|sf)>"
                        \ contained conceal  skipwhite   nextgroup=texMathStyleConcArg

            syn region texMathStyleConcArg matchgroup=texDelim
                        \ start="{"
                        \ end="}"
                        \ contained
                        \ contains=@texClusterMath
                        \ concealends

            for l:re_cmd in [
                        \ 'text%(normal|rm|up|tt|sf|sc)?',
                        \ 'intertext',
                        \ '[mf]box',
                        \]
                exe     'syntax match texMathCmdText'
                            \ '"\v\\' . l:re_cmd . '>"'
                            \ 'contained  skipwhite nextgroup=texMathTextConcArg'
                            \ 'conceal'
            endfor
            syn region texMathTextConcArg matchgroup=texDelim start="{" end="}"
                        \ contained contains=TOP,@NoSpell concealends
        en
    endf



    fun! s:match_math_sub_super() abort
        if !g:vimtex_syntax_conceal.math_super_sub | return | endif

        " This feature does not work unless &encoding = 'utf-8'
        if &encoding !=# 'utf-8'
            call vimtex#log#warning(
                        \ "Conceals for math_super_sub require `set encoding='utf-8'`!")
            return
        en

        "\ super
            exe     'syntax match texMathSuperSub'
                    \ '"\v\^%(' . s:re_super . ')"'
                    \ 'conceal contained contains=texMathSuper'

            exe     'syntax match texMathSuperSub'
                    \ '"\v\^\{%(' . s:re_super . '|\s)+}"'
                    \ 'conceal contained contains=texMathSuper'

            for [l:from, l:to] in s:map_super
                exe   'syntax match texMathSuper'
                          \ '"' . l:from . '"'
                          \ 'contained conceal
                          \ cchar=' . l:to
            endfor

        "\ subscript
            exe   'syntax match texMathSuperSub'
                      \ '"\v_%(' . s:re_sub . ')"'
                      \ 'conceal contained contains=texMathSub'

            exe   'syntax match texMathSuperSub'
                      \ '"\v_\{%(' . s:re_sub . '|\s)+}"'
                      \ 'conceal contained contains=texMathSub'

            for [l:from, l:to] in copy(s:map_sub)
                exe  'syntax match texMathSub'
                         \ '"' . l:from . '"'
                         \ 'contained conceal cchar=' . l:to
            endfor
    endf

        "\ let s:re_sub =   '\v' .  '[-+=()0-9aehijklmnoprstuvx]' . '|'
        let s:re_sub =    '[-+=()0-9aehijklmnoprstuvx]' . '|'
                \ . '\\%('
                    \ . join(['beta', 'delta', 'phi', 'gamma', 'chi' ], '|')
                   \ . ')>'

        let s:re_super = '[-+=()<>:;0-9a-pr-zABDEG-PRTUVW*]'
        "\ let s:re_super = '[-+=()<>:;0-9a-pr-zABDEG-PRTUVW]'
                "\ 被刨掉:            q      F H I J K L M N O Q S X Y  Z

        let s:map_sub = [
                    \ ['\\beta\>',  'ᵦ'],
                    \ ['\\rho\>', 'ᵨ'],
                    \ ['\\phi\>',   'ᵩ'],
                    \ ['\\gamma\>', 'ᵧ'],
                    \ ['\\chi\>',   'ᵪ'],
                    \ ['(',         '₍'],
                    \ [')',         '₎'],
                    \ ['+',         '₊'],
                    \ ['-',         '₋'],
                    \ ['=',         '₌'],
                    \ ['0',         '₀'],
                    \ ['1',         '₁'],
                    \ ['2',         '₂'],
                    \ ['3',         '₃'],
                    \ ['4',         '₄'],
                    \ ['5',         '₅'],
                    \ ['6',         '₆'],
                    \ ['7',         '₇'],
                    \ ['8',         '₈'],
                    \ ['9',         '₉'],
                    \ ['a',         'ₐ'],
                    \ ['e',         'ₑ'],
                    \ ['h',         'ₕ'],
                    \ ['i',         'ᵢ'],
                    \ ['j',         'ⱼ'],
                    \ ['k',         'ₖ'],
                    \ ['l',         'ₗ'],
                    \ ['m',         'ₘ'],
                    \ ['n',         'ₙ'],
                    \ ['o',         'ₒ'],
                    \ ['p',         'ₚ'],
                    \ ['r',         'ᵣ'],
                    \ ['s',         'ₛ'],
                    \ ['t',         'ₜ'],
                    \ ['u',         'ᵤ'],
                    \ ['v',         'ᵥ'],
                    \ ['x',         'ₓ'],
                    \]

        let s:map_super = [
                    \ ['(',  '⁽'],
                    \ [')',  '⁾'],
                    \ ['+',  '⁺'],
                    \ ['-',  '⁻'],
                    \ ['=',  '⁼'],
                    \ [':',  '︓'],
                    \ [';',  '︔'],
                    \ ['<',  '˂'],
                    \ ['>',  '˃'],
                    \ ['0',  '⁰'],
                    \ ['1',  '¹'],
                    \ ['2',  '²'],
                    \ ['3',  '³'],
                    \ ['4',  '⁴'],
                    \ ['5',  '⁵'],
                    \ ['6',  '⁶'],
                    \ ['7',  '⁷'],
                    \ ['8',  '⁸'],
                    \ ['9',  '⁹'],
                    \ ['a',  'ᵃ'],
                    \ ['b',  'ᵇ'],
                    \ ['c',  'ᶜ'],
                    \ ['d',  'ᵈ'],
                    \ ['e',  'ᵉ'],
                    \ ['f',  'ᶠ'],
                    \ ['g',  'ᵍ'],
                    \ ['h',  'ʰ'],
                    \ ['i',  'ⁱ'],
                    \ ['j',  'ʲ'],
                    \ ['k',  'ᵏ'],
                    \ ['l',  'ˡ'],
                    \ ['m',  'ᵐ'],
                    \ ['n',  'ⁿ'],
                    \ ['o',  'ᵒ'],
                    \ ['p',  'ᵖ'],
                    \ ['r',  'ʳ'],
                    \ ['s',  'ˢ'],
                    \ ['t',  'ᵗ'],
                    \ ['u',  'ᵘ'],
                    \ ['v',  'ᵛ'],
                    \ ['w',  'ʷ'],
                    \ ['x',  'ˣ'],
                    \ ['y',  'ʸ'],
                    \ ['z',  'ᶻ'],
                    \ ['A',  'ᴬ'],
                    \ ['B',  'ᴮ'],
                    \ ['D',  'ᴰ'],
                    \ ['E',  'ᴱ'],
                    \ ['G',  'ᴳ'],
                    \ ['H',  'ᴴ'],
                    \ ['I',  'ᴵ'],
                    \ ['J',  'ᴶ'],
                    \ ['K',  'ᴷ'],
                    \ ['L',  'ᴸ'],
                    \ ['M',  'ᴹ'],
                    \ ['N',  'ᴺ'],
                    \ ['O',  'ᴼ'],
                    \ ['P',  'ᴾ'],
                    \ ['R',  'ᴿ'],
                    \ ['T',  'ᵀ'],
                    \ ['U',  'ᵁ'],
                    \ ['V',  'ⱽ'],
                    \ ['W',  'ᵂ'],
                    \ ['*',  '˟'],
                    \]


    fun! s:match_math_symbols() abort
        " Many of these symbols were contributed by Björn Winckler
        if !g:vimtex_syntax_conceal.math_symbols | return | endif

        "\ 这几个无法放进cmd_symbols?
            syn match texMathSymbol '\\[,:;!]'              contained conceal
            syn match texMathSymbol '\\|'                   contained conceal cchar=‖
            syn match texMathSymbol '\\sqrt\[3]'            contained conceal cchar=∛
            syn match texMathSymbol '\\sqrt\[4]'            contained conceal cchar=∜

        for [l:cmd, l:symbol] in s:cmd_symbols
            exe  'syntax match texMathSymbol'
                     "\ \ '"\v\\' . l:cmd . '"'  \ 删掉>的话, \left被\le 捣乱
                     \ '"\v\\' . l:cmd . '\ze%(>|[_^]|\d)"'
                     \ 'contained conceal'
                     \ 'cchar=' . l:symbol
                     \ 'containedin=ALL'
        endfor


        for [l:cmd, l:pairs] in items(s:cmd_pairs_dict)
            call vimtex#syntax#core#conceal_math_cmd(l:cmd, l:pairs)
        endfor
    endf

    let s:cmd_symbols = [
                \ ['aleph'             , 'ℵ'],
                \ ['amalg'             , '∐'],
                \ ['angle'             , '∠'],
                \ ['approx'            , '≈'],
                \ ['ast'               , '∗'],
                \ ['asymp'             , '≍'],
                \ ['backslash'         , '∖'],
                \ ['bigcap'            , '∩'],
                \ ['bigcirc'           , '○'],
                \ ['bigcup'            , '∪'],
                \ ['bigodot'           , '⊙'],
                \ ['bigoplus'          , '⊕'],
                \ ['bigotimes'         , '⊗'],
                \ ['bigsqcup'          , '⊔'],
                \ ['bigtriangledown'   , '∇'],
                \ ['bigtriangleup'     , '∆'],
                \ ['bigvee'            , '⋁'],
                \ ['bigwedge'          , '⋀'],
                \ ['bot'               , '⊥'],
                \ ['bowtie'            , '⋈'],
                \ ['bullet'            , '•'],
                \ ['cap'               , '∩'],
                \ ['cdot'              , '·'],
                \ ['cdots'             , '⋯'],
                \ ['circ'              , '∘'],
                \ ['clubsuit'          , '♣'],
                \ ['cong'              , '≅'],
                \ ['coprod'            , '∐'],
                \ ['copyright'         , '©'],
                \ ['cup'               , '∪'],
                \ ['dagger'            , '†'],
                \ ['dashv'             , '⊣'],
                \ ['ddagger'           , '‡'],
                \ ['ddots'             , '⋱'],
                \ ['diamond'           , '⋄'],
                \ ['diamondsuit'       , '♢'],
                \ ['div'               , '÷'],
                \ ['doteq'             , '≐'],
                \ ['dots'              , '…'],
                \ ['downarrow'         , '↓'],
                \ ['Downarrow'         , '⇓'],
                \ ['ell'               , 'ℓ'],
                \ ['emptyset'          , 'Ø'],
                \ ['equiv'             , '≡'],
                \ ['exists'            , '∃'],
                \ ['flat'              , '♭'],
                \ ['forall'            , '∀'],
                \ ['frown'             , '⁔'],
                \ ['ge'                , '≥'],
                \ ['geq'               , '≥'],
                \ ['gets'              , '←'],
                \ ['gg'                , '⟫'],
                \ ['hbar'              , 'ℏ'],
                \ ['heartsuit'         , '♡'],
                \ ['hookleftarrow'     , '↩'],
                \ ['hookrightarrow'    , '↪'],
                \ ['iff'               , '⇔'],
                \ ['Im'                , 'ℑ'],
                \ ['imath'             , 'ɩ'],
                \ ['in'                , '∈'],
                \ ['notin'             , '∉'],
                \ ['infty'             , '∞'],
                \ ['int'               , '∫'],
                \ ['iint'              , '∬'],
                \ ['iiint'             , '∭'],
                \ ['jmath'             , '𝚥'],
                \ ['land'              , '∧'],
                \ ['lnot'              , '¬'],
                \ ['lceil'             , '⌈'],
                \ ['ldots'             , '…'],
                \ ['le'                , '≤'],
                \ ['leftarrow'         , '←'],
                \ ['Leftarrow'         , '⇐'],
                \ ['leftharpoondown'   , '↽'],
                \ ['leftharpoonup'     , '↼'],
                \ ['leftrightarrow'    , '↔'],
                \ ['Leftrightarrow'    , '⇔'],
                \ ['lhd'               , '◁'],
                \ ['rhd'               , '▷'],
                \ ['leq'               , '≤'],
                \ ['ll'                , '≪'],
                \ ['lmoustache'        , '╭'],
                \ ['lor'               , '∨'],
                \ ['mapsto'            , '↦'],
                \ ['mid'               , '∣'],
                \ ['models'            , '⊨'],
                \ ['mp'                , '∓'],
                \ ['nabla'             , '∇'],
                \ ['natural'           , '♮'],
                \ ['ne'                , '≠'],
                \ ['nearrow'           , '↗'],
                \ ['neg'               , '¬'],
                \ ['neq'               , '≠'],
                \ ['ni'                , '∋'],
                \ ['nwarrow'           , '↖'],
                \ ['odot'              , '⊙'],
                \ ['oint'              , '∮'],
                \ ['ominus'            , '⊖'],
                \ ['oplus'             , '⊕'],
                \ ['oslash'            , '⊘'],
                \ ['otimes'            , '⊗'],
                \ ['owns'              , '∋'],
                \ ['P'                 , '¶'],
                \ ['parallel'          , '║'],
                \ ['partial'           , '∂'],
                \ ['perp'              , '⊥'],
                \ ['pm'                , '±'],
                \ ['prec'              , '≺'],
                \ ['preceq'            , '⪯'],
                \ ['prime'             , '′'],
                \ ['prod'              , '∏'],
                \ ['propto'            , '∝'],
                \ ['rceil'             , '⌉'],
                \ ['Re'                , 'ℜ'],
                \ ['quad'              , ' '],
                \ ['qquad'             , ' '],
                \ ['rightarrow'        , '→'],
                \ ['Rightarrow'        , '⇒'],
                \ ['leftarrow'         , '←'],
                \ ['Leftarrow'         , '⇐'],
                \ ['rightleftharpoons' , '⇌'],
                \ ['rmoustache'        , '╮'],
                \ ['S'                 , '§'],
                \ ['searrow'           , '↘'],
                \ ['setminus'          , '⧵'],
                \ ['sharp'             , '♯'],
                \ ['sim'               , '∼'],
                \ ['simeq'             , '⋍'],
                \ ['smile'             , '‿'],
                \ ['spadesuit'         , '♠'],
                \ ['sqcap'             , '⊓'],
                \ ['sqcup'             , '⊔'],
                \ ['sqsubset'          , '⊏'],
                \ ['sqsubseteq'        , '⊑'],
                \ ['sqsupset'          , '⊐'],
                \ ['sqsupseteq'        , '⊒'],
                \ ['star'              , '✫'],
                \ ['subset'            , '⊂'],
                \ ['subseteq'          , '⊆'],
                \ ['succ'              , '≻'],
                \ ['succeq'            , '⪰'],
                \ ['sum'               , '∑'],
                \ ['supset'            , '⊃'],
                \ ['supseteq'          , '⊇'],
                \ ['surd'              , '√'],
                \ ['swarrow'           , '↙'],
                \ ['times'             , '×'],
                \ ['to'                , '→'],
                \ ['top'               , '⊤'],
                \ ['triangle'          , '∆'],
                \ ['triangleleft'      , '⊲'],
                \ ['triangleright'     , '⊳'],
                \ ['uparrow'           , '↑'],
                \ ['Uparrow'           , '⇑'],
                \ ['updownarrow'       , '↕'],
                \ ['Updownarrow'       , '⇕'],
                \ ['vdash'             , '⊢'],
                \ ['vdots'             , '⋮'],
                \ ['vee'               , '∨'],
                \ ['wedge'             , '∧'],
                \ ['wp'                , '℘'],
                \ ['wr'                , '≀'],
                \ ['implies'           , '⇒'],
                \ ['choose'            , 'C'],
                \ ['sqrt'              , '√'],
                \ ['colon'             , ':'],
                \ ['coloneqq'          , '≔'],
                \]

    let s:cmd_symbols += &ambiwidth ==# 'double'
                \ ? [
                \     ['gg', '≫'],
                \     ['ll', '≪'],
                \ ]
                \ : [
                \     ['gg', '⟫'],
                \     ['ll', '⟪'],
                \ ]

    let s:cmd_pairs_dict = {
            \ 'bar': [
                \   ['a', 'ā'],
                \   ['e', 'ē'],
                \   ['g', 'ḡ'],
                \   ['i', 'ī'],
                \   ['o', 'ō'],
                \   ['u', 'ū'],
                \   ['A', 'Ā'],
                \   ['E', 'Ē'],
                \   ['G', 'Ḡ'],
                \   ['I', 'Ī'],
                \   ['O', 'Ō'],
                \   ['U', 'Ū'],
                \ ],
            \ 'dot': [
                \   ['A', 'Ȧ'],
                \   ['a', 'ȧ'],
                \   ['B', 'Ḃ'],
                \   ['b', 'ḃ'],
                \   ['C', 'Ċ'],
                \   ['c', 'ċ'],
                \   ['D', 'Ḋ'],
                \   ['d', 'ḋ'],
                \   ['E', 'Ė'],
                \   ['e', 'ė'],
                \   ['F', 'Ḟ'],
                \   ['f', 'ḟ'],
                \   ['G', 'Ġ'],
                \   ['g', 'ġ'],
                \   ['H', 'Ḣ'],
                \   ['h', 'ḣ'],
                \   ['I', 'İ'],
                \   ['M', 'Ṁ'],
                \   ['m', 'ṁ'],
                \   ['N', 'Ṅ'],
                \   ['n', 'ṅ'],
                \   ['O', 'Ȯ'],
                \   ['o', 'ȯ'],
                \   ['P', 'Ṗ'],
                \   ['p', 'ṗ'],
                \   ['R', 'Ṙ'],
                \   ['r', 'ṙ'],
                \   ['S', 'Ṡ'],
                \   ['s', 'ṡ'],
                \   ['T', 'Ṫ'],
                \   ['t', 'ṫ'],
                \   ['W', 'Ẇ'],
                \   ['w', 'ẇ'],
                \   ['X', 'Ẋ'],
                \   ['x', 'ẋ'],
                \   ['Y', 'Ẏ'],
                \   ['y', 'ẏ'],
                \   ['Z', 'Ż'],
                \   ['z', 'ż'],
                \ ],
            \ 'hat': [
                \   ['a', 'â'],
                \   ['A', 'Â'],
                \   ['c', 'ĉ'],
                \   ['C', 'Ĉ'],
                \   ['e', 'ê'],
                \   ['E', 'Ê'],
                \   ['g', 'ĝ'],
                \   ['G', 'Ĝ'],
                \   ['i', 'î'],
                \   ['I', 'Î'],
                \   ['o', 'ô'],
                \   ['O', 'Ô'],
                \   ['s', 'ŝ'],
                \   ['S', 'Ŝ'],
                \   ['u', 'û'],
                \   ['U', 'Û'],
                \   ['w', 'ŵ'],
                \   ['W', 'Ŵ'],
                \   ['y', 'ŷ'],
                \   ['Y', 'Ŷ'],
                \ ],
            \ '\%(var\)\?math\%(bb\%(b\|m\%(ss\|tt\)\?\)\?\|ds\)': [
                \   ['0', '𝟘'],
                \   ['1', '𝟙'],
                \   ['2', '𝟚'],
                \   ['3', '𝟛'],
                \   ['4', '𝟜'],
                \   ['5', '𝟝'],
                \   ['6', '𝟞'],
                \   ['7', '𝟟'],
                \   ['8', '𝟠'],
                \   ['9', '𝟡'],
                \   ['A', '𝔸'],
                \   ['B', '𝔹'],
                \   ['C', 'ℂ'],
                \   ['D', '𝔻'],
                \   ['E', '𝔼'],
                \   ['F', '𝔽'],
                \   ['G', '𝔾'],
                \   ['H', 'ℍ'],
                \   ['I', '𝕀'],
                \   ['J', '𝕁'],
                \   ['K', '𝕂'],
                \   ['L', '𝕃'],
                \   ['M', '𝕄'],
                \   ['N', 'ℕ'],
                \   ['O', '𝕆'],
                \   ['P', 'ℙ'],
                \   ['Q', 'ℚ'],
                \   ['R', 'ℝ'],
                \   ['S', '𝕊'],
                \   ['T', '𝕋'],
                \   ['U', '𝕌'],
                \   ['V', '𝕍'],
                \   ['W', '𝕎'],
                \   ['X', '𝕏'],
                \   ['Y', '𝕐'],
                \   ['Z', 'ℤ'],
                \   ['a', '𝕒'],
                \   ['b', '𝕓'],
                \   ['c', '𝕔'],
                \   ['d', '𝕕'],
                \   ['e', '𝕖'],
                \   ['f', '𝕗'],
                \   ['g', '𝕘'],
                \   ['h', '𝕙'],
                \   ['i', '𝕚'],
                \   ['j', '𝕛'],
                \   ['k', '𝕜'],
                \   ['l', '𝕝'],
                \   ['m', '𝕞'],
                \   ['n', '𝕟'],
                \   ['o', '𝕠'],
                \   ['p', '𝕡'],
                \   ['q', '𝕢'],
                \   ['r', '𝕣'],
                \   ['s', '𝕤'],
                \   ['t', '𝕥'],
                \   ['u', '𝕦'],
                \   ['v', '𝕧'],
                \   ['w', '𝕨'],
                \   ['x', '𝕩'],
                \   ['y', '𝕪'],
                \   ['z', '𝕫'],
                \ ],
                \ 'mathfrak': [
                \   ['a', '𝔞'],
                \   ['b', '𝔟'],
                \   ['c', '𝔠'],
                \   ['d', '𝔡'],
                \   ['e', '𝔢'],
                \   ['f', '𝔣'],
                \   ['g', '𝔤'],
                \   ['h', '𝔥'],
                \   ['i', '𝔦'],
                \   ['j', '𝔧'],
                \   ['k', '𝔨'],
                \   ['l', '𝔩'],
                \   ['m', '𝔪'],
                \   ['n', '𝔫'],
                \   ['o', '𝔬'],
                \   ['p', '𝔭'],
                \   ['q', '𝔮'],
                \   ['r', '𝔯'],
                \   ['s', '𝔰'],
                \   ['t', '𝔱'],
                \   ['u', '𝔲'],
                \   ['v', '𝔳'],
                \   ['w', '𝔴'],
                \   ['x', '𝔵'],
                \   ['y', '𝔶'],
                \   ['z', '𝔷'],
                \   ['A', '𝔄'],
                \   ['B', '𝔅'],
                \   ['C', 'ℭ'],
                \   ['D', '𝔇'],
                \   ['E', '𝔈'],
                \   ['F', '𝔉'],
                \   ['G', '𝔊'],
                \   ['H', 'ℌ'],
                \   ['I', 'ℑ'],
                \   ['J', '𝔍'],
                \   ['K', '𝔎'],
                \   ['L', '𝔏'],
                \   ['M', '𝔐'],
                \   ['N', '𝔑'],
                \   ['O', '𝔒'],
                \   ['P', '𝔓'],
                \   ['Q', '𝔔'],
                \   ['R', 'ℜ'],
                \   ['S', '𝔖'],
                \   ['T', '𝔗'],
                \   ['U', '𝔘'],
                \   ['V', '𝔙'],
                \   ['W', '𝔚'],
                \   ['X', '𝔛'],
                \   ['Y', '𝔜'],
                \   ['Z', 'ℨ'],
                \ ],
            \ 'math\%(scr\|cal\)': [
                \   ['A', '𝓐'],
                \   ['B', '𝓑'],
                \   ['C', '𝓒'],
                \   ['D', '𝓓'],
                \   ['E', '𝓔'],
                \   ['F', '𝓕'],
                \   ['G', '𝓖'],
                \   ['H', '𝓗'],
                \   ['I', '𝓘'],
                \   ['J', '𝓙'],
                \   ['K', '𝓚'],
                \   ['L', '𝓛'],
                \   ['M', '𝓜'],
                \   ['N', '𝓝'],
                \   ['O', '𝓞'],
                \   ['P', '𝓟'],
                \   ['Q', '𝓠'],
                \   ['R', '𝓡'],
                \   ['S', '𝓢'],
                \   ['T', '𝓣'],
                \   ['U', '𝓤'],
                \   ['V', '𝓥'],
                \   ['W', '𝓦'],
                \   ['X', '𝓧'],
                \   ['Y', '𝓨'],
                \   ['Z', '𝓩'],
                \ ],
                \}


    fun! s:match_math_fracs() abort
        if !g:vimtex_syntax_conceal.math_fracs | return | endif

        "\ syn match texMathSymbol '\v\\[dt]?frac\s*' contained conceal cchar=/
        syn match texMathSymbol '\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(2\|{2}\)' contained conceal cchar=½
        syn match texMathSymbol '\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(3\|{3}\)' contained conceal cchar=⅓
        syn match texMathSymbol '\\[dt]\?frac\s*\%(2\|{2}\)\s*\%(3\|{3}\)' contained conceal cchar=⅔
        syn match texMathSymbol '\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(4\|{4}\)' contained conceal cchar=¼
        syn match texMathSymbol '\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(5\|{5}\)' contained conceal cchar=⅕
        syn match texMathSymbol '\\[dt]\?frac\s*\%(2\|{2}\)\s*\%(5\|{5}\)' contained conceal cchar=⅖
        syn match texMathSymbol '\\[dt]\?frac\s*\%(3\|{3}\)\s*\%(5\|{5}\)' contained conceal cchar=⅗
        syn match texMathSymbol '\\[dt]\?frac\s*\%(4\|{4}\)\s*\%(5\|{5}\)' contained conceal cchar=⅘
        syn match texMathSymbol '\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(6\|{6}\)' contained conceal cchar=⅙
        syn match texMathSymbol '\\[dt]\?frac\s*\%(5\|{5}\)\s*\%(6\|{6}\)' contained conceal cchar=⅚
        syn match texMathSymbol '\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(8\|{8}\)' contained conceal cchar=⅛
        syn match texMathSymbol '\\[dt]\?frac\s*\%(3\|{3}\)\s*\%(8\|{8}\)' contained conceal cchar=⅜
        syn match texMathSymbol '\\[dt]\?frac\s*\%(5\|{5}\)\s*\%(8\|{8}\)' contained conceal cchar=⅝
        syn match texMathSymbol '\\[dt]\?frac\s*\%(7\|{7}\)\s*\%(8\|{8}\)' contained conceal cchar=⅞
    endf


    fun! s:match_math_delims() abort
        "\ syn match texMathDelimMod             "\v\\%(left|right)>"
        syn match texMathDelimMod contained   "\v\\%(left|right)>"
        syn match texMathDelimMod contained "\\[bB]igg\?[lr]\?\>"

        syn match texMathDelim contained "[<>()[\]|/.]\|\\[{}|]"
        syn match texMathDelim contained "\\backslash\>"
        syn match texMathDelim contained "\\downarrow\>"
        syn match texMathDelim contained "\\Downarrow\>"
        syn match texMathDelim contained "\\[lr]vert\>"
        syn match texMathDelim contained "\\[lr]Vert\>"
        syn match texMathDelim contained "\\langle\>"
        syn match texMathDelim contained "\\lbrace\>"
        syn match texMathDelim contained "\\lceil\>"
        syn match texMathDelim contained "\\lfloor\>"
        syn match texMathDelim contained "\\lgroup\>"
        syn match texMathDelim contained "\\lmoustache\>"
        syn match texMathDelim contained "\\rangle\>"
        syn match texMathDelim contained "\\rbrace\>"
        syn match texMathDelim contained "\\rceil\>"
        syn match texMathDelim contained "\\rfloor\>"
        syn match texMathDelim contained "\\rgroup\>"
        syn match texMathDelim contained "\\rmoustache\>"
        syn match texMathDelim contained "\\uparrow\>"
        syn match texMathDelim contained "\\Uparrow\>"
        syn match texMathDelim contained "\\updownarrow\>"
        syn match texMathDelim contained "\\Updownarrow\>"

        if !g:vimtex_syntax_conceal.math_delimiters || &encoding !=# 'utf-8'
            return
        en

        syn match texMathDelim contained conceal cchar=| "\\left|"
        syn match texMathDelim contained conceal cchar=| "\\right|"
        syn match texMathDelim contained conceal cchar=‖ "\\left\\|"
        syn match texMathDelim contained conceal cchar=‖ "\\right\\|"
        syn match texMathDelim contained conceal cchar=| "\\[lr]vert\>"
        syn match texMathDelim contained conceal cchar=‖ "\\[lr]Vert\>"
        syn match texMathDelim contained conceal cchar=( "\\left("
        syn match texMathDelim contained conceal cchar=) "\\right)"
        syn match texMathDelim contained conceal cchar=[ "\\left\["
        syn match texMathDelim contained conceal cchar=] "\\right]"
        syn match texMathDelim contained conceal cchar={ "\\left\\{"
        syn match texMathDelim contained conceal cchar=} "\\right\\}"
        syn match texMathDelim contained conceal cchar=⟨ '\\langle\>'
        syn match texMathDelim contained conceal cchar=⟩ '\\rangle\>'
        syn match texMathDelim contained conceal cchar=⌊ "\\lfloor\>"
        syn match texMathDelim contained conceal cchar=⌋ "\\rfloor\>"
        syn match texMathDelim contained conceal cchar=< "\\\%([bB]igg\?l\?\|left\)<"
        syn match texMathDelim contained conceal cchar=> "\\\%([bB]igg\?r\?\|right\)>"
        syn match texMathDelim contained conceal cchar=( "\\\%([bB]igg\?l\?\|left\)("
        syn match texMathDelim contained conceal cchar=) "\\\%([bB]igg\?r\?\|right\))"
        syn match texMathDelim contained conceal cchar=[ "\\\%([bB]igg\?l\?\|left\)\["
        syn match texMathDelim contained conceal cchar=] "\\\%([bB]igg\?r\?\|right\)]"
        syn match texMathDelim contained conceal cchar={ "\\\%([bB]igg\?l\?\|left\)\\{"
        syn match texMathDelim contained conceal cchar=} "\\\%([bB]igg\?r\?\|right\)\\}"
        syn match texMathDelim contained conceal cchar=[ "\\\%([bB]igg\?l\?\|left\)\\lbrace\>"
        syn match texMathDelim contained conceal cchar=⌈ "\\\%([bB]igg\?l\?\|left\)\\lceil\>"
        syn match texMathDelim contained conceal cchar=⌊ "\\\%([bB]igg\?l\?\|left\)\\lfloor\>"
        syn match texMathDelim contained conceal cchar=⌊ "\\\%([bB]igg\?l\?\|left\)\\lgroup\>"
        syn match texMathDelim contained conceal cchar=⎛ "\\\%([bB]igg\?l\?\|left\)\\lmoustache\>"
        syn match texMathDelim contained conceal cchar=] "\\\%([bB]igg\?r\?\|right\)\\rbrace\>"
        syn match texMathDelim contained conceal cchar=⌉ "\\\%([bB]igg\?r\?\|right\)\\rceil\>"
        syn match texMathDelim contained conceal cchar=⌋ "\\\%([bB]igg\?r\?\|right\)\\rfloor\>"
        syn match texMathDelim contained conceal cchar=⌋ "\\\%([bB]igg\?r\?\|right\)\\rgroup\>"
        syn match texMathDelim contained conceal cchar=⎞ "\\\%([bB]igg\?r\?\|right\)\\rmoustache\>"
        syn match texMathDelim contained conceal cchar=| "\\\%([bB]igg\?[lr]\?\|left\|right\)|"
        syn match texMathDelim contained conceal cchar=‖ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\|"
        syn match texMathDelim contained conceal cchar=↓ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\downarrow\>"
        syn match texMathDelim contained conceal cchar=⇓ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\Downarrow\>"
        syn match texMathDelim contained conceal cchar=↑ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\uparrow\>"
        syn match texMathDelim contained conceal cchar=↑ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\Uparrow\>"
        syn match texMathDelim contained conceal cchar=↕ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\updownarrow\>"
        syn match texMathDelim contained conceal cchar=⇕ "\\\%([bB]igg\?[lr]\?\|left\|right\)\\Updownarrow\>"

        if &ambiwidth ==# 'double'
            syn match texMathDelim contained conceal cchar=〈 "\\\%([bB]igg\?l\?\|left\)\\langle\>"
            syn match texMathDelim contained conceal cchar=〉 "\\\%([bB]igg\?r\?\|right\)\\rangle\>"
        el
            syn match texMathDelim contained conceal cchar=⟨ "\\\%([bB]igg\?l\?\|left\)\\langle\>"
            syn match texMathDelim contained conceal cchar=⟩ "\\\%([bB]igg\?r\?\|right\)\\rangle\>"
        en
    endf



    fun! s:match_conceal_accents() abort
        for [l:chr; l:targets] in s:map_accents
            for i in range(13)
                let l:target = l:targets[i]
                if empty(l:target) | continue | endif

                let l:accent = s:key_accents[i]
                let l:re_ws = l:accent =~# '^\\\\\a$' ? '\s\+' : '\s*'
                let l:re = l:accent . '\%(\s*{' . l:chr . '}\|' . l:re_ws . l:chr . '\)'
                exe     'syntax match texCmdAccent /' . l:re . '/'
                            \ 'conceal cchar=' . l:target
            endfor
        endfor
    endf

    let s:key_accents = [
                \ '\\`',
                \ '\\''',
                \ '\\^',
                \ '\\"',
                \ '\\\%(\~\|tilde\)',
                \ '\\\.',
                \ '\\=',
                \ '\\c',
                \ '\\H',
                \ '\\k',
                \ '\\r',
                \ '\\u',
                \ '\\v'
                \]

    let s:map_accents = [
                \ ['a',  'à','á','â','ä','ã','ȧ','ā','' ,'' ,'ą','å','ă','ǎ'],
                \ ['A',  'À','Á','Â','Ä','Ã','Ȧ','Ā','' ,'' ,'Ą','Å','Ă','Ǎ'],
                \ ['c',  '' ,'ć','ĉ','' ,'' ,'ċ','' ,'ç','' ,'' ,'' ,'' ,'č'],
                \ ['C',  '' ,'Ć','Ĉ','' ,'' ,'Ċ','' ,'Ç','' ,'' ,'' ,'' ,'Č'],
                \ ['d',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'ď'],
                \ ['D',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ď'],
                \ ['e',  'è','é','ê','ë','ẽ','ė','ē','ȩ','' ,'ę','' ,'ĕ','ě'],
                \ ['E',  'È','É','Ê','Ë','Ẽ','Ė','Ē','Ȩ','' ,'Ę','' ,'Ĕ','Ě'],
                \ ['g',  '' ,'ǵ','ĝ','' ,'' ,'ġ','' ,'ģ','' ,'' ,'' ,'ğ','ǧ'],
                \ ['G',  '' ,'Ǵ','Ĝ','' ,'' ,'Ġ','' ,'Ģ','' ,'' ,'' ,'Ğ','Ǧ'],
                \ ['h',  '' ,'' ,'ĥ','' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'ȟ'],
                \ ['H',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ȟ'],
                \ ['i',  'ì','í','î','ï','ĩ','į','ī','' ,'' ,'į','' ,'ĭ','ǐ'],
                \ ['I',  'Ì','Í','Î','Ï','Ĩ','İ','Ī','' ,'' ,'Į','' ,'Ĭ','Ǐ'],
                \ ['J',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'ǰ'],
                \ ['k',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'ķ','' ,'' ,'' ,'' ,'ǩ'],
                \ ['K',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ķ','' ,'' ,'' ,'' ,'Ǩ'],
                \ ['l',  '' ,'ĺ','ľ','' ,'' ,'' ,'' ,'ļ','' ,'' ,'' ,'' ,'ľ'],
                \ ['L',  '' ,'Ĺ','Ľ','' ,'' ,'' ,'' ,'Ļ','' ,'' ,'' ,'' ,'Ľ'],
                \ ['n',  '' ,'ń','' ,'' ,'ñ','' ,'' ,'ņ','' ,'' ,'' ,'' ,'ň'],
                \ ['N',  '' ,'Ń','' ,'' ,'Ñ','' ,'' ,'Ņ','' ,'' ,'' ,'' ,'Ň'],
                \ ['o',  'ò','ó','ô','ö','õ','ȯ','ō','' ,'ő','ǫ','' ,'ŏ','ǒ'],
                \ ['O',  'Ò','Ó','Ô','Ö','Õ','Ȯ','Ō','' ,'Ő','Ǫ','' ,'Ŏ','Ǒ'],
                \ ['r',  '' ,'ŕ','' ,'' ,'' ,'' ,'' ,'ŗ','' ,'' ,'' ,'' ,'ř'],
                \ ['R',  '' ,'Ŕ','' ,'' ,'' ,'' ,'' ,'Ŗ','' ,'' ,'' ,'' ,'Ř'],
                \ ['s',  '' ,'ś','ŝ','' ,'' ,'' ,'' ,'ş','' ,'ȿ','' ,'' ,'š'],
                \ ['S',  '' ,'Ś','Ŝ','' ,'' ,'' ,'' ,'Ş','' ,'' ,'' ,'' ,'Š'],
                \ ['t',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'ţ','' ,'' ,'' ,'' ,'ť'],
                \ ['T',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ţ','' ,'' ,'' ,'' ,'Ť'],
                \ ['u',  'ù','ú','û','ü','ũ','' ,'ū','' ,'ű','ų','ů','ŭ','ǔ'],
                \ ['U',  'Ù','Ú','Û','Ü','Ũ','' ,'Ū','' ,'Ű','Ų','Ů','Ŭ','Ǔ'],
                \ ['w',  '' ,'' ,'ŵ','' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
                \ ['W',  '' ,'' ,'Ŵ','' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
                \ ['y',  'ỳ','ý','ŷ','ÿ','ỹ','' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
                \ ['Y',  'Ỳ','Ý','Ŷ','Ÿ','Ỹ','' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
                \ ['z',  '' ,'ź','' ,'' ,'' ,'ż','' ,'' ,'' ,'' ,'' ,'' ,'ž'],
                \ ['Z',  '' ,'Ź','' ,'' ,'' ,'Ż','' ,'' ,'' ,'' ,'' ,'' ,'Ž'],
                \ ['\\i','ì','í','î','ï','ĩ','į','' ,'' ,'' ,'' ,'' ,'ĭ',''],
                \]


    fun! s:match_conceal_ligatures() abort
        syn match texCmdLigature "\\lq\>"    conceal cchar=‘
        syn match texCmdLigature "\\rq\>"    conceal cchar=′
        syn match texCmdLigature "\\i\>"     conceal cchar=ı
        syn match texCmdLigature "\\j\>"     conceal cchar=ȷ
        syn match texCmdLigature "\\AE\>"    conceal cchar=Æ
        syn match texCmdLigature "\\ae\>"    conceal cchar=æ
        syn match texCmdLigature "\\oe\>"    conceal cchar=œ
        syn match texCmdLigature "\\OE\>"    conceal cchar=Œ
        syn match texCmdLigature "\\o\>"     conceal cchar=ø
        syn match texCmdLigature "\\O\>"     conceal cchar=Ø
        syn match texCmdLigature "\\aa\>"    conceal cchar=å
        syn match texCmdLigature "\\AA\>"    conceal cchar=Å
        syn match texCmdLigature "\\ss\>"    conceal cchar=ß
        syn match texLigature    /--/        conceal cchar=–
        syn match texLigature    /---/       conceal cchar=—
        syn match texLigature    /`/         conceal cchar=‘
        syn match texLigature    /'/         conceal cchar=’
        syn match texLigature    /``/        conceal cchar=“
        syn match texLigature    /''/        conceal cchar=”
        syn match texLigature    /,,/        conceal cchar=„
        syn match texLigature    /!`/        conceal cchar=¡
        syn match texLigature    /?`/        conceal cchar=¿
    endf


    fun! s:match_conceal_fancy() abort
        syn match texCmd         '\\colon\>' conceal cchar=:
        syn match texCmd         '\\dots\>'  conceal cchar=…
        syn match texCmd         '\\slash\>' conceal cchar=/
        syn match texCmd         '\\ldots\>' conceal cchar=…
        syn match texCmdItem     '\\item\>'  conceal cchar=○
        syn match texTabularChar '\\\\'      conceal
        " syn match texTabularChar '\\\\'      conceal cchar=⏎
    endf


    fun! s:match_conceal_greek() abort
                                              "\ 我把contained全删了
        syn match texCmdGreek "\\alpha\>"      conceal cchar=α
        syn match texCmdGreek "\\beta\>"       conceal cchar=β
        syn match texCmdGreek "\\gamma\>"      conceal cchar=γ
        syn match texCmdGreek "\\delta\>"      conceal cchar=δ
        syn match texCmdGreek "\\epsilon\>"    conceal cchar=ϵ
        syn match texCmdGreek "\\varepsilon\>" conceal cchar=ε
        syn match texCmdGreek "\\zeta\>"       conceal cchar=ζ
        syn match texCmdGreek "\\eta\>"        conceal cchar=η
        syn match texCmdGreek "\\theta\>"      conceal cchar=θ
        syn match texCmdGreek "\\vartheta\>"   conceal cchar=ϑ
        syn match texCmdGreek "\\iota\>"       conceal cchar=ι
        syn match texCmdGreek "\\kappa\>"      conceal cchar=κ
        syn match texCmdGreek "\\lambda\>"     conceal cchar=λ
        syn match texCmdGreek "\\mu\>"         conceal cchar=μ
        syn match texCmdGreek "\\nu\>"         conceal cchar=ν
        syn match texCmdGreek "\\xi\>"         conceal cchar=ξ
        syn match texCmdGreek "\\pi\>"         conceal cchar=π
        syn match texCmdGreek "\\varpi\>"      conceal cchar=ϖ
        syn match texCmdGreek "\\rho\>"        conceal cchar=ρ
        syn match texCmdGreek "\\varrho\>"     conceal cchar=ϱ
        syn match texCmdGreek "\\sigma\>"      conceal cchar=σ
        syn match texCmdGreek "\\varsigma\>"   conceal cchar=ς
        syn match texCmdGreek "\\tau\>"        conceal cchar=τ
        syn match texCmdGreek "\\upsilon\>"    conceal cchar=υ
        syn match texCmdGreek "\\phi\>"        conceal cchar=ϕ
        syn match texCmdGreek "\\varphi\>"     conceal cchar=φ
        syn match texCmdGreek "\\chi\>"        conceal cchar=χ
        syn match texCmdGreek "\\psi\>"        conceal cchar=ψ
        syn match texCmdGreek "\\omega\>"      conceal cchar=ω
        syn match texCmdGreek "\\Gamma\>"      conceal cchar=Γ
        syn match texCmdGreek "\\Delta\>"      conceal cchar=Δ
        syn match texCmdGreek "\\Theta\>"      conceal cchar=Θ
        syn match texCmdGreek "\\Lambda\>"     conceal cchar=Λ
        syn match texCmdGreek "\\Xi\>"         conceal cchar=Ξ
        syn match texCmdGreek "\\Pi\>"         conceal cchar=Π
        syn match texCmdGreek "\\Sigma\>"      conceal cchar=Σ
        syn match texCmdGreek "\\Upsilon\>"    conceal cchar=Υ
        syn match texCmdGreek "\\Phi\>"        conceal cchar=Φ
        syn match texCmdGreek "\\Chi\>"        conceal cchar=Χ
        syn match texCmdGreek "\\Psi\>"        conceal cchar=Ψ
        syn match texCmdGreek "\\Omega\>"      conceal cchar=Ω
    endf


    fun! s:match_conceal_cites_brackets() abort
        syn match texCmdRefConcealed
                    \ "\\cite[tp]\?\>\*\?"
                    \ conceal
                    \ skipwhite
                    \ nextgroup=texRefConcealedOpt1,texRefConcealedArg

        call vimtex#syntax#core#new_opt('texRefConcealedOpt1', {
                    \ 'opts': g:vimtex_syntax_conceal_cites.verbose ? '' : 'conceal',
                    \ 'next': 'texRefConcealedOpt2,texRefConcealedArg',
                    \})
        call vimtex#syntax#core#new_opt('texRefConcealedOpt2', {
                    \ 'opts': 'conceal',
                    \ 'next': 'texRefConcealedArg',
                    \})
        call vimtex#syntax#core#new_arg('texRefConcealedArg', {
                    \ 'contains': 'texComment,@NoSpell,texRefConcealedDelim',
                    \ 'opts': 'keepend contained',
                    \ 'matchgroup': '',
                    \})
        syn match texRefConcealedDelim   contained "{" cchar=[ conceal
        syn match texRefConcealedDelim   contained "}" cchar=] conceal
    endf


    fun! s:match_conceal_cites_icon() abort
        if empty(g:vimtex_syntax_conceal_cites.icon) | return | endif

        exe     'syntax match texCmdRefConcealed'
                   \ '"\\cite[tp]\?\*\?\%(\[[^]]*\]\)\{,2}{[^}]*}"'
                    \ 'conceal'
                    \ 'cchar=' . g:vimtex_syntax_conceal_cites.icon
    endf


    fun! s:match_conceal_sections() abort
        syn match texPartConcealed      "\\"                contained conceal
        syn match texPartConcealed      "sub"               contained conceal cchar=-
        syn match texPartConcealed      "section\*\?"       contained conceal cchar=-
        " 不行
        " syn match texPartConcealed      "section\*\?\zs{"       contained conceal cchar=  "
        syn match texCmdPart   contains=texPartConcealed   nextgroup=texPartConcArgTitle
                                    \ "\v\\%(sub)*section>\*?"

        call vimtex#syntax#core#new_arg('texPartConcArgTitle', {
                    \ 'opts': 'contained keepend concealends'
                    \})
    endf


