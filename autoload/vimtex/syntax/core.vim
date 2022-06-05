" echom '我是core.vim'
" Email:      karl.yngve@gmail.com

" This script has a lot of unicode characters (for conceals)
scriptencoding utf-8

fun! vimtex#syntax#core#init() abort "
    " echo 'vimtex#syntax#core#init'
    " let b:current_syntax = 'tex'

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
                    " \conceal
                    " \cchar=X

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

    " }}}2

    " TeX symbols and special characters
        syn match texLigature "--"
        syn match texLigature "---"
        syn match texLigature "\v%(``|''|,,)"
                                 " ``flywheel effect''
                                 " 变成双引号:
                                 " "flywheel effect"

        syn match texTabularChar "&"
        syn match texTabularChar "\\\\"

        " E.g.:  \$ \& \% \# \{ \} \_ \S \P
        syn match texSpecialChar "\\[$&%#{}_]"
        syn match texSpecialChar "\\[SP@]\ze[^a-zA-Z@]"
        syn match texSpecialChar "\^\^\%(\S\|[0-9a-f]\{2}\)"
        syn match texSpecialChar "\\[,;:!]"
    " }}}2
    "
    " Commands: general
        " Unspecified TeX groups
        " This is necessary to keep track of all nested braces
        call vimtex#syntax#core#new_arg('texGroup', {'opts': ''})

        " Flag mismatching ending brace delimiter
        syn match texGroupError "}"

        " Add generic option elements contained in common option groups
        syn match texOptEqual contained "="
        syn match texOptSep contained ",\s*"

        " TeX Lengths (matched in options and some arguments)
        syn match texLength contained
           \ "\<\d\+\([.,]\d\+\)\?\s*\(true\)\?\s*\(bp\|cc\|cm\|dd\|em\|ex\|in\|mm\|pc\|pt\|sp\)\>"

        " Match general commands first
            syn match texCmd   "\\[a-zA-Z@]\+"
                                                \ nextgroup=texOpt,texArg
                                                \ skipwhite skipnl
                                                \ conceal
            call vimtex#syntax#core#new_opt(
                        \ 'texOpt',
                        \ {'next': 'texArg'},
                       \ )
            call vimtex#syntax#core#new_arg(
                        \ 'texArg',
                        \ {
                            \ 'next': 'texArg',
                            \ 'opts': 'contained transparent',
                        \ },
                       \ )

          " Generic commands, inside math regions
          " Defined here because order matters!
                                  " '\I_am_cmd'
            syn match texMathCmd  "\\\a\+"    contained   nextgroup=texMathArg
                                            \ skipwhite
                                            \ skipnl

            syn match texMathCmd  "\\times"    contained   nextgroup=texMathArg
                                            \ skipwhite
                                            \ skipnl
                                            \ conceal
                                            \ cchar=×


            call vimtex#syntax#core#new_arg(
                \ 'texMathArg',
                \ {'contains': '@texClusterMath'},
               \ )

        " Commands: core set

        " Accents and ligatures
            syn match texCmdAccent   "\\[bcdvuH]$"
            syn match texCmdAccent   "\\[bcdvuH]\ze[^a-zA-Z@]"
            syn match texCmdAccent   /\\[=^.~"`']/
            syn match texCmdAccent   /\\['=t'.c^ud"vb~Hr]{\a}/

            syn match texCmdLigature "\v\\%([ijolL]|ae|oe|ss|AA|AE|OE)$"
            syn match texCmdLigature "\v\\%([ijolL]|ae|oe|ss|AA|AE|OE)\ze[^a-zA-Z@]"

        " Spacecodes (TeX'isms)
            " * See e.g. https://en.wikibooks.org/wiki/TeX/catcode
            " * \mathcode`\^^@ = "2201
            " * \delcode`\( = "028300
            " * \sfcode`\) = 0
            " * \uccode`X = `X
            " * \lccode`x = `x
            syn match texCmdSpaceCode
                       \ "\v\\%(math|cat|del|lc|sf|uc)code`"me=e-1
                        \ nextgroup=texCmdSpaceCodeChar
            syn match texCmdSpaceCodeChar
                         \ "\v`\\?.%(\^.)?\?%(\d|\"\x{1,6}|`.)"
                         \ contained

        " Todo commands
            syn match texCmdTodo '\\todo\w*'

        " \author
            syn match texCmdAuthor
                    \ "\\author\>"
                    \ nextgroup=texAuthorOpt,texAuthorArg
                    \ skipwhite skipnl
            call vimtex#syntax#core#new_opt('texAuthorOpt', {'next': 'texAuthorArg'})
            call vimtex#syntax#core#new_arg('texAuthorArg', {'contains': 'TOP,@Spell'})

        " \title
            syn match texCmdTitle
                         \ "\\title\>"
                         \ nextgroup=texTitleArg
                         \ skipwhite skipnl

            call vimtex#syntax#core#new_arg('texTitleArg')

        " \footnote
            " 这是我加的?
            " debug
            syn match FootNotE "\\footnote\>"
                         \ contained
                         \ containedin=texCmdFootnote
                         \ conceal
            syn match texCmdFootnote
                         \ "\\footnote\>"
                         \ nextgroup=texFootnoteArg
                         \ skipwhite skipnl

            call vimtex#syntax#core#new_arg('texFootnoteArg')

        " \if \else \fi
            syn match texCmdConditional
                        \ "\\\(if[a-zA-Z@]\+\|fi\|else\)\>"
                        \ nextgroup=texConditionalArg
                        \ skipwhite skipnl
            call vimtex#syntax#core#new_arg('texConditionalArg')

        " \@ifnextchar
        " INC: If Next Char
            syn match texCmdConditional_inc
                        \ "\\\w*@ifnextchar\>"
                        \ nextgroup=texConditional_inc_Char
                        \ skipwhite skipnl
            syn match texConditional_inc_Char "\S" contained

        " Various commands that take a file argument (or similar)
            syn match texCmdInput      nextgroup=texFileArg               skipwhite skipnl   "\\input\>"
            syn match texCmdInput      nextgroup=texFileArg               skipwhite skipnl   "\\include\>"
            syn match texCmdInput      nextgroup=texFilesArg              skipwhite skipnl   "\\includeonly\>"
            syn match texCmdInput      nextgroup=texFileOpt,texFileArg    skipwhite skipnl   "\\includegraphics\>"
            syn match texCmdBib        nextgroup=texFilesArg              skipwhite skipnl   "\\bibliography\>"
            syn match texCmdBib        nextgroup=texFileArg               skipwhite skipnl   "\\bibliographystyle\>"
            syn match texCmdClass      nextgroup=texFileOpt,texFileArg    skipwhite skipnl   "\\document\%(class\|style\)\>"
            syn match texCmdPackage    nextgroup=texFilesOpt,texFilesArg  skipwhite skipnl   "\\usepackage\>"
            syn match texCmdPackage    nextgroup=texFilesOpt,texFilesArg  skipwhite skipnl   "\\RequirePackage\>"
            syn match texCmdPackage    nextgroup=texFilesOpt,texFilesArg  skipwhite skipnl   "\\ProvidesPackage\>"
            call vimtex#syntax#core#new_arg(
                \ 'texFileArg',
                \ {'contains': '@NoSpell,texCmd,texComment'},
               \ )
            call vimtex#syntax#core#new_arg(
                \ 'texFilesArg',
                \ {'contains': '@NoSpell,texCmd,texComment,texOptSep'},
               \ )
            call vimtex#syntax#core#new_opt('texFileOpt'  , {'next': 'texFileArg'})
            call vimtex#syntax#core#new_opt('texFilesOpt' , {'next': 'texFilesArg'})

        " LaTeX 2.09 type styles
            syn match texCmdStyle "\\rm\>"
            syn match texCmdStyle "\\em\>"
            syn match texCmdStyle "\\bf\>"
            syn match texCmdStyle "\\it\>"
            syn match texCmdStyle "\\s[cfl]\>"
            syn match texCmdStyle "\\tt\>"

        " LaTeX2E type styles
            syn match texCmdStyle "\\textrm\>"
            syn match texCmdStyle "\\emph\>"
            syn match texCmdStyle "\\textbf\>"
            syn match texCmdStyle "\\textit\>"
            syn match texCmdStyle "\\texts[cfl]\>"
            syn match texCmdStyle "\\texttt\>"

            syn match texCmdStyle "\\textmd\>"
            syn match texCmdStyle "\\textup\>"
            syn match texCmdStyle "\\textnormal\>"

        " type styles
            syn match texCmdStyle "\\rmfamily\>"
            syn match texCmdStyle "\\sffamily\>"
            syn match texCmdStyle "\\ttfamily\>"

            syn match texCmdStyle "\\itshape\>"
            syn match texCmdStyle "\\scshape\>"
            syn match texCmdStyle "\\slshape\>"
            syn match texCmdStyle "\\upshape\>"

            syn match texCmdStyle "\\bfseries\>"
            syn match texCmdStyle "\\mdseries\>"

        " Bold and italic commands
        " echom g:vimtex_syntax_xX
        call s:match_bold_italic()

        " Type sizes
            syn match texCmdSize "\\tiny\>"
            syn match texCmdSize "\\scriptsize\>"
            syn match texCmdSize "\\footnotesize\>"
            syn match texCmdSize "\\small\>"
            syn match texCmdSize "\\normalsize\>"
            syn match texCmdSize "\\large\>"
            syn match texCmdSize "\\Large\>"
            syn match texCmdSize "\\LARGE\>"
            syn match texCmdSize "\\huge\>"
            syn match texCmdSize "\\Huge\>"

        " \newcommand
            syn match texCmdNewcmd
                        \ "\\\%(re\)\?newcommand\>\*\?"
                        \ nextgroup=texNewcmdArgName
                        \ skipwhite skipnl

            syn match texNewcmdArgName
                        \ "\\[a-zA-Z@]\+"
                        \ nextgroup=texNewcmdOpt,texNewcmdArgBody
                        \ skipwhite skipnl
                        \ contained
            call vimtex#syntax#core#new_arg(
                         \'texNewcmdArgName',
                         \{
                            \ 'next': 'texNewcmdOpt,texNewcmdArgBody',
                            \ 'contains': ''
                         \}
                        \)
            call vimtex#syntax#core#new_opt('texNewcmdOpt',
                        \ {
                        \ 'next': 'texNewcmdOpt,texNewcmdArgBody',
                        \ 'opts': 'oneline',
                         \}
                       \)
            call vimtex#syntax#core#new_arg('texNewcmdArgBody')
            syn match texNewcmdParm
                                    \ "#\+\d"
                                    \ contained
                                    \ containedin=texNewcmdArgBody

        " \newenvironment
            syn match texCmdNewEnv
                                    \ "\\\%(re\)\?newenvironment\>"
                                    \ nextgroup=texNewEnv_ArgName
                                    \ skipwhite skipnl
            call vimtex#syntax#core#new_arg('texNewEnv_ArgName', {'next': 'texNewEnvArgBegin,texNewEnvOpt'})
            call vimtex#syntax#core#new_opt('texNewEnvOpt',
                        \ {
                        \ 'next': 'texNewEnvArgBegin,texNewEnvOpt',
                        \ 'opts': 'oneline'
                          \}
                        \)
            call vimtex#syntax#core#new_arg('texNewEnvArgBegin', {'next': 'texNewEnvArgEnd'})
            call vimtex#syntax#core#new_arg('texNewEnvArgEnd')
            syn match texNewEnvParm
                \ "#\+\d"
                \ contained
                \ containedin=texNewEnvArgBegin,texNewEnvArgEnd

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
            syn match texCmdRef    nextgroup=texRefArg            skipwhite skipnl    "\\nocite\>"            conceal
            syn match texCmdRef    nextgroup=texRefArg            skipwhite skipnl    "\\label\>"             conceal
            syn match texCmdRef    nextgroup=texRefArg            skipwhite skipnl    "\\\(page\|eq\)ref\>"   conceal
            syn match texCmdRef    nextgroup=texRefArg            skipwhite skipnl    "\\v\?ref\>"            conceal
            syn match texCmdRef    nextgroup=texRefOpt,texRefArg  skipwhite skipnl    "\\cite\>"              conceal
            syn match texCmdRef    nextgroup=texRefOpt,texRefArg  skipwhite skipnl    "\\cite[tp]\>\*\?"      conceal
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
        syn match texCmdPart "\\\(front\|main\|back\)matter\>"
        syn match texCmdPart "\\part\>"                         nextgroup=texPartArgTitle
        syn match texCmdPart "\\chapter\>\*\?"                  nextgroup=texPartArgTitle
        syn match texCmdPart "\v\\%(sub)*section>\*?"           nextgroup=texPartArgTitle
        syn match texCmdPart "\v\\%(sub)?paragraph>"            nextgroup=texPartArgTitle
        syn match texCmdPart "\v\\add%(part|chap|sec)>\*?"      nextgroup=texPartArgTitle
        call vimtex#syntax#core#new_arg('texPartArgTitle')

        " Item elements in lists
            syn match texCmdItem "\\item\>"

        " \begin \end environments
            " syn match texCmdEnv "\v\\%(begin|end)>" nextgroup=texEnvArgName
            syn match texCmdEnv   "\v\\begin" contained conceal cchar=     nextgroup=texEnvArgName
            syn match texCmdEnv   "\v\\end"   contained conceal cchar=     nextgroup=texEnvArgName
        " ✗在g:vimtex_syntax_custom_cmds里设, 尽量别改插件✗:
            " syn match texCmdEnv_b "\v\\begin"  conceal cchar=>
            " syn match texCmdEnv_e "\v\\end"    conceal cchar=<

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
    " }}}2
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
    " }}}2

    "
    " Comments
        " * In documented TeX Format,
          " actual comments are defined by leading "^^A".
        "   Almost all other lines start with one or more "%",
        "   which may be matched  as comment characters.
        "   ¿The remaining part of the line can be interpreted  as TeX syntax¿.
        " * For more info on dtx files, see e.g.
        "   https://ctan.uib.no/info/dtxtut/dtxtut.pdf
        if expand('%:e') ==# 'dtx'
            syn match texComment "\^\^A.*$"
            syn match texComment "^%\+"
        elseif g:vimtex_syntax_nospell_comments
            " syn match texComment "%.*$" contains=@NoSpell
            syn match texComment "\v(\\)@<!\%.*$" contains=@NoSpell
        el
            syn match texComment "%.*$" contains=@Spell
        en
        syn match texPercenT '\v\d\zs\\\ze\%'  conceal
        hi link texPercenT DebuG


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
        syn region texComment matchgroup=texCmdConditional
                    \ start="^\s*\\iffalse\>" end="\\\%(fi\|else\)\>"
                    \ contains=texCommentConditionals

        syn region texCommentConditionals matchgroup=texComment
                    \ start="\\if\w\+" end="\\fi\>"
                    \ contained transparent

        " Highlight \iftrue ... \else ... \fi blocks as comments
        syn region texConditionalTrueZone matchgroup=texCmdConditional
                    \ start="^\s*\\iftrue\>"  end="\v\\fi>|%(\\else>)@="
                    \ contains=TOP nextgroup=texCommentFalse
                    \ transparent

        syn region texConditionalNested matchgroup=texCmdConditional
                    \ start="\\if\w\+" end="\\fi\>"
                    \ contained contains=TOP
                    \ containedin=texConditionalTrueZone,texConditionalNested

        syn region texCommentFalse matchgroup=texCmdConditional
                    \ start="\\else\>"  end="\\fi\>"
                    \ contained contains=texCommentConditionals
    " }}}2

    " Zone: Verbatim
        " Verbatim environment
        call vimtex#syntax#core#new_region_env('texVerbZone', '[vV]erbatim')

        " Verbatim inline
        syn match texCmdVerb "\\verb\>\*\?" nextgroup=texVerbZoneInline
        call vimtex#syntax#core#new_arg('texVerbZoneInline', {
                    \ 'contains': '',
                    \ 'matcher': 'start="\z([^\ta-zA-Z]\)" end="\z1"'
                    \})
    " }}}2

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

            call vimtex#syntax#core#new_arg('texEnvMArgName',{
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
            exe     'syntax region texMathZone matchgroup=texMathDelimZone'
                            \ 'start="\%(\\\@<!\)\@<=\\("'
                            \ 'end="\%(\\\@<!\)\@<=\\)"'
                            \ 'contains=@texClusterMath keepend'
                            \ l:conceal

            exe     'syntax region texMathZone matchgroup=texMathDelimZone'
                            \ 'start="\\\["'
                            \ 'end="\\]"'
                            \ 'contains=@texClusterMath keepend'
                            \ l:conceal

            exe     'syntax region texMathZoneX matchgroup=texMathDelimZone'
                            \ 'start="\$"'
                            \ 'skip="\\\\\|\\\$"'
                            \ 'end="\$"'
                            \ 'contains=@texClusterMath'
                            \ 'nextgroup=texMathTextAfter'
                            \ l:conceal

            exe     'syntax region texMathZoneXX matchgroup=texMathDelimZone'
                            \ 'start="\$\$"'
                            \ 'end="\$\$"'
                            \ 'contains=@texClusterMath keepend'
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
        syn match texMathOper "[/=+-]" contained
        syn match texMathSuperSub "[_^]" contained

        " Text Inside Math regions
        " re: region
        for l:re_cmd in [
                    \ 'text%(normal|rm|up|tt|sf|sc)?',
                    \ 'intertext',
                    \ '[mf]box',
                    \]
            exe     'syntax match texMathCmdText'
                        \ '"\v\\' . l:re_cmd . '>"'
                        \ 'contained'
                        \ 'skipwhite'
                        \ 'nextgroup=texMathTextArg'
        endfor
        call vimtex#syntax#core#new_arg('texMathTextArg')


        " Math style commands
            " https://tex.stackexchange.com/a/58103
                " blackboard bold
                " bold face
                " cal: calligraphic 书法的
                " Fraktur (aka Gothic) 德文 哥特
                " rm : Roman
                " \mathsf  sans serif
    "
                " \mathnormal is the normal math italic font: $\mathnormal{a}$ and $a$ give the same result
                " \mathcal is the special calligraphic font for uppercase letters only
                " \mathbf gives upright Roman boldface letters
                " \mathit gives text italic letters: $different\ne\mathit{different}$
                " \mathtt gives upright letters from the typewriter type font

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
        call vimtex#syntax#core#new_arg('texMathArrayArg', {
                    \ 'contains': '@texClusterTabular'
                    \})

        call s:match_math_sub_super()
        call s:match_math_delims()
        call s:match_math_symbols()
        call s:match_math_fracs()



    " Zone: SynIgnore
        syn region texSynIgnoreZone matchgroup=texComment
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
            if g:vimtex_syntax_xX.fancy
                call s:match_xX_fancy()
            en

            " Conceal replace greek letters
            if g:vimtex_syntax_xX.greek
                call s:match_xX_greek()
            en

            " Conceal replace accented characters
            if g:vimtex_syntax_xX.accents
                call s:match_xX_accents()
            en

            " Conceal replace ligatures
            if g:vimtex_syntax_xX.ligatures
                call s:match_xX_ligatures()
            en

            " Conceal cite commands
            if g:vimtex_syntax_xX.cites
                call s:match_xX_cites_{g:vimtex_syntax_xX_cites.type}()
            en

            " Conceal section commands
            if g:vimtex_syntax_xX.sections
                call s:match_xX_sections()
            en
        en


    " Apply custom command syntax specifications
        for l:item in g:vimtex_syntax_custom_cmds
            call vimtex#syntax#core#new_cmd(l:item)
        endfor

    " 进了这个函数,没到这里
    " echom 'let b:current_syntax = "tex"'
    " let b:current_syntax = 'tex'
