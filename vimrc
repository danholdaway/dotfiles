set nu
set hlsearch        " highlight searches (hls)
set magic           " special characters, always keep on
set incsearch       " incremental search (is)
set ignorecase      " ignore case on searching (ic)
set smartcase       " acts smart about cases (scs)

autocmd BufRead *.f*,*.F* let fortran_have_tabs=1

highlight PUSHMAT ctermbg=grey guibg=grey
call matchadd('PUSHMAT', 'CALL PUSH', 11)
highlight POPMAT ctermbg=lightgrey guibg=lightgrey
call matchadd('POPMAT', 'CALL POP')                 

if has("gui_running")
    set guifont=Monaco:h13
    set lines=70
    set columns=170
endif 
