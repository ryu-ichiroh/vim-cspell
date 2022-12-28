let g:cspell#bad_words = []

function s:lint_callback(...)
  let words = []
  if has('nvim')
    let words = a:2
  else
    let words = [trim(a:2)]
  endif

  for word in words
    if (word == '' || word =~ '^CSpell: .*$')
      return
    endif
    call add(g:cspell#bad_words, word)
  endfor
endfunction

function s:lint_on_close(...)
  call spelunker#words#highlight(g:cspell#bad_words)
  let g:cspell#bad_words = []
endfunction

function cspell#lint()
  let cmd = s:get_command()
  let full_path = fnamemodify(expand('%'), ':p')
  let command = cmd . ' lint --no-color --no-progress --words-only --unique ' . full_path . ' 2>&1'
  if has('nvim')
    call jobstart(command, { "on_stdout": function("s:lint_callback"), "on_exit": function("s:lint_on_close")})
  else
    call job_start(command, { "callback": "s:lint_callback", "close_cb": "s:lint_on_close", "mode": "raw"})
  endif
endfunction

function! s:get_command() abort
  if exists('g:cspell#command')
    return g:cspell#command
  elseif executable('cspell')
    return 'cspell'
  elseif executable('cspell-cli')
    return 'cspell-cli'
  else
    throw 'Please install "cspell" from https://cspell.org/docs/installation/'
  end
endfunction