endf

fun! vimtex#syntax#core#init_post() abort
    if exists('b:vimtex_syntax_did_postinit') | return | endif
    let b:vimtex_syntax_did_postinit = 1

    " Add texTheoremEnvBgn for custom theorems
    for l:envname in s:gather_newtheorems()
        exe     'syntax match texTheoremEnvBgn'
                    \ printf('"\\begin{%s}"', l:envname)
                    \ 'nextgroup=texTheoremEnvOpt skipwhite skipnl'
                    \ 'contains=texCmdEnv'
    endfor

    call vimtex#syntax#packages#init()
endf


fun! vimtex#syntax#core#init_highlights() abort

    " Primitive TeX highlighting groups
        hi def link texArg                Ignore

        hi def link texCmd                Ignore
        hi def link texCmdSpaceCodeChar   Ignore
        hi def link texCmdTodo            Ignore
        hi def link texCmdType            Ignore

        hi def link texComment            Ignore
        hi def link texCommentTodo        Ignore

        " hi def link texDelim              Delimiter
        hi texDelim guifg=none guibg=none gui=none
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

        " hi def link texSpecialChar        Ignore
        " hi def link texSpecialChar        SpecialChar
        hi def link texSymbol             Ignore

        hi def link texTitleArg           Ignore

                    " 本来是
        " hi def link texArg                Include吧
        " hi def link texCmd                Statement
        " hi def link texCmdSpaceCodeChar   Special
        " hi def link texCmdTodo            Todo
        " hi def link texCmdType            Type
        " hi def link texComment            Comment
        " hi def link texCommentTodo        Todo
        " hi def link texDelim              Delimiter
        " hi def link texEnvArgName         PreCondit
        " hi def link texError              Error
        " hi def link texLength             Number
        " hi def link texMathDelim          Type
        " hi def link texMathEnvArgName     Delimiter
        " hi def link texMathOper           Operator
        " hi def link texMathZone           Special
        " hi def link texOpt                Identifier
        " hi def link texOptSep             NormalNC
        " hi def link texParm               Special
        hi def link texPartArgTitle       String
        " hi def link texRefArg             Special
        " hi def link texZone               PreCondit
        hi def link texSymbol             SpecialChar
        " hi def link texTitleArg           Underlined



        hi def texMathStyleBold         gui=bold
        hi def texMathStyleItal         gui=italic

        hi def texStyleBold             gui=bold
        hi def texStyleItal             gui=italic
        hi def texStyleBoth             gui=bold,italic
        hi def texStyleUnder            gui=underline
        hi def texStyleBoldUnder        gui=bold,underline
        hi def texStyleItalUnder        gui=italic,underline
        hi def texStyleBoldItalUnder    gui=bold,italic,underline

    " " Inherited groups
    "     hi def link texArgNew             texCmd
    "     hi def link texAuthorOpt          texOpt
    "     hi def link texBibitemArg         texArg
    "     hi def link texBibitemOpt         texOpt
    "     hi def link texBoxOptPosVal       texSymbol
    "     hi def link texBoxOptIPosVal      texBoxOptPosVal
    "     hi def link texCmdAccent          texCmd
    "     hi def link texCmdAuthor          texCmd
    "     hi def link texCmdBib             texCmd
    "     hi def link texCmdBibitem         texCmd
    "     hi def link texCmdClass           texCmd
    "     hi def link texCmdConditional     texCmd
    "     hi def link texCmdConditional_inc  texCmdConditional
    "     hi def link texCmdDef             texCmdNew
        hi def link texCmdEnv             texCmd
    "     hi def link texCmdEnvM            texCmdEnv
    "     hi def link texCmdE3              texCmd
    "     hi def link texCmdFootnote        texCmd
        hi def link texCmdGreek           texMathCmd
        hi def link texCmdMath            texCmd
    "     hi def link texCmdInput           texCmd
    "     hi def link texCmdItem            texCmdEnv
    "     hi def link texCmdLet             texCmdNew
        hi def link texCmdLigature        texSpecialChar
    "     hi def link texCmdMathEnv         texCmdEnv
    "     hi def link texCmdNew             texCmd
    "     hi def link texCmdNewcmd          texCmdNew
    "     hi def link texCmdNewEnv          texCmd
    "     hi def link texCmdNewthm          texCmd
        hi def link texCmdPackage         texCmd
    "     hi def link texCmdParbox          texCmd
        hi def link texCmdPart            texCmd
        hi def link texCmdRef             texCmd
        hi def link texCmdRefConcealed    texCmdRef
    "     hi def link texCmdSize            texCmdType
    "     hi def link texCmdSpaceCode       texCmd
    "     hi def link texCmdStyle           texCmd
    "     hi def link texCmdStyle           texCmdType
    "     hi def link texCmdStyleBold       texCmd
    "     hi def link texCmdStyleBoldItal   texCmd
    "     hi def link texCmdStyleItal       texCmd
    "     hi def link texCmdStyleItalBold   texCmd
    "     hi def link texCmdTitle           texCmd
    "     hi def link texCmdVerb            texCmd
    "     hi def link texCommentAcronym     texComment
    "     hi def link texCommentFalse       texComment
    "     hi def link texCommentURL         texComment
    "     hi def link texConditionalArg     texArg
    "     hi def link texConditional_inc_Char texSymbol
    "     hi def link texDefArgName         texArgNew
    "     hi def link texDefParm            texParm
    "     hi def link texE3Cmd              texCmd
        hi def link texE3Delim            texDelim
        hi def link texRefConcealedDelim  texDelim
        hi def link texMathDelimZone      texDelim
    "     hi def link texE3Function         texCmdType
    "     hi def link texE3Opt              texOpt
    "     hi def link texE3Parm             texParm
    "     hi def link texE3Type             texParm
    "     hi def link texE3Variable         texCmd
    "     hi def link texE3Constant         texE3Variable
    "     hi def link texEnvOpt             texOpt
    "     hi def link texEnvMArgName        texEnvArgName
    "     hi def link texFileArg            texArg
    "     hi def link texFileOpt            texOpt
    "     hi def link texFilesArg           texFileArg
    "     hi def link texFilesOpt           texFileOpt
    "     hi def link texGroupError         texError
    "     hi def link texLetArgEqual        texSymbol
    "     hi def link texLetArgName         texArgNew
        hi def link texLigature           texSymbol
    "     hi def link texMinipageOptHeight  texError
    "     hi def link texMinipageOptIPos    texError
    "     hi def link texMinipageOptPos     texError
    "     hi def link texMathArg            texMathZone
    "     hi def link texMathArrayArg       texOpt
    "     hi def link texMathCmd            texCmd
    "     hi def link texMathCmdStyle       texMathCmd
    "     hi def link texMathCmdStyleBold   texMathCmd
    "     hi def link texMathCmdStyleItal   texMathCmd
    "     hi def link texMathCmdText        texCmd
    "     hi def link texMathDelimMod       texMathDelim
    "     hi def link texMathError          texError
    "     hi def link texMathErrorDelim     texError
    "     hi def link texMathGroup          texMathZone
    "     hi def link texMathZoneEnsured    texMathZone
    "     hi def link texMathZoneEnv        texMathZone
    "     hi def link texMathZoneEnvStarred texMathZone
    "     hi def link texMathZoneX          texMathZone
    "     hi def link texMathZoneXX         texMathZone
    "     hi def link texMathStyleConcArg   texMathZone
    "     hi def link texMathSub            texMathZone
    "     hi def link texMathSuper          texMathZone
    "     hi def link texMathSuperSub       texMathOper
        hi def link texMathSymbol         texCmd
    "     hi def link texNewcmdArgName      texArgNew
    "     hi def link texNewcmdOpt          texOpt
    "     hi def link texNewcmdParm         texParm
    "     hi def link texNewEnv_ArgName      texEnvArgName
    "     hi def link texNewEnvOpt          texOpt
    "     hi def link texNewEnvParm         texParm
    "     hi def link texNewthmArgName      texArg
    "     hi def link texNewthmOptCounter   texOpt
    "     hi def link texNewthmOptNumberby  texOpt
    "     hi def link texOptEqual           texSymbol
    "     hi def link texParboxOptHeight    texError
    "     hi def link texParboxOptIPos      texError
    "     hi def link texParboxOptPos       texError
        hi def link texPartConcealed      texCmdPart
        hi def link texPartConcArgTitle   texPartArgTitle
    "     hi def link texRefOpt             texOpt
    "     hi def link texRefConcealedOpt1   texRefOpt
    "     hi def link texRefConcealedOpt2   texRefOpt
    "     hi def link texRefConcealedArg    texRefArg
    "     hi def link texTabularArg         texOpt
    "     hi def link texTabularAtSep       texMathDelim
    "     hi def link texTabularChar        texSymbol
    "     hi def link texTabularCol         texOpt
    "     hi def link texTabularOpt         texEnvOpt
    "     hi def link texTheoremEnvOpt      texEnvOpt
    "     hi def link texVerbZone           texZone
    "     hi def link texVerbZoneInline     texVerbZone
