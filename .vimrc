" execute pathogen#infect()
set number

syntax on
filetype plugin indent on

" Fix backspace
" https://stackoverflow.com/a/11560415/381010
set backspace=indent,eol,start

" recognize strings containing a dash as a single word by appending the dash
" to the iskeyword variable
set iskeyword+=-

" = TABS =
" The width of a TAB is set to 4. Still it is a \t. It is just that. 
" vim will interpret it to be having a width of 4.
set tabstop=4
"" In case of auto-identing (or manually shifting code blocks), use this width
set shiftwidth=4
" Convert tabs to spaces
set expandtab

" = Search =
set ignorecase " ignore case during search
set smartcase  " unless we use capital letters in our searchstring
set incsearch  " incremental search
" use n for next match, N for previous match

" Change split behavior to vsplit below and hsplit to the right
set splitbelow
set splitright

"  = NerdTree =
" NerdTree specific customizations
" autocmd vimenter * NERDTree 
" Open NerdTree every time a file is opened
" autocmd vimenter * if !argc() | NERDTree | endif 
" Open NerdTree even if no file is specified
" Automatically close NerdTree if it is the only remaining window
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
" Automatically jump to the window that was just opened (so that it is active
" instead of NerdTree)
" autocmd VimEnter * wincmd p
"autocmd BufNew * wincmd p 
" Show hidden files by default
let NERDTreeShowHidden=1


" Set some convenience commands for NerdTree
" nnoremap -> first n -> normal mode (Vim also has visual and insert mode)
"          -> noremap -> don't recursively map this.
"             i.e noremap <key> <result> -> result won't resolve to foo
"             if there was already a 'map <result> foo' before.
let mapleader = ','
nnoremap <leader>d :NERDTreeToggle<CR>      " Toggle director
" Open current file in NERDTree
nnoremap <leader>f :NERDTreeFind<CR>
" Toggle linenumbers
nnoremap <leader>n :set invnumber<CR>



" Enclose word under cursor in double quotes
nnoremap <Leader>q ciw""<Esc>P

" Set ,c as shortcut for Conque
" nnoremap <leader>c :5split<CR>:ConqueTerm bash<CR>

" Help toggle function
let g:help_is_open = 0
function! ToggleHelp()
    if g:help_is_open
        let g:help_is_open = 0
        " jump to the last window (only works when help window is on the outer
        " right)
        "   execute: execute the string as vim command
        "   winnr("$"): get number of last window (outer right)
        "   . (dot): concat
        "   2wincmd w: jump to window 2
        execute winnr("$") . "wincmd w"
        q " Close the help windo
    else
        :vsplit ~/.vimhelp
        let g:help_is_open = 1
    endif
endfunction

nnoremap <leader>h :call ToggleHelp()<CR>

" Window switching
" Allow switching between windows using Ctrl + arrow keys
noremap <C-Left> <C-w>h
noremap <C-Down> <C-w>j
noremap <C-Up> <C-w>k
noremap <C-Right> <C-w>l

" Command Aliases (for common typos)
" http://stackoverflow.com/questions/3878692/aliasing-a-command-in-vim
fun! SetupCommandAlias(from, to)
    exec 'cnoreabbrev <expr> '.a:from
           \ .' ((getcmdtype() is# ":" && getcmdline() is# "'.a:from.'")'
           \ .'? ("'.a:to.'") : ("'.a:from.'"))'
endfun

call SetupCommandAlias("W", "w")
call SetupCommandAlias("Wq", "wq")
" call SetupCommandAlias("q", "q!")

" = Highlighting =
" Highlights trailing whitespace. 
" Note the use of the Syntax command instead of the map command as being
" used to indicate the 80 chars width. This is because there can only be a
" single map command.
" http://vim.wikia.com/wiki/Highlight_unwanted_spaces
highlight ExtraWhitespace ctermbg=darkgreen guibg=darkgreen
"match ExtraWhitespace /\s\+$/
autocmd Syntax * syn match ExtraWhitespace /\s\+$/

" Highlights chars in lines that go over 80 chars
" http://stackoverflow.com/questions/235439/vim-80-column-layout-concerns
highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%81v.\+/
