execute pathogen#infect()
set number
set tabstop=4
" vsplit .
"
" NerdTree specific customizations
autocmd vimenter * NERDTree 
" Open NerdTree every time a file is opened
autocmd vimenter * if !argc() | NERDTree | endif 
" Open NerdTree even if no file is specified
" Automatically close NerdTree if it is the only remaining window
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
" Automatically jump to the window that was just opened (so that it is active
" instead of NerdTree)
autocmd VimEnter * wincmd p
"autocmd BufNew * wincmd p 

" Highlights chars in lines that go over 80 chars
" http://stackoverflow.com/questions/235439/vim-80-column-layout-concerns
highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%81v.\+/