endf


fun! vimtex#syntax#core#new_arg(grp, ...) abort
    let l:cfg = extend(
                     \{
                      \'contains'   : 'TOP,@NoSpell',
                      \'matcher'    : 'start="{"
                                     \ skip="\\\\\|\\}"
                                       "\ skip掉 \\或\}
                                     \ end="}"',
                      \'next'       : '',
                      \'matchgroup' : 'matchgroup=texDelim',
                      \'opts'       : 'contained',
                      \'skipwhite'  : v:true,
                     \},
                     \
                     \a:0 > 0 ?
                     \   a:1
                     \ : {},
                \)

    exe     'syntax region' a:grp
                \ l:cfg.matchgroup
                \ l:cfg.matcher
                \ l:cfg.opts
                \ (empty(l:cfg.contains) ?
                        \  ''
                        \: 'contains='.l:cfg.contains
                 \)
                \ (empty(l:cfg.next) ?
                      \''
                    \:'nextgroup='..l:cfg.next..
                                              \(l:cfg.skipwhite ?
                                              \' skipwhite skipnl'
                                              \: ''
                                              \)
                 \)
endf

fun! vimtex#syntax#core#new_opt(grp, ...) abort
    let l:cfg = extend({
                \ 'opts': '',
                \ 'next': '',
                \ 'contains': '@texClusterOpt',
                \}, a:0 > 0 ? a:1 : {})

    exe     'syntax region' a:grp
                \ 'contained matchgroup=texDelim'
                \ 'start="\[" skip="\\\\\|\\\]" end="\]"'
                \ l:cfg.opts
                \ (empty(l:cfg.contains) ? '' : 'contains=' . l:cfg.contains)
                \ (empty(l:cfg.next) ? '' : 'nextgroup=' . l:cfg.next . ' skipwhite skipnl')
