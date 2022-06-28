# Documentation


The goal of this document is to help developers (and curious users)
to understand the structure of the plugin and how it works.

It should essentially provide a useful and quick overview of the most important files and directories.
See also `:help vimtex-code` for some related information.

    The VimTeX code is based on
    the |autoload| feature of vim.
    For each new latex buffer,
        the function *vimtex#init* initializes a state variable
        as well as buffer local mappings and
        commands,
    all based on  the desired options (see |vimtex-options|).

    The main init function calls `vimtex#mymodule#init_buffer` for each submodule,
    if it exists.
        This function should take care of defining buffer local mappings,
                commands,
                and autocommands.

    The state variable
    is a |Dictionary| that contains data that
    is specific to a single ¿LaTeX project¿.
    Such a project may consist of several buffers
    for different files
    if the project is a multi-file project (see |vimtex-multi-file|).
    A submodule may add to the state during initialization with `vimtex#mymodule#init_state`,
    which takes the ¿state object¿ as a single argument.
                   一个dict 大量用self

    The command |:VimtexInfo| (  mapped to <localleader>li by default)
    will show the (relevant)  contents of the local state,
    as well as some auxiliary information that may be useful for debugging purposes.

    See also the supplementary high-level code documentation [0]
    for ¿more detailed¿  information about the VimTeX code.

    [0]: https://github.com/lervag/vimtex/blob/master/DOCUMENTATION.md


The table of contents has the same structure as the essential file structure of VimTeX.
E.g.,
if you want to know something about `vimtex/autoload/vimtex/somefile.vim`,
then you can lookup the path in the table of contents and click on it.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN ¿doctoc¿ TO UPDATE -->


