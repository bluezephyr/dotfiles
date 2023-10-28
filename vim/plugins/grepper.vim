Plug 'mhinz/vim-grepper'

let g:grepper = {}
let g:grepper.tools = ['grep', 'git', 'rg']

nnoremap <leader>* :Grepper -cword -noprompt<cr>