endf

fun! vimtex#syntax#core#new_cmd(cfg) abort
    if empty(get(a:cfg, 'name'))
        return
    en

    " Parse options/config
    let l:cfg = extend({
                \ 'mathmode': v:false,
                \ 'conceal': v:false,
                \ 'concealchar': '',
                \ 'opt': v:true,
                \ 'arg': v:true,
                \ 'argstyle': '',
                \ 'argspell': v:true,
                \ 'arggreedy': v:false,
                \ 'nextgroup': '',
                \ 'hlgroup': '',
                \}, a:cfg)

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
        let l:name = 'C' . toupper(l:cfg.name[0]) . l:cfg.name[1:]
        let l:pre = l:cfg.mathmode ? 'texMath' : 'tex'
        let l:group_cmd = l:pre . 'Cmd' . l:name
        let l:group_opt = l:pre . l:name . 'Opt'
        let l:group_arg = l:pre . l:name . 'Arg'

    " Specify rules for next groups
        if !empty(l:cfg.nextgroup)
            let l:nextgroups = 'skipwhite nextgroup=' . l:cfg.nextgroup
        el
            " Add syntax rules for the optional group
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

            " Add syntax rules for the argument group
            if l:cfg.arg
                let l:nextgroups += [l:group_arg]

                let l:arg_cfg = {'opts': 'contained'}
                if l:cfg.conceal && empty(l:cfg.concealchar)
                    let l:arg_cfg.opts .= ' concealends'
                en
                if l:cfg.mathmode
                    let l:arg_cfg.contains = '@texClusterMath'
                elseif !l:cfg.argspell
                    let l:arg_cfg.contains = 'TOP,@Spell'
                en
                if l:cfg.arggreedy
                    let l:arg_cfg.next = l:group_arg
                en
                call vimtex#syntax#core#new_arg(l:group_arg, l:arg_cfg)

                let l:style = get({
                            \ 'bold': 'texStyleBold',
                            \ 'ital': 'texStyleItal',
                            \ 'under': 'texStyleUnder',
                            \ 'boldital': 'texStyleBoth',
                            \ 'boldunder': 'texStyleBoldUnder',
                            \ 'italunder': 'texStyleItalUnder',
                            \ 'bolditalunder': 'texStyleBoldItalUnder',
                            \}, l:cfg.argstyle,
                            \ l:cfg.mathmode ? 'texMathArg' : '')
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

    " Create the final syntax rule
    exe     'syntax match' l:group_cmd
                \ '"\v\\' . get(l:cfg, 'cmdre', l:cfg.name . '>') . '"'
                \ l:cfg.conceal ? 'conceal' : ''
                \ !empty(l:cfg.concealchar) ? 'cchar=' . l:cfg.concealchar : ''
                \ l:nextgroups
                \ l:cfg.mathmode ? 'contained' : ''

    " Define default highlight rule
    exe     'highlight def link' l:group_cmd
                \ !empty(l:cfg.hlgroup)
                \   ? l:cfg.hlgroup
                \   : l:pre . 'Cmd'
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
    let l:cfg = extend({
                \ 'starred': 1,
                \ 'next': '',
                \}, a:0 > 0 ? a:1 : {})

    let l:envname = a:mathzone . (l:cfg.starred ? '\*\?' : '')

    exe     'syntax match texMathError  "\\end{'..l:envname ..'}"  '

    exe     'syntax match texMathEnvBgnEnd  "\\\v%(begin|end)>\{'..l:envname..'\}"  contained'
                \ ' contains=texCmdMathEnv'
                \ ( empty(l:cfg.next) ?  ''   :   'nextgroup='..l:cfg.next..' skipwhite skipnl' )

    exe     'syntax region texMathZoneEnv'
                \ 'start="\\begin{\z('..l:envname..'\)}"'
                \ 'end="\\end{\z1}"'
                \ 'contains=texMathEnvBgnEnd,@texClusterMath'
                \ 'keepend'
    " \z\(aaabbb\): 用于¿start= ¿的特殊的regex
