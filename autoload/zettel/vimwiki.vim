" source: https://stackoverflow.com/a/6271254/2467963
" get text of the visual selection
function! s:get_visual_selection()
  " Why is this not a built-in Vim script function?!
  let [line_start, column_start] = getpos("'<")[1:2]
  let [line_end, column_end] = getpos("'>")[1:2]
  let lines = getline(line_start, line_end)
  if len(lines) == 0
    return ''
  endif
  let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][column_start - 1:]
  return join(lines, "\n")
endfunction

" title and date to a new zettel note
function! zettel#vimwiki#template(title, date)
  if vimwiki#vars#get_wikilocal('syntax') ==? 'markdown'
    call append(line("1"), "---")
    call append(line("1"), "  - ")
    call append(line("1"), "tags: ")
    call append(line("1"), "date: " . a:date)
    call append(line("1"), "title: ". a:title)
    call append(line("1"), "---")
  else
    call append(line("1"), "%date " . a:date)
    call append(line("1"), "%title ". a:title)
  end
endfunction

function! zettel#vimwiki#new_zettel_name()
  return strftime(g:zettel_format)
endfunction

" use different link style for wiki and markdown syntaxes
function! zettel#vimwiki#format_link(file, title)
  if vimwiki#vars#get_wikilocal('syntax') ==? 'markdown'
    return '['.a:title.'](' . a:file . ')'
  else
    return '[[' . a:file . '|' . a:title .']]'
  endif
endfunction

" create new zettel note
" there is one optional argument, the zettel title
function! zettel#vimwiki#zettel_new(...)
  " name of the new note
  let format = zettel#vimwiki#new_zettel_name()
  let date_format = strftime("%Y-%m-%d %H:%M")
  echom("new zettel". format)
  let link_info = vimwiki#base#resolve_link(format)
  " detect if the wiki file exists
  let wiki_not_exists = empty(glob(link_info.filename)) 
  " let vimwiki to open the wiki file. this is necessary  
  " to support the vimwiki navigation commands.
  call vimwiki#base#open_link(':e ', format)
  " add basic template to the new file
  if wiki_not_exists
    call zettel#vimwiki#template(a:1, date_format)
  endif
endfunction

" crate zettel link from a selected text
function! zettel#vimwiki#zettel_new_selected()
  let name = zettel#vimwiki#new_zettel_name()
  let title = <sid>get_visual_selection()
  " replace the visually selected text with a link to the new zettel
  " \\%V.*\\%V. should select the whole visual selection
  execute "normal! :'<,'>s/\\%V.*\\%V./" . zettel#vimwiki#format_link( name, "\\0") ."\<cr>\<C-o>"
  call zettel#vimwiki#zettel_new(title)
endfunction

" Open zettel from fzf line
function! zettel#vimwiki#zettel_open(line)
  let filename = split(a:line,":")[0]
  let wikiname = split(filename,'\.')[0]
  call vimwiki#base#open_link(':e ', wikiname)
endfunction

" make new zettel from a file. the file contents will be copied to a new
" zettel, the original file contents will be replaced with the zettel filename
" use temporary file if you want to keep the original file
function! zettel#vimwiki#zettel_capture(wnum,...)
  let origfile = expand("%")
  execute ":set ft=vimwiki"
  " This probably doesn't work with current vimwiki code
  if a:wnum >= vimwiki#vars#number_of_wikis()
    echomsg 'Vimwiki Error: Wiki '.a:wnum.' is not registered in g:vimwiki_list!'
    return
  endif
  if a:wnum > 0
    let idx = a:wnum - 1
  else
    let idx = 0
  endif
  let format = zettel#vimwiki#new_zettel_name()
  " let link_info = vimwiki#base#resolve_link(format)
  let newfile = vimwiki#vars#get_wikilocal('path',idx ) . format . vimwiki#vars#get_wikilocal('ext',idx )
  " copy the captured file to a new zettel
  execute ":w " . newfile
  " delete contents of the captured file
  execute "normal! ggdG"
  " replace it with a address of the zettel file
  execute "normal! i" . newfile 
  execute ":w"
  " open the new zettel
  execute ":e " . newfile
endfunction

