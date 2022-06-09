set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on
syn    enable

" set nomore

nno      q :qall!<cr>

" Use a more colorful colorscheme
" colorscheme morning

fun! SynNames()
    return join(vimtex#syntax#stack(), ' -> ')
endf

if empty($INMAKE)
    aug  Testing
        au!
        au  CursorMoved * echo SynNames()
    aug  END
en