endf


" conceal 太长, 以后用xX代替? x像封条
fun! vimtex#syntax#core#xX_math_cmd(cmd, pairs) abort

    for [l:from, l:to] in a:pairs
        exe     'syntax match texMathSymbol'
                    \ '"\\' . a:cmd . '\%({\s*' . l:from . '\s*}\|\s\+' . l:from . '\)"'
                    \ 'contained conceal cchar=' . l:to
    endfor
endf



fun! s:match_bold_italic() abort
    let [l:conceal, l:concealends] =  g:vimtex_syntax_xX.styles ?
                                        \ ['conceal', 'concealends'] :
                                        \ ['', '']

    syn cluster texClusterBold     contains=TOP,@NoSpell,texCmdStyleItal,texCmdStyleBold,texCmdStyleItalBold
    syn cluster texClusterItal     contains=TOP,@NoSpell,texCmdStyleItal,texCmdStyleBold,texCmdStyleBoldItal
    syn cluster texClusterItalBold contains=TOP,@NoSpell,texCmdStyleItal,texCmdStyleBold,texCmdStyleItalBold,texCmdStyleBoldItal

    let l:map = {
                \ 'texCmdStyleBold': 'texStyleBold',
                \ 'texCmdStyleBoldItal': 'texStyleBoth',
                \ 'texCmdStyleItal': 'texStyleItal',
                \ 'texCmdStyleItalBold': 'texStyleBoth',
                \}

    for [l:group, l:pattern] in [
                \ ['texCmdStyleBoldItal', 'emph'],
                \ ['texCmdStyleBoldItal', 'textit'],
                \ ['texCmdStyleBoldItal', 'textsl'],
                \ ['texCmdStyleItalBold', 'textbf'],
                \ ['texCmdStyleBold', 'textbf'],
                \ ['texCmdStyleItal', 'emph'],
                \ ['texCmdStyleItal', 'textit'],
                \ ['texCmdStyleItal', 'textsl'],
                \]
        exe     'syntax match' l:group '"\\' . l:pattern . '\>"'
                    \ 'skipwhite skipnl nextgroup=' . l:map[l:group]
                    \ l:conceal
    endfor

    exe     'syntax region texStyleBold matchgroup=texDelim start="{" end="}" contained contains=@texClusterBold' l:concealends
    exe     'syntax region texStyleItal matchgroup=texDelim start="{" end="}" contained contains=@texClusterItal' l:concealends
    exe     'syntax region texStyleBoth matchgroup=texDelim start="{" end="}" contained contains=@texClusterItalBold' l:concealends

    if g:vimtex_syntax_xX.styles
        syn match texCmdStyle "\v\\text%(rm|tt|up|normal|sf|sc)>"
                    \ conceal skipwhite skipnl nextgroup=texStyleArgConc
        syn region texStyleArgConc matchgroup=texDelim start="{" end="}"
                    \ contained contains=TOP,@NoSpell concealends
    en
