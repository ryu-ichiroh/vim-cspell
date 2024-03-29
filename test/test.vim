set verbose=1

let s:suite = themis#suite('cspell')
let s:assert = themis#helper('assert')
let s:cspell_cli_timeout = 10000
let s:cspell_vars = themis#helper('scope').vars('autoload/cspell.vim')
let s:cspell_funcs = themis#helper('scope').funcs('autoload/cspell.vim')

let s:words1_called = 0
function! s:words1(...)
  let s:words1_called += 1
  let stdout = s:cspell_funcs.get_stdout(a:1)

  call s:assert.equals(len(stdout), 4, printf('stdout: %s', stdout))
endfunction

function! s:suite.job_start()
  call s:assert.equals(s:words1_called, 0, 's:words1 should not be called')

  let job_id = s:cspell_funcs.job_start(s:cspell_funcs.get_command_path() . ' --no-summary --no-progress test/data/words1.txt 2>&1', function('s:words1'))

  call cspell#job#wait([job_id], s:cspell_cli_timeout)

  call s:assert.equals(s:words1_called, 1, 's:words1 should be called once')
endfunction

function! s:suite.parse_line()
  let test_cases = [
    \ {
    \   'input': 'test/data/words1.txt:1:1 - Unknown word (helo) Suggestions: [helot, held, hell, helm, help]',
    \   'expect': {'bad_word': 'helo', 'suggestions': ['helot', 'held', 'hell', 'helm', 'help']},
    \ },
    \ {
    \   'input': 'test/data/words1.txt:3:1 - Unknown word (hewo) Suggestions: [hewn, hews, hero, Hero, hew]',
    \   'expect': {'bad_word': 'hewo', 'suggestions': ['hewn', 'hews', 'hero', 'Hero', 'hew']},
    \ },
    \ {
    \   'input': 'test/data/words1.txt:4:1 - Unknown word (heloo) Suggestions: [helot, helio, hello, Helot, holo]',
    \   'expect': {'bad_word': 'heloo', 'suggestions': ['helot', 'helio', 'hello', 'Helot', 'holo']},
    \ },
    \ {
    \   'input': 'test/data/words1.txt:4:7 - Unknown word (rldw) Suggestions: [rads, redd, rede, redo, reds]',
    \   'expect': {'bad_word': 'rldw', 'suggestions': ['rads', 'redd', 'rede', 'redo', 'reds']},
    \ },
    \ {
    \    'input': 'vim-vimlparser/autoload/vimlparser.vim:6352:36 - Unknown word (mlvc) Suggestions: [mlle, melva, Mlle, move, melic]',
    \   'expect': {'bad_word': 'mlvc', 'suggestions': ['mlle', 'melva', 'Mlle', 'move', 'melic']},
    \ }]
  for test_case in test_cases
    let actual = s:cspell_funcs.parse_line(test_case.input)
    call s:assert.equals(test_case.expect, actual)
  endfor

endfunction

function! s:suite.lint()
  call s:assert.equals(cspell#get_bad_words(), [])
  let g:called = 0
  augroup CSpellTest
    autocmd User CSpellBadWordChanged let g:called += 1
  augroup end

  edit test/data/words1.txt

  call s:assert.not_equals(s:cspell_vars.latest_lint_job, 0)
  call cspell#job#wait([s:cspell_vars.latest_lint_job], s:cspell_cli_timeout)
  call s:assert.equals(g:called, 1, 'autocmd CSpellBadWordChanged should be triggered')

  let expect = [{'bad_word': 'helo', 'suggestions': ['halo', 'held', 'hell', 'helm', 'help']}, {'bad_word': 'hewo', 'suggestions': ['hero', 'hewn', 'hews', 'Hero', 'hew']}, {'bad_word': 'heloo', 'suggestions': ['helio', 'hello', 'helot', 'Helot', 'holo']}, {'bad_word': 'rldw', 'suggestions': ['rads', 'redd', 'rede', 'redo', 'reds']}]
  let actual = cspell#get_bad_words()
  call s:assert.equals(actual, expect)
endfunction
