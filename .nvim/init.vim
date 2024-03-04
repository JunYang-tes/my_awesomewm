autocmd BufWritePost *.fnl :! ./build.fnl
map <F5> :lua require('FTerm').scratch({ cmd = 'cd widgets && cargo build --release' })<cr>
map <F6> :lua require('FTerm').scratch({ cmd = 'cd widgets && cargo build ' })<cr>
