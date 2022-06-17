if !get(g:, 'vimtex_enabled', 1)
    finish
en

if exists('b:did_ftplugin')
    finish
en
let b:did_ftplugin = 1

call vimtex#init()

