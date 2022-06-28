let s:scratch = { 'name' : 'VimtexScratch' }

fun! vimtex#scratch#new(opts) abort
    let l:buf = extend(
        \ deepcopy(s:scratch),
        \ a:opts,
       \ )
    call l:buf.open()
endf


fun! s:scratch.open() abort dict
    let l:bufnr  = bufnr('')
    let l:vimtex = get(b:, 'vimtex' , {})



    silent execute '-tab drop' escape(self.name, ' ')
    "\ silent execute 'keepalt edit' escape(self.name, ' ')
                          "\ :edit file_name

    let self.prev_bufnr = l:bufnr
    let b:scratch       = self
    let b:vimtex        = l:vimtex

    setl  bufhidden=wipe
    setl  buftype=nofile
    setl  concealcursor=nvic
    setl  conceallevel=0
    setl  nobuflisted
    setl  nolist
    setl  nospell
    setl  noswapfile
    setl  nowrap
    setl  tabstop=8

    "\ nno  <silent><buffer><nowait> q        :call b:scratch.close()<cr>
    "\ nno  <silent><buffer><nowait> <esc>    :call b:scratch.close()<cr>
    "\ nno  <silent><buffer><nowait> <c-6>    :call b:scratch.close()<cr>
    "\ nno  <silent><buffer><nowait> <c-^>    :call b:scratch.close()<cr>
    "\ nno  <silent><buffer><nowait> <c-e>    :call b:scratch.close()<cr>

    if has_key(self, 'syntax')  | call self.syntax()  | en

    call self.fill()
endf


fun! s:scratch.close() abort dict
    silent execute 'keepalt buffer' self.prev_bufnr
endf


fun! s:scratch.fill() abort dict
    setl  modifiable
    %delete

    call self.print_content()

    0delete _
    "\ setl  nomodifiable
endf


