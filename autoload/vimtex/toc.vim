let s:toc = {}

"\ can be called outside this script
    fun! vimtex#toc#init_buffer() abort
        if !g:vimtex_toc_enabled | return | endif

        com!  -buffer VimtexTocOpen   call b:vimtex.toc.open()
        com!  -buffer VimtexTocToggle call b:vimtex.toc.toggle()

        nno  <buffer> <plug>(vimtex-toc-open)   :call b:vimtex.toc.open()<cr>
        nno  <buffer> <plug>(vimtex-toc-toggle) :call b:vimtex.toc.toggle()<cr>
    endf


    fun! vimtex#toc#init_state(state) abort
        if !g:vimtex_toc_enabled | return | endif

        let a:state.toc = vimtex#toc#new()
    endf



    fun! vimtex#toc#new(...) abort
        return extend(
                    \ deepcopy(s:toc),
                    \ vimtex#util#extend_recursive(  deepcopy(g:vimtex_toc_config),   a:0 > 0 ? a:1 : {} )
                   \ )
    endf


    fun! vimtex#toc#get_entries() abort
        if !has_key(b:vimtex, 'toc') | return [] | endif

        return b:vimtex.toc.get_entries(0)
    endf


    fun! vimtex#toc#refresh() abort
        if has_key(b:vimtex, 'toc')
            call b:vimtex.toc.get_entries(1)
        en
    endf




