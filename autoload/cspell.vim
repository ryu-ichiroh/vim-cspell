let g:cspell#words = []

function s:lint_callback(channel, msg)
  let word = trim(a:msg)
  if (word =~ 'CSpell')
    return
  endif

  echomsg 'word' word
  call add(g:cspell#words, word)
endfunction

function s:lint_on_close(channel)
  call spelunker#words#highlight(g:cspell#words)
endfunction

function cspell#lint()
  let cmd = s:get_command()
  let full_path = fnamemodify(expand('%'), ':p')
  let g:cspell#words = []
  let command = cmd . ' lint --no-color --no-progress --words-only --unique ' . full_path . ' 1>&2'
  call job_start(command, { "callback": "s:lint_callback", "close_cb": "s:lint_on_close", "mode": "raw"})
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
