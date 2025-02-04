let s:save_cpo = &cpo
set cpo&vim

let s:source = {
          \ 'name'          :  'vimtex'              ,
          \ 'sorters'       :  'sorter_nothing'      ,
          \ 'default_kind'  :  'jump_list'           ,
          \ 'syntax'        :  'uniteSource__vimtex' ,
          \ 'entries'       :  []                    ,
          \ 'maxlevel'      :  1                     ,
          \ 'hooks'         :  {}                    ,
          \}

fun! s:source.gather_candidates(args, context) abort
    if exists('b:vimtex')
        let s:source.entries = vimtex#parser#toc()
        let s:source.maxlevel = max(map(copy(s:source.entries), 'v:val.level'))
    en
    return map(copy(s:source.entries),
                \ 's:create_candidate(v:val, s:source.maxlevel)')
endf


fun! s:source.hooks.on_syntax(args, context) abort
    syn  match VimtexTocSecs /.* @\d$/
                \ contains=VimtexTocNum,VimtexTocTag,@Tex
                \ contained containedin=uniteSource__vimtex
    syn  match VimtexTocSec0 /.* @0$/
                \ contains=VimtexTocNum,VimtexTocTag,@Tex
                \ contained containedin=uniteSource__vimtex
    syn  match VimtexTocSec1 /.* @1$/
                \ contains=VimtexTocNum,VimtexTocTag,@Tex
                \ contained containedin=uniteSource__vimtex
    syn  match VimtexTocSec2 /.* @2$/
                \ contains=VimtexTocNum,VimtexTocTag,@Tex
                \ contained containedin=uniteSource__vimtex
    syn  match VimtexTocSec3 /.* @3$/
                \ contains=VimtexTocNum,VimtexTocTag,@Tex
                \ contained containedin=uniteSource__vimtex
    syn  match VimtexTocSec4 /.* @4$/
                \ contains=VimtexTocNum,VimtexTocTag,@Tex
                \ contained containedin=uniteSource__vimtex
    syn  match VimtexTocNum
                \ /\%69v\%(\%([A-Z]\+\>\|\d\+\)\%(\.\d\+\)*\)\?\s*@\d$/
                \ contains=VimtexTocLevel
                \ contained containedin=VimtexTocSec[0-9*]
    syn  match VimtexTocTag
                \ /\[.\]\s*@\d$/
                \ contains=VimtexTocLevel
                \ contained containedin=VimtexTocSec[0-9*]
    syn  match VimtexTocLevel
                \ /@\d$/ conceal
                \ contained containedin=VimtexTocNum,VimtexTocTag
endf



fun! s:create_candidate(entry, maxlevel) abort
    let level = a:maxlevel - a:entry.level
    let title = printf('%-65S%-10s',
                \ strpart(repeat(' ', 2*level) . a:entry.title, 0, 60),
                \ b:vimtex.toc.print_number(a:entry.number))
    return {
                \ 'word' : title,
                \ 'abbr' : title . ' @' . level,
                \ 'action__path' : a:entry.file,
                \ 'action__line' : get(a:entry, 'line', 0),
                \ }
endf



fun! unite#sources#vimtex#define() abort
    return s:source
endf

let &cpo = s:save_cpo
