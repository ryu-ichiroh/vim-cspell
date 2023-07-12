# vim-cspell

vim-cspell is a plugin that checks spelling by using [cspell](https://cspell.org) for Vim/Neovim.

# Requirements

* [cspell-cli](https://cspell.org/docs/installation)
* [spelunker](https://github.com/kamykn/spelunker.vim)

# Installation

For [vim-plug](https://github.com/junegunn/vim-plug)
```vim

call plug#begin()
  ...

  Plug 'kamykn/spelunker.vim'
  Plug 'ryicoh/vim-cspell'

  ...
call plug#end()

let g:spelunker_disable_auto_group = 1
augroup MyCSpell
  au!
  au User ChangeCSpellUnknownWord call spelunker#words#highlight(map(cspell#get_unknown_words(), { _, k -> k.unknown_word }))
augroup end
```