"
"\ use dict as   class in python
"\ use function with 'dict' as method of a class in python
    " Open and close TOC window
    "
    fun! s:toc.open() abort dict
        if self.is_open() | return | endif

        if has_key(self, 'layers')
            for l:key in keys(self.layer_status)
                let self.layer_status[l:key] = index(self.layers, l:key) >= 0
            endfor
        en

        let self.calling_file = expand('%:p')
        let self.calling_line = line('.')

        call self.get_entries(0)

        if self.mode > 1
            call setloclist(0, map(filter(deepcopy(self.entries), 'v:val.active'),
                        \ {_, x -> {
                                \   'lnum'     : x.line,
                                \   'filename' : x.file,
                                \   'text'     : x.title,
                        \ }
                        \}))

            call setloclist(0, [], 'r', {'title': self.name})
            if self.mode == 4 | lopen | endif
        en

        if self.mode < 3
            call self.create()
        en
    endf




    fun! s:toc.is_open() abort dict
        return bufwinnr(bufnr(self.name)) >= 0
    endf


    fun! s:toc.toggle() abort dict
        if self.is_open()
            call self.close()
        el
            call self.open()
            if has_key(self, 'winid_prev')
                call win_gotoid(self.winid_prev)
            en
        en
    endf


    fun! s:toc.close() abort dict
        let self.fold_level = &l:foldlevel

        if self.resize
            silent exe 'set columns -=' .self.split_width
        en

        if self.split_pos ==# 'full'
            silent execute 'buffer' self.bufnr_prev
        el
            silent execute 'bwipeout' bufnr(self.name)
        en


        " if self.bufnr_alternate >= 0
              " let @# = self.bufnr_alternate
        " en
        try
            let @# = self.bufnr_alternate
        catch
            echo 'self.bufnr_alternate 有时不存在, 发生在BufEnter?'
            "\ echom  self
        endtry
    endf


    fun! s:toc.goto() abort dict
        if self.is_open()
            let l:winid_prev = win_getid()
            silent execute bufwinnr(bufnr(self.name)) . 'wincmd w'
            let b:toc.winid_prev = l:winid_prev
        en
    endf



    "
    " Get the TOC entries
    "
    fun! s:toc.get_entries(force) abort dict
        if has_key(self, 'entries') && !self.refresh_always && !a:force
            return self.entries
        en

        let self.entries = vimtex#parser#toc()
        let self.topmatters = vimtex#parser#toc#get_topmatters()

        "
        " Sort todo entries
        "
        if self.todo_sorted
            let l:todos = filter(copy(self.entries), 'v:val.type ==# ''todo''')
            for l:t in l:todos[1:]
                let l:t.level = 1
            endfor
            call filter(self.entries, 'v:val.type !=# ''todo''')
            let self.entries = l:todos + self.entries
        en

        "
        " Add hotkeys to entries
        "
        if self.hotkeys_enabled
            let k = strwidth(self.hotkeys)
            let n = len(self.entries)
            let m = len(s:base(n, k))
            let i = 0
            for entry in self.entries
                let keys = map(
                          \ s:base(i, k),
                          \ 'strcharpart(self.hotkeys, v:val, 1)',
                        \ )
                let keys = repeat(  [self.hotkeys[0]], m - len(keys)  ) + keys
                let i+=1

                let entry.num = i
                let entry.hotkey = join(keys, '')
            endfor
        en

        "
        " Apply active layers
        "
        for entry in self.entries
            let entry.active = self.layer_status[entry.type]
        endfor

        "
        " Refresh if wanted
        "
        if a:force && self.is_open()
            call self.refresh()
        en

        return self.entries
    endf


    fun! s:toc.get_visible_entries() abort dict
        return filter(deepcopy(get(self, 'entries', [])),
                    \ 'self.entry_is_visible(v:val)')
    endf


    fun! s:toc.entry_is_visible(entry) abort
        return get(a:entry, 'active', 1) && !get(a:entry, 'hidden')
                    \ && (a:entry.type !=# 'content' || a:entry.level <= self.tocdepth)
    endf



    "
    " Creating, refreshing and filling the buffer
    "
    fun! s:toc.create() abort dict
        let l:bufnr           = bufnr('')
        let l:bufnr_alternate = bufnr('#')
        "\ echom "l:bufnr_alternate 是: "   l:bufnr_alternate

        let l:winid           = win_getid()
        let l:vimtex          = get(b:, 'vimtex'        , {})
        let l:vimtex_syntax   = get(b:, 'vimtex_syntax' , {})

        if self.split_pos ==# 'full'
            silent execute 'edit' escape(self.name, ' ')
        el
            if self.resize
                silent exe 'set columns +=' . self.split_width
            en
            silent execute  self.split_pos  self.split_width   'new'   escape(self.name, ' ')
        en

        let self.bufnr_prev      = l:bufnr
        let self.bufnr_alternate = l:bufnr_alternate
        let self.winid_prev      = l:winid
        let b:toc                = self
        let b:vimtex             = l:vimtex
        let b:vimtex_syntax      = l:vimtex_syntax

        setl  bufhidden=wipe
        setl  buftype=nofile
        setl  concealcursor=nvic
        setl  conceallevel=2
        setl  cursorline
        setl  nobuflisted
        setl  nolist
        setl  nospell
        setl  noswapfile
        setl  nowrap
        setl  tabstop=8
        setl  winfixwidth
        setl  winfixheight

        if self.hide_line_numbers
            setl  nonumber
            setl  norelativenumber
        en

        call self.refresh()
        call self.set_syntax()

        if self.fold_enable
            let self.foldexpr = function('s:foldexpr')
            let self.foldtext = function('s:foldtext')
            setl  foldmethod=expr
            setl  foldexpr=b:toc.foldexpr(v:lnum)
            setl  foldtext=b:toc.foldtext()
            let &l:foldlevel = get(
                \ self,
                \ 'fold_level',
                \ (self.fold_level_start > 0? self.fold_level_start: self.tocdepth),
               \ )
        en

        nno  <silent><buffer><nowait><expr>   gg     b:toc.show_help  ?  'gg}}j'  : 'gg'

        nno  <silent><buffer><nowait>    <esc>OA       k
        nno  <silent><buffer><nowait>    <esc>OC       k
        nno  <silent><buffer><nowait>    <esc>OB       j
        nno  <silent><buffer><nowait>    <esc>OD       j

        nno  <silent><buffer><nowait>    q              :call b:toc.close()<cr>
        nno  <silent><buffer><nowait>    go             :call b:toc.close()<cr>

        "\ nno  <silent><buffer><nowait>    <esc>         :call b:toc.close()<cr>

        "\ nno  <silent><buffer><nowait>    <space>       :call b:toc.activate_current(0)<cr>
        nno  <silent><buffer><nowait>    <2-leftmouse> :call b:toc.activate_current(0)<cr>
        nno  <silent><buffer><nowait>    <cr>          :call b:toc.activate_current(1)<cr>

        "\ nno  <silent><buffer><nowait>    h             :call b:toc.toggle_help()<cr>
        nno  <silent><buffer><nowait>    s             :call b:toc.toggle_numbers()<cr>
        nno  <silent><buffer><nowait>    t             :call b:toc.toggle_sorted_todos()<cr>

        nno  <silent><buffer><nowait>    <c-f>             :call b:toc.filter()<cr>
        nno  <silent><buffer><nowait>    <m-f>             :call b:toc.clear_filter()<cr>

        nno  <silent><buffer><nowait>    r                 :call b:toc.get_entries(1)<cr>
        nno  <silent><buffer><nowait>    <M-h>             :call b:toc.decrease_depth()<cr>
        nno  <silent><buffer><nowait>    <M-l>             :call b:toc.increase_depth()<cr>

        com!  -buffer VimtexTocToggle call b:toc.close()

        for [type, key] in items(self.layer_keys)
            exe  printf(
                      \ 'nnoremap  <silent><buffer><nowait> %s'
                      \ . ' :call b:toc.toggle_type(''%s'')<cr>',
                      \ key, type
                      \)
        endfor

        if self.hotkeys_enabled
            for entry in self.entries
                exe  printf(
                            \ 'nnoremap <silent><buffer><nowait> %s%s'
                            \ . ' :call b:toc.activate_hotkey(''%s'')<cr>',
                                    \ self.hotkeys_leader,
                                        \entry.hotkey,
                                        \entry.hotkey
                            \)
            endfor
        en

        " Jump to closest index
        call vimtex#pos#set_cursor(self.get_closest_index())

        if exists('#User#VimtexEventTocCreated')
            doautocmd <nomodeline> User VimtexEventTocCreated
        en
    endf


    fun! s:toc.refresh() abort dict
        let l:toc_winnr = bufwinnr(bufnr(self.name))
        let l:buf_winnr = bufwinnr(bufnr(''))

        if l:toc_winnr < 0
            return
        elseif l:buf_winnr != l:toc_winnr
            silent execute l:toc_winnr . 'wincmd w'
        en

        call self.position_save()
        setl  modifiable
        silent %delete _

        call self.print_help()
        call self.print_entries()

        0delete _
        setl  nomodifiable
        call self.position_restore()

        if l:buf_winnr != l:toc_winnr
            silent execute l:buf_winnr . 'wincmd w'
        en
    endf


    fun! s:toc.set_syntax() abort dict "{{{1
        syn  clear

        if self.show_help
            exe  'syntax match VimtexTocHelp'
                        \ '/^\%<' . self.help_nlines . 'l.*/'
                        \ 'contains=VimtexTocHelpKey,VimtexTocHelpLayerOn,VimtexTocHelpLayerOff'

            syn  match VimtexTocHelpKey /<\S*>/ contained
            syn  match VimtexTocHelpKey /^\s*[-+<>a-zA-Z\/]\+\ze\s/ contained
                        \ contains=VimtexTocHelpKeySeparator
            syn  match VimtexTocHelpKey /^Layers:\s*\zs[-+<>a-zA-Z\/]\+/ contained
            syn  match VimtexTocHelpKeySeparator /\// contained

            syn  match VimtexTocHelpLayerOn /\w\++/ contained
                        \ contains=VimtexTocHelpConceal
            syn  match VimtexTocHelpLayerOff /(hidden)/ contained
            syn  match VimtexTocHelpLayerOff /\w\+-/ contained
                        \ contains=VimtexTocHelpConceal
            syn  match VimtexTocHelpConceal /[+-]/ contained conceal

            hi link VimtexTocHelpKeySeparator VimtexTocHelp
        en

        exe  'syntax match VimtexTocTodo'
                    \ '/\v\s\zs%('
                    \   . toupper(join(keys(g:vimtex_toc_todo_labels), '|')) . '): /'
                    \ 'contained'

        syn  match VimtexTocInclPath /.*/ contained

        syn  match VimtexTocIncl     /\w\+ incl:/ contained
                                    \ nextgroup=VimtexTocInclPath

        syn  match VimtexTocLabelsSecs #\v(chap|(sub)*sec):.*$# contained
        syn  match VimtexTocLabelsEq   /eq:.*$/           contained
        syn  match VimtexTocLabelsFig  /fig:.*$/          contained
        syn  match VimtexTocLabelsTab  /tab:.*$/          contained

        syn  cluster VimtexTocTitleStuff add=VimtexTocIncl,
                                   \VimtexTocTodo,
                                   \VimtexTocLabelsSecs,
                                   \VimtexTocLabelsEq,
                                   \VimtexTocLabelsFig,
                                   \VimtexTocLabelsTab,
                                   \@Tex

        syn  match VimtexTocTitle /.*$/ contained transparent
                    \ contains=@VimtexTocTitleStuff

        syn  match VimtexTocNum /\v(([A-Z]+>|\d+)(\.\d+)*)?\s*/ contained
                    \ nextgroup=VimtexTocTitle

        syn  match VimtexTocHotkey /\[[^] ]\+\]\s*/ contained
                    \ nextgroup=VimtexTocNum

        syn  match VimtexTocSecLabel /^L\d / contained conceal
                    \ nextgroup=VimtexTocHotkey,VimtexTocNum,VimtexTocTitle

        syn  match VimtexTocSec0 /^L0.*/     contains=VimtexTocSecLabel
        syn  match VimtexTocSec1 /^L1.*/     contains=VimtexTocSecLabel
        syn  match VimtexTocSec2 /^L2.*/     contains=VimtexTocSecLabel
        syn  match VimtexTocSec3 /^L3.*/     contains=VimtexTocSecLabel
        syn  match VimtexTocSec4 /^L[4-9].*/ contains=VimtexTocSecLabel
    endf



    "
    " Print the TOC entries
    "
    fun! s:toc.print_help() abort dict
        let self.help_nlines = 0
        if !self.show_help | return | endif

        let help_text = [
                    \ '<Esc>/q  Close',
                    \ '<Space>  Jump',
                    \ '<Enter>  Jump and close',
                    \ '      r  Refresh',
                    \ '      h  Toggle help text',
                    \ '      t  Toggle sorted TODOs',
                    \ '    -/+  Decrease/increase ToC depth (for content layer)',
                    \ '    f/F  Apply/clear filter',
                    \]

        if self.layer_status.content
            call add(help_text, '      s  Hide numbering')
        en
        call add(help_text, '')

        let l:first = 1
        let l:frmt = printf('%%-%ds',
                        \ 2 + max(  map(values(self.layer_keys),   'strlen(v:val)')    )
                      \)
        for [layer, status] in items(self.layer_status)
            call add(help_text,
                        \ (l:first ? 'Layers:  ' : '         ')
                        \ . printf(l:frmt, self.layer_keys[layer])
                        \ . layer . (status ? '+' : '- (hidden)'))
            let l:first = 0
        endfor

        call append('$', help_text)
        call append('$', '')

        let self.help_nlines += len(help_text) + 1
    endf


    fun! s:toc.print_entries() abort dict
        call self.set_number_format()

        for entry in self.get_visible_entries()
            call self.print_entry(entry)
        endfor
    endf


    fun! s:toc.print_entry(entry) abort dict
        "\ let output = '  ' ->repeat(a:entry.level)
        "\ let output = 'L' . a:entry.level . ' '
        let output = ''

        if self.hotkeys_enabled
            let output .= printf('%S  ', a:entry.hotkey)
        en

        if self.indent_levels
            let output .= repeat('    ', a:entry.level)
        en

        if self.show_numbers
            let number = a:entry.level >= self.tocdepth + 2 ? ''
                        \ : strpart(self.print_number(a:entry.number),
                        \           0, self.number_width - 1)
            let output .= printf(self.number_format, number)
        en

        let output .= a:entry.title

        call append('$', output)
    endf


    fun! s:toc.print_number(number) abort dict
        if empty(a:number) | return '' | endif
        if type(a:number) == v:t_string | return a:number | endif

        if get(a:number, 'part_toggle')
            return s:int_to_roman(a:number.part)
        en

        let number = [
                    \ a:number.chapter,
                    \ a:number.section,
                    \ a:number.subsection,
                    \ a:number.subsubsection,
                    \ a:number.subsubsubsection,
                    \ ]

        " Remove unused parts
        while len(number) > 0 && number[0] == 0
            call remove(number, 0)
        endwhile
        while len(number) > 0 && number[-1] == 0
            call remove(number, -1)
        endwhile

        " Change numbering in frontmatter, appendix, and backmatter
        if self.topmatters > 1
                    \ && (a:number.frontmatter || a:number.backmatter)
            return ''
        elseif a:number.appendix
            let number[0] = nr2char(number[0] + 64)
        en

        return join(number, '.')
    endf


    fun! s:toc.set_number_format() abort dict
        let number_width = 0
        for entry in self.get_visible_entries()
            let number_width = max([number_width, strlen(self.print_number(entry.number)) + 1])
        endfor

        let self.number_width = self.layer_status.content
                    \ ? max([0, min([2*(self.tocdepth + 2), number_width])])
                    \ : 0
        let self.number_format = '%-' . self.number_width . 's'
    endf



    "
    " Interactions with TOC buffer/window
    "
    fun! s:toc.activate_current(close_after) abort dict "{{{1
        let n = vimtex#pos#get_cursor_line() - 1
        if n < self.help_nlines | return {} | endif

        let l:count = 0
        for l:entry in self.get_visible_entries()
            if l:count == n - self.help_nlines
                return self.activate_entry(l:entry, a:close_after)
            en
            let l:count += 1
        endfor

        return {}
    endf


    fun! s:toc.activate_hotkey(key) abort dict "{{{1
        for entry in self.entries
            if entry.hotkey ==# a:key
                return self.activate_entry(entry, 1)
            en
        endfor

        return {}
    endf


    fun! s:toc.activate_entry(entry, close_after) abort dict "{{{1
        let self.prev_index = vimtex#pos#get_cursor_line()
        let l:vimtex_main = get(b:vimtex, 'tex', '')

        " Save toc winnr info for later use
        let toc_winnr = winnr()

        " Return to calling window
        call win_gotoid(self.winid_prev)

        " Get buffer number, add buffer if necessary
        let bnr = bufnr(a:entry.file)
        if bnr == -1
            exe  'badd ' . fnameescape(a:entry.file)
            let bnr = bufnr(a:entry.file)
        en

        " Set bufferopen command
        "   The point here is to use existing open buffer if the user has turned on
        "   the &switchbuf option to either 'useopen' or 'usetab'
        let cmd = 'buffer! '
        if &switchbuf =~# 'usetab'
            for i in range(tabpagenr('$'))
                if index(tabpagebuflist(i + 1), bnr) >= 0
                    let cmd = 'sbuffer! '
                    break
                en
            endfor
        elseif &switchbuf =~# 'useopen'
            if bufwinnr(bnr) > 0
                let cmd = 'sbuffer! '
            en
        en

        " Open file buffer
        exe  'keepalt' cmd bnr

        " Go to entry line
        if has_key(a:entry, 'line')
            call vimtex#pos#set_cursor(a:entry.line, 0)
        en

        " If relevant, enable VimTeX stuff
        if get(a:entry, 'link', 0) && !empty(l:vimtex_main)
            let b:vimtex_main = l:vimtex_main
            call vimtex#init()
        en

        " Ensure folds are opened
        norm! zv

        " Keep or close toc window (based on options)
        " Note: Ensure alternate buffer is restored
        if a:close_after && self.split_pos !=# 'full'
            call self.close()

        else
            try
                let @# = self.bufnr_alternate
            catch
                echom 'let @# = self.bufnr_alternate'
            endtry
        en

        " Allow user entry points through autocmd events
        if exists('#User#VimtexEventTocActivated')
            doautocmd <nomodeline> User VimtexEventTocActivated
        en
    endf


    fun! s:toc.toggle_help() abort dict "{{{1
        let l:pos = vimtex#pos#get_cursor()
        if self.show_help
            let l:pos[1] = max([l:pos[1] - self.help_nlines, 1])
            call vimtex#pos#set_cursor(l:pos)
        en

        let self.show_help = self.show_help ? 0 : 1
        call self.refresh()
        call self.set_syntax()

        if self.show_help
            let l:pos[1] += self.help_nlines
            call vimtex#pos#set_cursor(l:pos)
        en
    endf


    fun! s:toc.toggle_numbers() abort dict "{{{1
        let self.show_numbers = self.show_numbers ? 0 : 1
        call self.refresh()
    endf


    fun! s:toc.toggle_sorted_todos() abort dict "{{{1
        let self.todo_sorted = self.todo_sorted ? 0 : 1
        call self.get_entries(1)
        call vimtex#pos#set_cursor(self.get_closest_index())
    endf


    fun! s:toc.toggle_type(type) abort dict "{{{1
        let self.layer_status[a:type] = !self.layer_status[a:type]
        for entry in self.entries
            if entry.type ==# a:type
                let entry.active = self.layer_status[a:type]
            en
        endfor
        call self.refresh()
    endf


    fun! s:toc.decrease_depth() abort dict "{{{1
        let self.tocdepth = max([self.tocdepth - 1, -2])
        call self.refresh()
    endf


    fun! s:toc.increase_depth() abort dict "{{{1
        let self.tocdepth = min([self.tocdepth + 1, 5])
        call self.refresh()
    endf


    fun! s:toc.filter() dict abort "{{{1
        let re_filter = input('filter entry title by: ')
        for entry in self.entries
            let entry.hidden = get(entry, 'hidden') || entry.title !~# re_filter
        endfor
        call self.refresh()
    endf


    fun! s:toc.clear_filter() dict abort "{{{1
        for entry in self.entries
            let entry.hidden = 0
        endfor
        call self.refresh()
    endf



    "
    " Utility functions
    "
    fun! s:toc.get_closest_index() abort dict
        let l:calling_rank = 0
        let l:not_found = 1
        for [l:file, l:lnum, l:line] in vimtex#parser#tex(b:vimtex.tex)
            let l:calling_rank += 1
            if l:file ==# self.calling_file && l:lnum >= self.calling_line
                let l:not_found = 0
                break
            en
        endfor

        if l:not_found
            return [0, get(self, 'prev_index', self.help_nlines + 1), 0, 0]
        en

        let l:index = 0
        let l:dist = 0
        let l:closest_index = 1
        let l:closest_dist = 10000
        for l:entry in self.get_visible_entries()
            let l:index += 1
            let l:dist = l:calling_rank - entry.rank

            if l:dist >= 0 && l:dist < l:closest_dist
                let l:closest_dist = l:dist
                let l:closest_index = l:index
            en
        endfor

        return [0, l:closest_index + self.help_nlines, 0, 0]
    endf


    fun! s:toc.position_save() abort dict
        let self.position = vimtex#pos#get_cursor()
    endf


    fun! s:toc.position_restore() abort dict
        if self.position[1] <= self.help_nlines
            let self.position[1] = self.help_nlines + 1
        en
        call vimtex#pos#set_cursor(self.position)
    endf




    fun! s:foldexpr(lnum) abort
        let pline = getline(a:lnum - 1)
        let cline = getline(a:lnum)
        let nline = getline(a:lnum + 1)
        let l:pn = matchstr(pline, '^L\zs\d')
        let l:cn = matchstr(cline, '^L\zs\d')
        let l:nn = matchstr(nline, '^L\zs\d')

        " Don't fold options
        if cline =~# '^\s*$'
            return 0
        en

        if l:nn > l:cn
            return '>' . l:nn
        en

        if l:cn < l:pn
            return l:cn
        en

        return '='
    endf


    fun! s:foldtext() abort
        let l:line = getline(v:foldstart)[3:]
        if b:toc.todo_sorted
                    \ && l:line =~# '\v%(' . join(keys(g:vimtex_toc_todo_labels), '|') . ')'
            return substitute(l:line, '\w+\zs:.*', 's', '')
        el
            return l:line
        en
    endf



    fun! s:int_to_roman(number) abort
        let l:number = a:number
        let l:result = ''
        for [l:val, l:romn] in [
                    \ ['1000', 'M'],
                    \ ['900', 'CM'],
                    \ ['500', 'D'],
                    \ ['400', 'CD' ],
                    \ ['100', 'C'],
                    \ ['90', 'XC'],
                    \ ['50', 'L'],
                    \ ['40', 'XL'],
                    \ ['10', 'X'],
                    \ ['9', 'IX'],
                    \ ['5', 'V'],
                    \ ['4', 'IV'],
                    \ ['1', 'I'],
                    \]
            while l:number >= l:val
                let l:number -= l:val
                let l:result .= l:romn
            endwhile
        endfor

        return l:result
    endf


    fun! s:base(n, k) abort
        if a:n < a:k
            return [a:n]
        el
            return add(s:base(a:n/a:k, a:k), a:n % a:k)
        en
    endf