endf


fun! s:match_bold_italic_math() abort
    let [l:conceal, l:concealends] =    g:vimtex_syntax_xX.styles ?
                                        \ ['conceal', 'concealends']
                                        \ : ['', '']
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

    exe     'syntax region texMathStyleBold matchgroup=texDelim start="{" end="}" contained contains=@texClusterMath' l:concealends
    exe     'syntax region texMathStyleItal matchgroup=texDelim start="{" end="}" contained contains=@texClusterMath' l:concealends

    if g:vimtex_syntax_xX.styles
        syn match texMathCmdStyle "\v\\math%(rm|tt|normal|sf)>"
                    \ contained conceal skipwhite nextgroup=texMathStyleConcArg
        syn region texMathStyleConcArg matchgroup=texDelim start="{" end="}"
                    \ contained contains=@texClusterMath concealends

        for l:re_cmd in [
                    \ 'text%(normal|rm|up|tt|sf|sc)?',
                    \ 'intertext',
                    \ '[mf]box',
                    \]
            exe     'syntax match texMathCmdText'
                        \ '"\v\\' . l:re_cmd . '>"'
                        \ 'contained skipwhite nextgroup=texMathTextConcArg'
                        \ 'conceal'
        endfor
        syn region texMathTextConcArg matchgroup=texDelim start="{" end="}"
                    \ contained contains=TOP,@NoSpell concealends
    en
endf