- [ftplugin](#ftplugin)
- [syntax](#syntax)
- [indent](#indent)
- [after/ftplugin](#afterftplugin)
- [autoload](#autoload)
  - [vimtex.vim](#vimtexvim)
  - [vimtex](#vimtex)
    - [state.vim](#statevim)
    - [delim.vim](#delimvim)
    - [cmd.vim](#cmdvim)
    - [cache.vim](#cachevim)
    - [compiler.vim](#compilervim)
    - [compiler](#compiler)
    - [debug.vim](#debugvim)
    - [complete.vim](#completevim)
      - [tools](#tools)
    - [context.vim](#contextvim)
    - [fold.vim](#foldvim)
    - [parser.vim](#parservim)
    - [qf.vim](#qfvim)
    - [syntax](#syntax-1)
    - [text\_obj.vim](#text%5C_objvim)
    - [view.vim](#viewvim)
  - [health/vimtex.vim](#healthvimtexvim)
  - [unite/sources/vimtex.vim](#unitesourcesvimtexvim)
- [rplugin/python3/denite/source/vimtex.py](#rpluginpython3denitesourcevimtexpy)
- [test](#test)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# ftplugin
    VimTeX provides a filetype plugin for the `tex` and `bib` filetypes.
    These scripts are the main entry points
    for the ´bulk functionalities´ of VimTeX.
    They are both very simple:
        they ensure that  the user wants to load VimTeX,
        then they execute the function
        `vimtex#init()` from [`autoload/vimtex.vim`](#vimtexvim).

# syntax

# indent
    this feature is also a special concept with an entry point under the `indent/` directory,
    see `:help indent-expression`.
    The main purpose of `indent/tex.vim` and `indent/bib.vim`
        is to provide functions like `VimtexIndent()`
            that are used with the  `:help 'indentexpr'` option.

# after/ftplugin
    Currently,
        there's only one script `after/ftplugin/tex.vim`.
    This is used to make sure that VimTeX loaded successfully and that
    there're no conflicts with  other plugins such as ´LaTeX-Box´.

# autoload
    the bulk VimTeX code is not sourced unless necessary.
    It may also be instructive to read
    [this chapter](https://learnvimscriptthehardway.stevelosh.com/chapters/42.html)
    ## vimtex.vim
        This file defines the main entry point `vimtex#init()`,
        which is responsible  for
        loading all of the VimTeX functionalities, except:

            * syntax highlighting is loaded from `syntax/tex.vim`
            * indentation is loaded from `indent/tex.vim`

        The main initialization function calls `vimtex#mymodule#init_buffer()` for each submodule,
        if it exists.
        This function should take care of
            defining buffer  local mappings, commands, and autocommands for the respective submodule.

        The initialization function also ensures that the current buffer
        is coupled with a corresponding state dictionary,
        see [autoload/vimtex/state.vim](#statevim).

    ## vimtex

        This directory holds the bulk of the VimTeX source code.
        Each `.vim` file represents a separate ¿submodule¿ that may provide one or more of the following:

            * a functional API that is used in other parts of VimTeX
            * buffer functionalities (mappings, commands, and/or autocommands)
            * state data

        ### state.vim
            The VimTeX state variable is a dictionary that contains data specific to a single LaTeX project.
            A project may consist of several buffers for different files,
            A submodule may add to the state
                during initialization with `vimtex#mymodule#init_state(state)`,

        ### delim.vim

            This file defines an API and some buffer mappings for detecting and
            manipulating the surrounding delimiters.

            The API is mostly based on the function `vimtex#delim#get_surrounding(type)`.

            The following is a simple example to detect the surrounding environment.
            Let  `|` denote the cursor position:

                ```tex
                \begin{Environment}
                  Some awesome | text
                \end{Environment}
                ```

            Example code for working with the environment delimiter:

                ```vim
                let [l:open, l:close] = vimtex#delim#get_surrounding('env_tex')
                                        " return values are list of dictionaries

                " Empty dicts mean we did not find a surrounding environment
                if empty(l:open) | return | endif

                " The dicts have several attributes, the most important are probably these:
                echo l:open.name
                echo l:open.lnum
                echo l:open.cnum
                ```

        ### cmd.vim
            This file defines an API and some buffer mappings for detecting and
            manipulating LaTeX commands.

            The main API relies on the functions `vimtex#cmd#get_*(...)`, e.g.
            `vimtex#cmd#get_current()`.
            A simple example usage:

            ```vim

                let l:cmd = vimtex#cmd#get_current()
                if empty(l:cmd) | return | endif

                echo l:cmd.name
                echo l:cmd.pos_start
                echo l:cmd.pos_end
                echo l:cmd.args
                echo l:cmd.opts
            ```

        ### cache.vim
            This file implements an API for creating and
            accessing caches that can be both
            volatile and persistent,
            as well as project and buffer local.

            Here's an example of how to use a cache.

            ```vim
            function VimTeXCacheExample()
              " create a new cache (if the name doesn't exist yet)
              " with an attribute 'number'. So the cache would be like that:
              "
              "   let l:test = {
              "   'number' = 10,
              "   }
              let l:my_cache = vimtex#cache#open('cache_name', {'number' : 10})

              " change the value in you cache
              let l:my_cache['number'] = 9001

              " will print '9001'
              echo l:my_cache['number']

              " save your changes
              " In general it'll be saved in your `$XDG_CACHE_HOME/vimtex/` directory
              " (normally '~/.cache/vimtex') in the appropriate tex-file where you accessed
              " cache file.
              call vimtex#cache#close('cache_name')
            endfunction
            ```

        ### compiler.vim
            Defines an API for interacting with LaTeX compiler backends.
            Defines the main compiler mappings and commands (e.g. `:VimtexCompile`).

            Each supported backend is defined in separated scripts under
                    `vimtex/autoload/vimtex/compiler/*.vim`.
                These scripts provide  `vimtex#compiler#mycompiler#init()`,
                which is used to initialize a particular  backend
                    it should return a dictionary object
                        that will be part of the VimTeX  state.

            The main compiler API essentially connects to the specified backend.
             if  one uses the default `latexmk` backend,
                then the top level  `vimtex#compiler#start()` function will essentially call the
                `s:compiler_nvim.start_single()`
            from
                `vimtex/autoload/vimtex/compiler/latexmk.vim`.

        ### debug.vim
            This standalone script defines a convenience function for internal debugging:
            `vimtex#debug#stacktrace()` parses the stacktrace from the `v:throwpoint`
            variable
            If this does not exist,
            then we forcibly create it and remove the top element.
            You can try this code as  an example:

            ```vim
            " Save as test.py
                function! Test() abort
                try
                    throw "Nasty error message is here "
                catch
                    call vimtex#debug#stacktrace(1)
                endtry
                endfunction
            ```

            Now type `:call Test()`,
            and the quickfix window should pop up with the
            specified error message and the location of the error.

        ### complete.vim
            This script defines the main completion API:
                `vimtex#complete#omnifunc(...)`.
                See `:help complete-functions` for details on how omnifunctions work.

            The function is relatively advanced and
            allows different completion mechanisms
            for different contexts.

            The `complete/` subdirectory contains simple files that lists keywords defined
            for specific packages or classes.
            These files are used by
                the command and
                environment completers.

            The `complete/tools` directory includes a large map between
                LaTeX commands and unicode glyphs,
                like `\alpha -> α` and `\beta -> β`.
                This is used to enrich the  keywords lists under `complete/` to add more fancy completion menus.

        ### context.vim
            This script provides a context menu feature
                (`:help :VimtexContextMenu`).
            Each script under `autoload/vimtex/context/*.vim` defines a specific context and
            its related actions.
            See  [here](https://github.com/lervag/vimtex/pull/1961#issuecomment-795476750) for
                a more detailed description of how this is implemented.

            For instance,
                the context `context/cite.vim` defines a citation context
                (see  `:help vimtex-context-citation`).

        ### fold.vim
        This defines the fold functions for VimTeX.
        An example of how a folded document may look like:
            ![folding example](https://github.com/lervag/vimtex-media/blob/main/img/folding.png)

        VimTeX defines a custom fold expression,
        see `:help fold-expr`.
        The  `vimtex#fold#init_state` function will apply folding as per the related
        configuration
        (see `:help vimtex-folding`).

        The fold expression is modularized to allow a relatively high degree of
        customizability.
        Each type is defined in its separate file,
        e.g.
            `autoload/vimtex/fold/envs.vim` for folding of environments.

        ### parser.vim
        A lot of VimTeX functionalities relies on some type of parsing.
        This module  defines an API for various parsers,
        both for TeX files and other filetypes
        (e.g. `aux` and `bib`),
        as well as some specific types of
        arser (e.g. `toc`  for parsing TeX files for a table of contents).

        The code for each parser is defined in sub modules,
            e.g. `parser/bib.vim`.

        The `vimcomplete.bst` file is used by `parser/bib.vim` in the
        `s:parse_with_bibtex()` function.
        It is used to convert a `.bib` file to  a `.bbl` file with `bibtex`
            this is useful because the `.bbl` file generated
            with this `.bst` file is very easy to parse.

        ### toc.vim

        ![toc example](https://github.com/lervag/vimtex-media/blob/main/img/toc.png)

        ### qf.vim
        This submodule defines functions and buffer mappings to
        parse log files and  similar and

        The functions are used e.g. by callbacks from the compilers,
        if  supported and enabled,
            to automatically parse log files and display potential  errors after compilation.

        The files `vimtex/autoload/vimtex/qf/*.vim` define different types of log
        parsers.
        E.g., `qf/bibtex.vim` is used to parse `.blg` files for BibTeX related
        warnings and errors,
        and `qf/latexlog.vim` parses `.log` files for LaTeX  warnings and errors.
        `qf/pulp.vim` defines an alternative log parser that can
        be used instead of `latexlog.vim`.
            See also `:help g:vimtex_quickfix_method`.

        Here's an example of the quickfix list generated by the `qf/latexlog.vim`
        script:

        ![quickfix example](https://github.com/lervag/vimtex-media/blob/main/img/quickfix.png)

        ### syntax.vim
            This script implements some convenience functions for the bulk VimTeX code.
            This may be ¿counter intuitive¿, so be warned.

            The idea is that other parts of VimTeX may rely on the syntax state,
            to  ¿determine if a position is within math mode¿
                (`vimtex#syntax#in_mathzone(...)`).

            The actual syntax rules are defined in the scripts under `syntax/*.vim`.

        ### syntax
            This subdirectory contains the main syntax highlighting scripts.
            The entry  point for the syntax scripts are  the top level  [`syntax/tex.vim`](#syntax).
            However,
            as most of the code,
            the bulk source is  defined
            in the autoloaded functions.

            `syntax/core.vim` implements the core syntax rules,
            whereas the  scripts under `syntax/p/` define package specific syntax rules.

        ### text\_obj.vim
            This submodule defines text objects,
            see `:help text-objects`.
            Buffer local  mappings are created during initialization.

            The module allows to use different backends,
            including the popular  [`targets.vim`](https://github.com/wellle/targets.vim).

        ### view.vim
            This submodule defines the main view API and buffer mappings/commands.
            That is,
            mappings and commands to open a PDF viewer for the compiled LaTeX document.

            The desired PDF viewer is specified  with `g:vimtex_view_method` variable,
            and  the specified viewer is initialized from `view/VIEWER.vim` (e.g.
            `view/zathura.vim`).
            This  mainly does the following for a given VimTeX  state:
            ```vim
                let a:state.viewer = vimtex#view#{g:vimtex_view_method}#new()
                    ```

            That is, if `g:vimtex_view_method` is `zathura`,
            then this calls  `vimtex#view#zathura#new()`.
            The `new()` method should return a dictionary  object with e.g. a `.view()` method
            that is used to open a file with the  specified viewer.

    ## health/vimtex.vim
        VimTeX hooks into the `health.vim` framework provided by `neovim` (see `:help
        health`). This is a utility framework for performing health checks that may
        help users discover problems with e.g. configuration. VimTeX has a few checks
        for e.g. Vim versions and configuration validation.

        This is not relevant for regular Vim.

    ## unite/sources/vimtex.vim
        See `:help vimtex-unite`  for more info.

# rplugin/python3/denite/source/vimtex.py
        This script defines a VimTeX table-of-content source for the
        [denite.vim](https://github.com/Shougo/denite.nvim) plugin.
        See also `:help  vimtex-denite`.

# test

    This directory is used to,
    define tests for the VimTeX code.
    The tests are built on top of a ¿Makefile¿ based workflow.
    The `test/Makefile` runs all tests defined in sub directories named `test-...`.
    It is a fundamental requirement that all tests run with `make` from the top level `test` directory should pass for VimTeX to be deemed stable and
    fully functional.

    The `test/` directory also contains some simple LaTeX and VimTeX configuration
    examples under `test/example-...`,
    as well as some issue specific test files  under `issues/ISSUE-NUMBER`.

DIY_again
DIY_2  vim:filetype=help:syntax=help:
