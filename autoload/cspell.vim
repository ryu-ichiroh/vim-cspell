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


let s:unknown_words_by_buf = {}

let s:latest_lint_job = 0

function! cspell#lint() abort
  let cmd = s:get_command() . ' 2>&1'

  let s:unknown_words_by_buf[bufnr()] = []
  let s:latest_lint_job = s:job_start(cmd, function('s:lint_callback'))
endfunction

function! cspell#get_unknown_words() abort
  let buf = bufnr()
  if has_key(s:unknown_words_by_buf, buf)
    return s:unknown_words_by_buf[buf]
  endif

  return []
endfunction

function! s:lint_callback(...) abort
  let lines = s:get_stdout(a:1)

  for line in lines
    let unknown_words = s:parse_line(line)
    if empty(unknown_words)
      return
    endif

    if has_key(s:unknown_words_by_buf, bufnr())
      call add(s:unknown_words_by_buf[bufnr()], unknown_words)
    else
      let s:unknown_words_by_buf[bufnr()] = [unknown_words]
    endif

  endfor

  if exists('#User#ChangeCSpellUnknownWord')
    doautocmd User ChangeCSpellUnknownWord
  endif
endfunction

function! s:parse_line(line) abort
  let matched = matchstr(a:line, ' - Unknown word \(.*\) Suggestions: [.*')
  if matched ==? ''
    return {}
  endif

  let unknown_words = matched[stridx(matched, '(')+1:stridx(matched, ')')-1]
  let suggestions = map(split(matched[stridx(matched, '[')+1:stridx(matched, ']')-1], ','), { _, v -> trim(v) })

  return {'unknown_word': unknown_words, 'suggestions': suggestions}
endfunction

function! s:get_command() abort
  let full_path = fnamemodify(expand('%'), ':p')
  let args = ' --no-color --no-progress --no-summary --show-suggestions '
  if exists('g:cspell#command')
    return g:cspell#command . args . full_path
  endif

  let cmd = s:get_command_path()
  return cmd . ' lint --no-gitignore --dot --unique' . args . full_path
endfunction

function! s:get_command_path() abort
  if executable('cspell')
    return 'cspell'
  elseif executable('cspell-cli')
    return 'cspell-cli'
  else
    throw 'CSpell not found'
  endif
endfunction


let s:stdout_by_job = {}

function! s:job_start(cmd, callback) abort
  return cspell#job#start(a:cmd, {
  \ 'on_stdout': function('s:on_stdout'),
  \ 'on_exit': function(a:callback),
  \ })
endfunction

function! s:on_stdout(...) abort
  let job = a:1
  let stdout = a:2

  if !has_key(s:stdout_by_job, job)
    let s:stdout_by_job[job] = stdout
  else
    let s:stdout_by_job[job] = extend(s:stdout_by_job[job], stdout)
  endif
endfunction

function! s:get_stdout(job) abort
  if has_key(s:stdout_by_job, a:job)
    return filter(s:stdout_by_job[a:job], {k, v -> v != ''})
  endif

  return []
endfunction