fun! s:match_math_sub_super() abort
    if !g:vimtex_syntax_xX.math_super_sub | return | endif

    " This feature does not work unless &encoding = 'utf-8'
    if &encoding !=# 'utf-8'
        call vimtex#log#warning(
                    \ "Conceals for math_super_sub require `set encoding='utf-8'`!")
        return
    en

    exe     'syntax match texMathSuperSub'
                \ '"\^\%(' . s:re_super . '\)"'
                \ 'conceal contained contains=texMathSuper'
    exe     'syntax match texMathSuperSub'
                \ '"\^{\%(' . s:re_super . '\|\s\)\+}"'
                \ 'conceal contained contains=texMathSuper'
    for [l:from, l:to] in s:map_super
        exe     'syntax match texMathSuper'
                    \ '"' . l:from . '"'
                    \ 'contained conceal cchar=' . l:to
    endfor

    exe     'syntax match texMathSuperSub'
                \ '"_\%(' . s:re_sub . '\)"'
                \ 'conceal contained contains=texMathSub'
    exe     'syntax match texMathSuperSub'
                \ '"_{\%(' . s:re_sub . '\|\s\)\+}"'
                \ 'conceal contained contains=texMathSub'
    for [l:from, l:to] in copy(s:map_sub)
        exe     'syntax match texMathSub'
                    \ '"' . l:from . '"'
                    \ 'contained conceal cchar=' . l:to
    endfor
endf

let s:re_sub =
            \ '[-+=()0-9aehijklmnoprstuvx]\|\\\%('
            \ . join([
            \     'beta', 'delta', 'phi', 'gamma', 'chi'
            \ ], '\|') . '\)\>'
let s:re_super = '[-+=()<>:;0-9a-pr-zABDEG-PRTUVW]'

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
            \]


fun! s:match_math_symbols() abort
    " Many of these symbols were contributed by Björn Winckler
    if !g:vimtex_syntax_xX.math_symbols | return | endif

    " 几个简单的case
        syn match texMathSymbol '\\[,:;!]'              contained conceal
        syn match texMathSymbol '\\|'                   contained conceal cchar=‖
        syn match texMathSymbol '\\sqrt\[3]'            contained conceal cchar=∛
        syn match texMathSymbol '\\sqrt\[4]'            contained conceal cchar=∜

    for [l:cmd, l:symbol] in s:cmd_symbols
        exe     'syntax match texMathSymbol'
                    \ '"\v\\' . l:cmd . '"'
                                    "\ $k \leq1$ 可以编译, but can not conceal
                    "\ \ '"\v\\' . l:cmd . '\ze%(>|[_^])"'
                    \ 'contained
                    \ conceal
                    \ cchar=' . l:symbol
    endfor

    for [l:cmd, l:pairs] in items(s:cmd_pairs_dict)
        call vimtex#syntax#core#xX_math_cmd(l:cmd, l:pairs)
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
                \ ['notin'             , '∉'],
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

    let s:cmd_symbols +=    &ambiwidth ==# 'double'
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
                \   ['Z', 'Ẑ'],
                \   ['D', 'Ḓ'],
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

            " ref:
            " 我记的吧
                " Characters	Unicode	Name
                " Â	U+00C2	Latin Capital Letter A with Circumflex
                " Ê	U+00CA	Latin Capital Letter E with Circumflex
                " Î	U+00CE	Latin Capital Letter I with Circumflex
                " Ô	U+00D4	Latin Capital Letter O with Circumflex
                " Û	U+00DB	Latin Capital Letter U with Circumflex
                " â	U+00E2	Latin Small Letter A with Circumflex
                " ê	U+00EA	Latin Small Letter E with Circumflex
                " î	U+00EE	Latin Small Letter I with Circumflex
                " ô	U+00F4	Latin Small Letter O with Circumflex
                " û	U+00FB	Latin Small Letter U with Circumflex
                " Ĉ	U+0108	Latin Capital Letter C with Circumflex
                " ĉ	U+0109	Latin Small Letter C with Circumflex
                " Ĝ	U+011C	Latin Capital Letter G with Circumflex
                " ĝ	U+011D	Latin Small Letter G with Circumflex
                " Ĥ	U+0124	Latin Capital Letter H with Circumflex
                " ĥ	U+0125	Latin Small Letter H with Circumflex
                " Ĵ	U+0134	Latin Capital Letter J with Circumflex
                " ĵ	U+0135	Latin Small Letter J with Circumflex
                " Ŝ	U+015C	Latin Capital Letter S with Circumflex
                " ŝ	U+015D	Latin Small Letter S with Circumflex
                " Ŵ	U+0174	Latin Capital Letter W with Circumflex
                " ŵ	U+0175	Latin Small Letter W with Circumflex
                " Ŷ	U+0176	Latin Capital Letter Y with Circumflex
                " ŷ	U+0177	Latin Small Letter Y with Circumflex
                " Ḓ	U+1E12	Latin Capital Letter D with Circumflex Below
                " ḓ	U+1E13	Latin Small Letter D with Circumflex Below
                " Ḙ	U+1E18	Latin Capital Letter E with Circumflex Below
                " ḙ	U+1E19	Latin Small Letter E with Circumflex Below
                " Ḽ	U+1E3C	Latin Capital Letter L with Circumflex Below
                " ḽ	U+1E3D	Latin Small Letter L with Circumflex Below
                " Ṋ	U+1E4A	Latin Capital Letter N with Circumflex Below
                " ṋ	U+1E4B	Latin Small Letter N with Circumflex Below
                " Ṱ	U+1E70	Latin Capital Letter T with Circumflex Below
                " ṱ	U+1E71	Latin Small Letter T with Circumflex Below
                " Ṷ	U+1E76	Latin Capital Letter U with Circumflex Below
                " ṷ	U+1E77	Latin Small Letter U with Circumflex Below
                " Ẑ	U+1E90	Latin Capital Letter Z with Circumflex
                " ẑ	U+1E91	Latin Small Letter Z with Circumflex
                " Ấ	U+1EA4	Latin Capital Letter A with Circumflex and Acute
                " ấ	U+1EA5	Latin Small Letter A with Circumflex and Acute
                " Ầ	U+1EA6	Latin Capital Letter A with Circumflex and Grave
                " ầ	U+1EA7	Latin Small Letter A with Circumflex and Grave
                " Ẩ	U+1EA8	Latin Capital Letter A with Circumflex and Hook Above
                " ẩ	U+1EA9	Latin Small Letter A with Circumflex and Hook Above
                " Ẫ	U+1EAA	Latin Capital Letter A with Circumflex and Tilde
                " ẫ	U+1EAB	Latin Small Letter A with Circumflex and Tilde
                " Ậ	U+1EAC	Latin Capital Letter A with Circumflex and Dot Below
                " ậ	U+1EAD	Latin Small Letter A with Circumflex and Dot Below


    fun! s:match_math_fracs() abort
        if !g:vimtex_syntax_xX.math_fracs | return | endif

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
        syn match texMathDelimMod contained "\\\(left\|right\)\>"
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

        if !g:vimtex_syntax_xX.math_delimiters || &encoding !=# 'utf-8'
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



