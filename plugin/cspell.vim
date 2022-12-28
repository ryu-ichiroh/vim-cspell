if !exists('g:cspell#disabled')
  augroup CSpell
    autocmd!
    autocmd BufWinEnter,BufWritePost * call cspell#lint()
  augroup END
endif
