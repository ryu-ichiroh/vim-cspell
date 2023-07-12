" Copyright 2022 Ryuichiroh Ikeuchi. All rights reserved.
"
" Licensed under the Apache License, Version 2.0 (the "License");
" you may not use this file except in compliance with the License.
" You may obtain a copy of the License at
"
"     http://www.apache.org/licenses/LICENSE-2.0
"
" Unless required by applicable law or agreed to in writing, software
" distributed under the License is distributed on an "AS IS" BASIS,
" WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
" See the License for the specific language governing permissions and
" limitations under the License.


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
