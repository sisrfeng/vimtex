fun! vimtex#compiler#generic#init(options) abort
    return s:compiler.new(a:options)
endf

let s:compiler = vimtex#compiler#_template#new({
            \ 'name' : 'generic',
            \ 'command' : '',
            \})

fun! s:compiler.__check_requirements() abort dict
    if empty(self.command)
        call vimtex#log#warning('Please specify the command to run!')
        throw 'VimTeX: Requirements not met'
    en
endf


fun! s:compiler.__build_cmd() abort dict
    return self.command
endf