fun! s:match_xX_accents() abort
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


fun! s:match_xX_ligatures() abort
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
    syn match texLigature    "--"        conceal cchar=–
    syn match texLigature    "---"       conceal cchar=—
    syn match texLigature    "`"         conceal cchar=‘
    syn match texLigature    "'"         conceal cchar=’
    syn match texLigature    "``"        conceal cchar=“
    syn match texLigature    "''"        conceal cchar=”
    syn match texLigature    ",,"        conceal cchar=„
    syn match texLigature    "!`"        conceal cchar=¡
    syn match texLigature    "?`"        conceal cchar=¿
endf


fun! s:match_xX_fancy() abort
    syn match texCmd         '\\colon\>' conceal cchar=:
    syn match texCmd         '\\dots\>'  conceal cchar=…
    syn match texCmd         '\\slash\>' conceal cchar=/
    syn match texCmd         '\\ldots\>' conceal cchar=…
    syn match texCmdItem     '\\item\>'  conceal cchar=○
    syn match texTabularChar '\\\\'      conceal cchar= " 避免弄脏屏幕
    " syn match texTabularChar '\\\\'      conceal cchar=⏎
endf


fun! s:match_xX_greek() abort
    syn match texCmdGreek "\\alpha\>"      contained conceal cchar=α
    syn match texCmdGreek "\\beta\>"       contained conceal cchar=β
    syn match texCmdGreek "\\gamma\>"      contained conceal cchar=γ
    syn match texCmdGreek "\\delta\>"      contained conceal cchar=δ
    syn match texCmdGreek "\\epsilon\>"    contained conceal cchar=ϵ
    syn match texCmdGreek "\\varepsilon\>" contained conceal cchar=ε
    syn match texCmdGreek "\\zeta\>"       contained conceal cchar=ζ
    syn match texCmdGreek "\\eta\>"        contained conceal cchar=η
    syn match texCmdGreek "\\theta\>"      contained conceal cchar=θ
    syn match texCmdGreek "\\vartheta\>"   contained conceal cchar=ϑ
    syn match texCmdGreek "\\iota\>"       contained conceal cchar=ι
    syn match texCmdGreek "\\kappa\>"      contained conceal cchar=κ
    syn match texCmdGreek "\\lambda\>"     contained conceal cchar=λ
    syn match texCmdGreek "\\mu\>"         contained conceal cchar=μ
    syn match texCmdGreek "\\nu\>"         contained conceal cchar=ν
    syn match texCmdGreek "\\xi\>"         contained conceal cchar=ξ
    syn match texCmdGreek "\\pi\>"         contained conceal cchar=π
    syn match texCmdGreek "\\varpi\>"      contained conceal cchar=ϖ
    syn match texCmdGreek "\\rho\>"        contained conceal cchar=ρ
    syn match texCmdGreek "\\varrho\>"     contained conceal cchar=ϱ
    syn match texCmdGreek "\\sigma\>"      contained conceal cchar=σ
    syn match texCmdGreek "\\varsigma\>"   contained conceal cchar=ς
    syn match texCmdGreek "\\tau\>"        contained conceal cchar=τ
    syn match texCmdGreek "\\upsilon\>"    contained conceal cchar=υ
    syn match texCmdGreek "\\phi\>"        contained conceal cchar=ϕ
    syn match texCmdGreek "\\varphi\>"     contained conceal cchar=φ
    syn match texCmdGreek "\\chi\>"        contained conceal cchar=χ
    syn match texCmdGreek "\\psi\>"        contained conceal cchar=ψ
    syn match texCmdGreek "\\omega\>"      contained conceal cchar=ω
    syn match texCmdGreek "\\Gamma\>"      contained conceal cchar=Γ
    syn match texCmdGreek "\\Delta\>"      contained conceal cchar=Δ
    syn match texCmdGreek "\\Theta\>"      contained conceal cchar=Θ
    syn match texCmdGreek "\\Lambda\>"     contained conceal cchar=Λ
    syn match texCmdGreek "\\Xi\>"         contained conceal cchar=Ξ
    syn match texCmdGreek "\\Pi\>"         contained conceal cchar=Π
    syn match texCmdGreek "\\Sigma\>"      contained conceal cchar=Σ
    syn match texCmdGreek "\\Upsilon\>"    contained conceal cchar=Υ
    syn match texCmdGreek "\\Phi\>"        contained conceal cchar=Φ
    syn match texCmdGreek "\\Chi\>"        contained conceal cchar=Χ
    syn match texCmdGreek "\\Psi\>"        contained conceal cchar=Ψ
    syn match texCmdGreek "\\Omega\>"      contained conceal cchar=Ω
endf


fun! s:match_xX_cites_brackets() abort
    syn match texCmdRefConcealed
                \ "\\cite[tp]\?\>\*\?"
                \ conceal skipwhite nextgroup=texRefConcealedOpt1,texRefConcealedArg
    call vimtex#syntax#core#new_opt('texRefConcealedOpt1', {
                \ 'opts': g:vimtex_syntax_xX_cites.verbose ? '' : 'conceal',
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


fun! s:match_xX_cites_icon() abort
    if empty(g:vimtex_syntax_xX_cites.icon) | return | endif

    exe     'syntax match texCmdRefConcealed'
                \ '"\\cite[tp]\?\*\?\%(\[[^]]*\]\)\{,2}{[^}]*}"'
                \ 'conceal cchar=' . g:vimtex_syntax_xX_cites.icon
endf


fun! s:match_xX_sections() abort
    syn match texPartConcealed      "\\"                contained conceal
    syn match texPartConcealed      "sub"               contained conceal cchar=-
    syn match texPartConcealed      "section\*\?"       contained conceal cchar=-
    syn match texCmdPart   contains=texPartConcealed
                          \ nextgroup=texPartConcArgTitle
                          \ "\v\\%(sub)*section>\*?"

    call vimtex#syntax#core#new_arg(
              \'texPartConcArgTitle',
              \ { 'opts': 'contained keepend concealends'}
            \)
endf


fun! s:gather_newtheorems() abort
    let l:lines = vimtex#parser#preamble(b:vimtex.tex)

    call filter(l:lines, {_, x -> x =~# '^\s*\\newtheorem\>'})
    call map(l:lines, {_, x -> matchstr(x, '^\s*\\newtheorem\>\*\?{\zs[^}]*')})

    return l:lines
endf


