"============================================================================
"    Copyright: Copyright (c) 2017, konlux
"               All rights reserved.
"
"               Redistribution and use in source and binary forms, with or
"               without modification, are permitted provided that the
"               following conditions are met:
"
"               * Redistributions of source code must retain the above
"                 copyright notice, this list of conditions and the following
"                 disclaimer.
"
"               * Redistributions in binary form must reproduce the above
"                 copyright notice, this list of conditions and the following
"                 disclaimer in the documentation and/or other materials
"                 provided with the distribution.
"
"               * Neither the name of the {organization} nor the names of its
"                 contributors may be used to endorse or promote products
"                 derived from this software without specific prior written
"                 permission.
"
"               THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
"               CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
"               INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
"               MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
"               DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
"               CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
"               SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
"               NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
"               LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
"               HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
"               CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
"               OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
"               EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
" Name Of File: bufselect.vim
"  Description: Select a Buffer Vim Plugin
"   Maintainer: konlux (mail at konlux dot de)
" Last Changed: Monday, 07 Aug 2017
"      Version: See g:bufselect_version for version number.
"        Usage: This file should reside in the plugin directory and be
"               automatically sourced.
"
"               You may use the default keymappings of
"
"                 <Leader>ls  - Opens the bufselect window
"
"               Or you can override the defaults and define your own mapping
"               in your vimrc file by setting the g:BufSelectToggleKey
"               variable, for example:
"
"                 g:bufSelectToggleKey = "<F5>"
"
"                 or
"
"                 nmap <F5> :BufSelect
"
"               If you use the last option, you won't toggle the window with
"               that key.
"               Or you can use the command
"
"                 ":BufSelect" - Opens bufselect window
"
"               For more help see supplied documentation.
"      History: -
"=============================================================================
 
" Exit quickly if already running or when 'compatible' is set.
if exists("g:bufselect_version") || &cp
    finish
endif
 
" Version number
let g:bufselect_version = "0.1"
 
" Create command to start
command! BufSelect :call BufSelect()
 
" SetupVariable(variable, default)
" - checks if the variable is already set (in .vimrc for example)
" - if the variable is not set, the default value will be applied
function! s:SetupVariable(varname, default)
    if !exists(a:varname)
        if type(a:default) == 0
            execute "let ".a:varname." = ".a:default
        else
            execute "let ".a:varname." = ".string(a:default)
        endif
    endif
endfunction
 
" Setup global variables for customization
call s:SetupVariable("g:bufSelectOpenOnTop", 0)
call s:SetupVariable("g:bufSelectWindowLines", 10)
call s:SetupVariable("g:bufSelectToggleKey", "<leader>ls")
execute "nmap ".g:bufSelectToggleKey." <Esc>:call BufSelect()<CR>"
 
" Script variables
let s:bufSelectCurrentWindow=0
let s:RestoreWindowState=""
let s:bufSelectCurrentFileList=[]
 
" BufSelectEnter()
" - clear bufselects buffer keymap
" - close bufselcts window
" - restore the window layout
" - jump to the the window where bufselect was started
" - open the buffer in that window which was selected
function! BufSelectEnter()
    let l:file = s:bufSelectCurrentFileList[line(".") - 1]
    mapclear  <buffer>
    mapclear! <buffer>
    quit!
    execute s:RestoreWindowState
    execute s:bufSelectCurrentWindow . "wincmd w"
    execute "buffer!" . l:file
    set laststatus=2
    echo
endfunction
 
" BufSelectLeave()
" - clear bufselects buffer keymap
" - close bufselcts window
" - restore the window layout
" - jump to the the window where bufselect was started
function! BufSelectLeave()
    mapclear  <buffer>
    mapclear! <buffer>
    quit!
    execute s:RestoreWindowState
    execute s:bufSelectCurrentWindow . "wincmd w"
    set laststatus=2
    echo
endfunction
 
" BufSelect()
" - parse vims buffers command output
" - open bufselct window
" - print buffers command output and remember which
"   line represent which buffer-number
" - set keymap to disable normal vim commands or window-switches
function! BufSelect()
    echo
    let bt = &buftype
    if bt == "nofile" || bt == "nowrite" || bt == "acwrite"
        echo "BufSelect won't work out of this window!"
        return 0
    endif
    let s:RestoreWindowState = winrestcmd()
    let s:bufSelectCurrentFileList=[]
    let PrintFileList=[]
    let s:bufSelectCurrentWindow = winnr()
    let currentbuffer_idx = 0
    let idx = 1
    " get current buffer-list from vims buffers command
    redir => buffers_output
        silent buffers
    redir END
    " calculate the best width for filename
    let filewidth = 0
    let maxfilelen = 0
    let maxfilewidth = winwidth(s:bufSelectCurrentWindow) - 21
    for bufline in split(buffers_output, '\n')
        let bufwords = split(bufline, '\s *')
        if maxfilelen <= strlen(bufwords[-3])
            let maxfilelen = strlen(bufwords[-3])
        endif
    endfor
    if maxfilelen >= maxfilewidth
        let filewidth = maxfilewidth
    else
        let filewidth = maxfilelen
    endif
    "if filewidth <= 25
    "    echomsg "Your window is to small to show the buffers correctly."
    "endif
    " get bufnr, bufattributes, bufname and current line number
    for bufline in split(buffers_output, '\n')
        let bufnr = str2nr(substitute(strpart(bufline, 0, 3), ' ', '', 'g'))
        let bufattr = strpart(bufline, 4, 4)
        let bufwords = split(strpart(bufline, 8), '\s *')
        let bufname = bufwords[0]
        let buflnr = bufwords[2]
        " if filename is to long, strip the left side
        if strlen(bufname) > filewidth
            let s = strlen(bufname) - filewidth + 3
            let bufname = '.."'.strpart(bufname, s)
        endif
        let line = printf("%3s: %-4s %-".filewidth."s Line %4s", bufnr
                                                              \, bufattr
                                                              \, bufname
                                                              \, buflnr)
        call add(PrintFileList, line)
        call add(s:bufSelectCurrentFileList, bufnr)
        if bufname(bufnr) == bufname("%")
            let currentbuffer_idx = len(PrintFileList)
        endif
    endfor
    " open window and print the buffers filelist
    if !g:bufSelectOpenOnTop
        execute ":botright ".g:bufSelectWindowLines. " new"
    else
        execute ":topleft  ".g:bufSelectWindowLines. " new"
    endif
    let rc = append(0, PrintFileList)
    " set cursor and cursorline
    delete
    hi CursorLine cterm=NONE ctermbg=DarkBlue
    setlocal cursorline
    call setpos(".", [0, currentbuffer_idx, 1])
    " set buf-attributes to act like a command window
    setlocal nonumber
    setlocal buftype=nofile bufhidden=hide    nobuflisted  noswapfile nowrap
    setlocal foldcolumn=0   foldmethod=manual nofoldenable nospell
    setlocal readonly       nomodifiable
    " disable jump and ":" command key
    map  <buffer> <c-w> <Nop>
    map  <buffer> <F1>  <Nop>
    nnoremap <buffer> _ :
    nmap     <buffer> : <Nop>
    map <buffer> <Enter>               _call BufSelectEnter()<CR>
    map <buffer>  q                    _call BufSelectLeave()<CR>
    execute "map <buffer> ".g:bufSelectToggleKey." _call BufSelectLeave()<CR>"
    " we use the statusline for a little help message
    let w:stl = 'Press "Enter" to switch to the selected file '
    let w:stl.= 'or type "q" to quit'
    setlocal statusline=%!w:stl
endfunction
