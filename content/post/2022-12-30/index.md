---
# type: docs 
title: Neovim の設定集（2022年12月30時点）
date: 2022-12-30T16:48:00+09:00
featured: true
draft: false
toc: true
comment: true
tags: [備忘録, Neovim]
archives: 2022/12
---

## 前置き

WSL2 + Neovim + VSCode で使っていく予定だったのですが、Neovim をあれこれカスタマイズしていると Neovim が使いやすくなってきてメインエディタになりそうなので、これまでの設定をまとめてみようと思います。

順不同で色々なネタを扱っていて記事が長いですので、上記の目次で必要な個所を拾い読みしてください。


## アウトラインバッファの作成

{{% alert info %}}
2022年1月10日追記
{{% /alert %}}

このブログは、Go言語 で書かれた静的サイトジェネレーターの [The world’s fastest framework for building websites |Hugo](https://gohugo.io/) で構築しており、記事は Markdown で書いています。また、職場で細々と行っている勉強会の資料は、書籍制作向けのテキストマークアップ言語仕様、およびその変換システムである [Re:VIEW - Digital Publishing System for Books and eBooks](https://reviewml.org/) で作成しています。

どちらもそこそこ長い記事を書くことがあるのでアウトライン機能が欲しいのですが、プラグインはできる限り少なくしたいため、プラグイン無しでできるか挑戦したところ上手くいきましたので、方法を紹介します。

処理の大まかな流れは、`;o` キーをタイプしたらファイルタイプ毎の検索条件を用いて Vimgrep と Quickfix を実行し、その結果をカレントバッファの右半分に表示するというものです。

ただ、Neovim のデフォルトのファイルタイプに Re:VIEW は含まれていませんので、`~/.config/nvim/filetype.vim` に以下のコードを追加して、Re:VIEW のファイルタイプを登録します。

```vim
augroup filetypedetect
  " 拡張子 .re のファイルを Re:VIEW ファイルと判定
  au BufNewFile,BufRead *.re        setf review
augroup END
```

それから、Vimgrep と Quickfix を次のとおり組み合わせます。

1. Markdown と Re:VIEW の見出し部分を検索条件に設定した Vimgrep を実行
1. Vimgrep の結果を `copen` コマンドで表示
1. `wincmd L` コマンドで結果を右側に表示
1. 上記の処理を関数にまとめた上で `;o` キーバインドに割り当て

具体的なコードは次のとおりです。

```vim
function! CreateOutlineBuffer()
  if (&ft=='review')
    vimgrep /^=\+ / %
  elseif (&ft=='markdown')
    vimgrep /^#\+ / %
  endif
  copen
  wincmd L
endfunction

nnoremap <silent> ;o :<Cmd>call CreateOutlineBuffer()<CR><CR>
```

これで `;o` 次のスクリーンショットのようにアウトラインバッファを作成することができます。

{{< bsimage src="outlineBuffer.png" title="アウトラインバッファを表示" >}}

実際の動作は次の動画のとおりです。

{{< video src="runOutlineBuffer.mp4" type="video/webm" preload="auto" >}}


{{% alert info %}}
ちなみに、このアウトラインバッファは、今は開発が終了した Github 製エディタのプラグインの [t9md/atom-narrow: narrow something](https://github.com/t9md/atom-narrow) の見た目を模して設定しました。私はこのプラグインがお気に入りでしたので、見た目だけでも同じようにしたかったものです。
{{% /alert %}}

### 2022年1月10日追記

上記のコードには欠陥があり、次のウィンドウ配置で編集しているときにアウトラインを更新するために `;f` キーバインドをタイプすると画面配置が変わってしまいます。

```
アウトライン更新前
+────────────+────────────+
| Window A   | Window B   |
| (Doc)      | (Outline)  |
|            +────────────+
|            | Window C   |
|            | (Terminal) |
+────────────+────────────+
```

```
アウトライン更新後
+───────+────────+────────+
| Win A | Win C  | Win B  |
|       |        |        |
|       |        |        |
|       |        |        |
|       |        |        |
+───────+────────+────────+
```

この問題を解決するため、`;f` キーバインドをタイプしたときに Quickfix ウィンドウが存在しているか調査し、存在していればその時点のウィンドウ配置をいったん保存してからアウトラインを更新してウィンドウ配置を元に戻す方法に変更しました。

具体的なコードは次のとおりです。

```vim
function! CreateOutlineBuffer()
  let QuickfixWindowExists = QuickfixWindowExists()
  if QuickfixWindowExists == "true"
    let windowLayout = winsaveview()
    call DoVimgrep(&filetype)
    copen
    execute winrestview(windowLayout)
  else
    call DoVimgrep(&filetype)
    copen
    wincmd L
  endif
endfunction

function! QuickfixWindowExists() abort
  let bufferNoList = tabpagebuflist()
  for bufferNo in bufferNoList
    if getwininfo(bufwinid(bufferNo))['variables']['quickfix'] == 1
      return "true"
    endif
  endfor
  return "false"
endfunction

function! DoVimgrep(filetype) abort
  if (a:filetype=='review')
    vimgrep /^=\+ / %
  elseif (a:filetype=='markdown')
    vimgrep /^#\+ / %
  endif
endfunction

nnoremap <silent> ;o :<Cmd>call CreateOutlineBuffer()<CR><CR>
```

Quickfix ウィンドウの存在確認は `QuickfixWindowExists()` 関数で行っています。

まず、`tabpagebuflist()` 関数で編集中のタブにあるバッファの番号リストを取得します。そうしたら、その番号リストを `for` 文で順番に `bufwinid()` 関数に渡してウィンドウID を取得し、その ID を `getwininfo()` 関数に渡してウィンドウ情報を辞書のリストとして取得します。ウィンドウ情報にはそのウィンドウが Quickfix/Location ウィンドウかどうかを示す項目がありますので、その項目を `if` 文の条件に用いています。Quickfix ウィンドウは1つしか開くことができませんので、Quickfix ウィンドウが1つ見つかった時点で `"true"` を返して関数を終了します。

あとは、`QuickfixWindowExists()` 関数の返り値が `"true"` なら Quickfix ウィンドウが存在するので `winsaveview()` 関数を実行してウィンドウ配置の情報を取得して変数に格納します。それからアウトライン表示の `DoVimgrep()` 関数を実行してアウトラインを更新し、Ex コマンドの `winrestview` に先ほど格納したウィンドウ配置の情報を渡してウィンドウ配置を復元します。

なお、`cbuffer` コマンドを実行してアウトラインを更新する方法も試しましたが、行頭に `||` が追加されて Enter キーを押しても該当箇所にジャンプできなくなる症状を解消できなかったため、断念して上記の方法に切り替えました。

## 日本語テキストでの移動の効率化

Vim の `f{char}` コマンドを日本語で使う場合、`f` キーをタイプしてから IME をオンにして検索文字を入力する必要があり、非常に面倒くさいです。

そこで、[Vimで日本語編集時の f, t の移動や操作を楽にするプラグイン ftjpn を作りました](https://sasasa.org/vim/ftjpn/) をインストールして、`f,` や `f.` や `fg` のキーバインドで `、` や `。` や `が` に移動できるようにしました。

ソースコードを編集するときのような細やかな移動はできませんが、`、` や `。` や `が` に移動できるだけでも結構効率は上がりますので、このプラグインは便利なプラグインです。なお、私の設定は次のとおりです。

```vim
let g:ftjpn_key_list = [
    \ ['.', '。', '．'],
    \ [',', '、', '，'],
    \ ['g', 'が'],
    \ ['w', 'を'],
    \ ['h', 'は'],
    \ ['(', '（', '）'],
    \ [';', '！', '？'],
    \ ['[', '「', '『', '【'],
    \ [']', '」', '』', '】'],
    \ ]
```

なお、このプラグインを使い始めた当初、`,` や `.` は使えるのに `g` や `h` が使えなくて困っていましたが、作者に[相談](https://github.com/juro106/ftjpn/issues/1)して無事に使えるようになりました。あらためて御礼申し上げます。


## ddu.vim の導入

エディタ内蔵のファイラーがあると便利なので色々探したのですが、Vim 標準の Netrw は操作性が独特だったりサイドバーの幅の調整が難しかったりとイマイチ合わなかったので、思い切って [新世代のファイラー UI ddu-ui-filer](https://zenn.dev/shougo/articles/ddu-ui-filer) を導入しました。

最初は設定方法などがさっぱり分からず悪戦苦闘の連続でしたが、何とか使えるようになるととても便利で、手放せないプラグインになりそうです。

現在はファイラーに加えて、バッファリストとコマンド履歴の絞り込み＆選択にも使っています。特に、バッファリストの選択は便利な機能で、ターミナルで `nvim **.vim` や `nvim **.re` と入力して設定ファイルや Re:VIEW ファイルを一括して開いてバッファリストに読み込み、そのリストを `;b` キーバインドで呼び出してサクサク切り替えています。ついでに、リストから開くときに `Enter` だとカレントバッファに読み込み、`vo` でウィンドウを縦分割して読み込み、`vs` でウィンドウを水平分割して読み込むように設定しています。ただし、ここまで来るには悪戦苦闘の連続でした。

実際の設定とその解説を書けば他の人の役に立つと思うのですが、記事が一本書けそうな気がしますので、設定の解説は別の記事にします。そのため、ここでは実際の設定のみ掲載します。

```vim
let g:denops#deno = '/home/s-show/.deno/bin/deno'

call ddu#custom#patch_global({
\   'ui': 'filer',
\   'sources': [
\     {
\       'name': 'file',
\       'params': {},
\     },
\   ],
\   'sourceOptions': {
\     '_': {
\       'columns': ['filename'],
\     },
\     'command_history': {
\       'matchers': [ 'matcher_substring' ],
\     },
\     'buffer': {
\       'matchers': [ 'matcher_substring' ],
\     },
\   },
\   'kindOptions': {
\     'file': {
\       'defaultAction': 'open',
\     },
\     'command_history': {
\       'defaultAction': 'execute',
\     },
\   },
\   'uiParams': {
\     'filer': {
\       'sort': 'filename',
\       'split': 'floating',
\       'displayTree': v:true,
\       'previewVertical': v:true,
\       'previewWidth': 80,
\     }
\   },
\ })

autocmd FileType ddu-ff call s:ddu_my_settings()
function! s:ddu_my_settings() abort
  nnoremap <buffer><silent> <CR>
        \ <Cmd>call ddu#ui#ff#do_action('itemAction')<CR>
  nnoremap <buffer><silent> vo
        \ <Cmd>call ddu#ui#ff#do_action('itemAction', {'name': 'open', 'params': {'command': 'vsplit'}})<CR>
  nnoremap <buffer><silent> vs
        \ <Cmd>call ddu#ui#ff#do_action('itemAction', {'name': 'open', 'params': {'command': 'split'}})<CR>
  nnoremap <buffer><silent> <Space>
        \ <Cmd>call ddu#ui#ff#do_action('toggleSelectItem')<CR>
  nnoremap <buffer><silent> i
        \ <Cmd>call ddu#ui#ff#do_action('openFilterWindow')<CR>
  nnoremap <buffer><silent> q
        \ <Cmd>call ddu#ui#ff#do_action('quit')<CR>
endfunction

autocmd FileType ddu-ff-filter call s:ddu_filter_my_settings()
function! s:ddu_filter_my_settings() abort
  inoremap <buffer><silent> <CR>
  \ <Esc><Cmd>close<CR>
  nnoremap <buffer><silent> <CR>
  \ <Cmd>close<CR>
  nnoremap <buffer><silent> q
  \ <Cmd>close<CR>
endfunction

autocmd FileType ddu-filer call s:ddu_filer_my_settings()
function! s:ddu_filer_my_settings() abort
  nnoremap <buffer><silent><expr> <CR>
    \ ddu#ui#filer#is_tree() ?
    \ "<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'narrow'})<CR>" :
    \ "<Cmd>call ddu#ui#filer#do_action('itemAction')<CR>"
  nnoremap <buffer><silent><expr> vo
    \ ddu#ui#filer#is_tree() ?
    \ "<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'narrow'})<CR>" :
    \ "<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'open', 'params': {'command': 'vsplit'}})<CR>"
  nnoremap <buffer><silent> <Space>
        \ <Cmd>call ddu#ui#filer#do_action('toggleSelectItem')<CR>
  nnoremap <buffer><silent> <Esc>
    \ <Cmd>call ddu#ui#filer#do_action('quit')<CR>
  nnoremap <buffer> o
        \ <Cmd>call ddu#ui#filer#do_action('expandItem',
        \ {'mode': 'toggle'})<CR>
  nnoremap <buffer><silent> q
    \ <Cmd>call ddu#ui#filer#do_action('quit')<CR>
  nnoremap <buffer><silent> ..
    \ <Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'narrow', 'params': {'path': '..'}})<CR>
  nnoremap <buffer><silent> c
    \ <Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'copy'})<CR>
  nnoremap <buffer><silent> p
    \ <Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'paste'})<CR>
  nnoremap <buffer><silent> d
    \ <Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'delete'})<CR>
  nnoremap <buffer><silent> r
    \ <Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'rename'})<CR>
  nnoremap <buffer><silent> mv
    \ <Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'move'})<CR>
  nnoremap <buffer><silent> t
    \ <Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'newFile'})<CR>
  nnoremap <buffer><silent> mk
    \ <Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'newDirectory'})<CR>
  nnoremap <buffer><silent> yy
    \ <Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'yank'})<CR>
endfunction

" `;f` でファイルリストを表示する
nmap <silent> ;f <Cmd>call ddu#start({
\   'name': 'filer',
\   'uiParams': {
\     'filer': {
\       'search': expand('%:p')
\     }
\   },
\ })<CR>

" `;b` でバッファリストを表示する
nmap <silent> ;b <Cmd>call ddu#start({
\   'ui': 'ff',
\   'sources': [{'name': 'buffer'}],
\   'uiParams': {
\     'ff': {
\       'split': 'floating',
\     }
\   },
\ })<CR>

" `;c` でコマンドリストを表示する
nmap <silent> ;c <Cmd>call ddu#start({
\   'ui': 'ff',
\   'sources': [
\     {
\       'name': 'command_history',
\     },
\   ],
\   'uiParams': {
\     'ff': {
\       'split': 'floating',
\     },
\   },
\ })<CR>
```

ファイルリストなどの実際の表示は次のとおりです。

{{< bsimage src="dduFiler.png" title="ファイラーを表示" >}}
{{< bsimage src="dduBufferList.png" title="バッファリストを表示" >}}
{{< bsimage src="dduCommandHistoryList.png" title="コマンド履歴を表示" >}}

## ddc.vim の導入

自動補完機能を強化するため、上記の ddu.vim と同じ方が作成してる自動補完プラグインの [新世代の自動補完プラグイン ddc.vim](https://zenn.dev/shougo/articles/ddc-vim-beta) を導入しました。合わせて、自動補完をコマンドラインバッファでも有効にするため、[自動補完プラグイン ddc.vim + pum.vim](https://zenn.dev/shougo/articles/ddc-vim-pum-vim) も導入しました。こちらも導入は悪戦苦闘の連続でしたが、何とか自動補完ができるようになりました。

過去に入力したコマンドであれば、上記の ddu.vim のコマンド履歴表示でも対応可能なのですが、新規のコマンドはコマンドラインバッファで入力しないといけないですし、コマンド履歴表示は若干タイムラグがあるので、コマンドラインバッファでの自動補完は便利です。また、通常のファイル編集でも2文字入力すれば補完機能が発動しますので、便利に使っています。ただし、プログラミングで必須の LSP 周りの設定は全くできていないため、次はここに挑戦します。

なお、こちらも ddu.vim と同じく解説を書くと記事が一本書けそうな感じなので、ここでは実際のコードのみ掲載します。

```vim
"=======================================================================================
" ddc.nvim の設定
"=======================================================================================
"
call ddc#custom#patch_global('sources', ['around'])
call ddc#custom#patch_global('sourceOptions', {
      \ '_': {
      \   'matchers': ['matcher_head'],
      \   'sorters': ['sorter_rank']
      \ },
      \ 'around': {
      \   'mark': 'around'
      \ },
      \})


"=======================================================================================
" pum.nvim の設定
"=======================================================================================
"
call ddc#custom#patch_global('cmdlineSources', {
    \ ':': ['cmdline-history', 'cmdline', 'around'],
    \ '@': ['cmdline-history', 'input', 'file', 'around'],
    \ '>': ['cmdline-history', 'input', 'file', 'around'],
    \ '/': ['around', 'line'],
    \ '?': ['around', 'line'],
    \ '-': ['around', 'line'],
    \ '=': ['input'],
    \ })

call ddc#custom#patch_global('ui', 'pum')
"call ddc#custom#patch_global('completionMenu', 'pum.vim')
inoremap <silent><expr> <TAB>
      \ pum#visible() ? '<Cmd>call pum#map#insert_relative(+1)<CR>' :
      \ (col('.') <= 1 <Bar><Bar> getline('.')[col('.') - 2] =~# '\s') ?
      \ '<TAB>' : ddc#manual_complete()
inoremap <S-Tab> <Cmd>call pum#map#insert_relative(-1)<CR>
inoremap <C-n>   <Cmd>call pum#map#select_relative(+1)<CR>
inoremap <C-p>   <Cmd>call pum#map#select_relative(-1)<CR>
inoremap <C-y>   <Cmd>call pum#map#confirm()<CR>
inoremap <C-e>   <Cmd>call pum#map#cancel()<CR>
inoremap <PageDown> <Cmd>call pum#map#insert_relative_page(+1)<CR>
inoremap <PageUp>   <Cmd>call pum#map#insert_relative_page(-1)<CR>

call ddc#custom#patch_global('autoCompleteEvents', [
    \ 'InsertEnter', 'TextChangedI', 'TextChangedP',
    \ 'CmdlineEnter', 'CmdlineChanged',
    \ ])

nnoremap :  <Cmd>call CommandlinePre()<CR>:
nnoremap ;; <Cmd>call CommandlinePre()<CR>:

function! CommandlinePre() abort
  " Note: It disables default command line completion!
  cnoremap <Tab> <Cmd>call pum#map#insert_relative(+1)<CR>
  cnoremap <S-Tab> <Cmd>call pum#map#insert_relative(-1)<CR>
  cnoremap <C-n> <Cmd>call pum#map#insert_relative(+1)<CR>
  cnoremap <C-p> <Cmd>call pum#map#insert_relative(-1)<CR>
  cnoremap <C-y>   <Cmd>call pum#map#confirm()<CR>
  cnoremap <C-e>   <Cmd>call pum#map#cancel()<CR>

  " Overwrite sources
  if !exists('b:prev_buffer_config')
    let b:prev_buffer_config = ddc#custom#get_buffer()
  endif
  call ddc#custom#patch_buffer('cmdlinesources',
          \ ['neovim', 'around'])

  autocmd User DDCCmdlineLeave ++once call CommandlinePost()
  autocmd InsertEnter <buffer> ++once call CommandlinePost()

  " Enable command line completion
  call ddc#enable_cmdline_completion()
endfunction

function! CommandlinePost() abort
  silent! cunmap <Tab>
  silent! cunmap <S-Tab>
  silent! cunmap <C-n>
  silent! cunmap <C-p>
  silent! cunmap <C-y>
  silent! cunmap <C-e>

  " Restore sources
  if exists('b:prev_buffer_config')
    call ddc#custom#set_buffer(b:prev_buffer_config)
    unlet b:prev_buffer_config
  else
    call ddc#custom#set_buffer({})
  endif
endfunction

call ddc#enable()
```

実際の自動補完の様子は次のとおりです。

{{< bsimage src="ddcCommandLine.png" title="コマンドラインバッファでの補完表示" >}}
{{< bsimage src="ddcInputMode.png" title="インプットモードでの補完表示" >}}

## lualine.nvim の導入

ステータスバーにもっと多くの情報を表示するため、[nvim-lualine/lualine.nvim: A blazing fast and easy to configure neovim statusline plugin written in pure lua.](https://github.com/nvim-lualine/lualine.nvim) を導入しました。

設定は公式リポジトリの「Default configuration」とほぼ同じですが、右側の表示のセパレータを `` から `|` に変更し、また、ファイル名の表示をフルパス表示に変更しています。

IMEの状態を右側に表示しようとしましたが、カーソルを上下移動するたびに画面がちらつくうえ、動作が明らかに重くなったため断念しました。

```lua
lua << END
  require('lualine').setup {
    options = {
      icons_enabled = true,
      theme = 'nord',
      component_separators = { left = '', right = '|'},
      section_separators = { left = '', right = ''},
      disabled_filetypes = {
        statusline = {},
        winbar = {},
      },
      ignore_focus = {},
      always_divide_middle = true,
      globalstatus = true,
      refresh = {
        statusline = 1000,
        tabline = 1000,
        winbar = 1000,
      }
    },
    sections = {
      lualine_a = {'mode'},
      lualine_b = {'branch', 'diff', 'diagnostics'},
      lualine_c = {{ 'filename', file_status = true, path = 3 }},
      lualine_x = {'encoding', 'fileformat', 'filetype'},
      lualine_y = {'progress'},
      lualine_z = {'location'}
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {'filename'},
      lualine_x = {'location'},
      lualine_y = {},
      lualine_z = {}
    },
    tabline = {},ftjpnの動作状況

    winbar = {},
    inactive_winbar = {},
    extensions = {}
  }
END

" IMEの状態を取得する関数。動作に支障が出るくらい遅くなるため未使用
function! Get_ime_status()
  let b:ime_status=system('spzenhan.exe')
  if b:ime_status==1
    return 'IME ON'
  else
    return 'IME OFF'
  endif
endfunction
```

また、lualine.nvim の導入と合わせて、画面を縦分割してもステータスバーを分割しないという設定も行っています。この設定は、設定ファイルに次の設定を追加すれば可能です。

```vim
set laststatus=3
```

設定の結果は次のとおりです。

{{< bsimage src="lualine.png" title="設定後の lualine.nvim の表示" >}}

## キーバインド変更

上書き保存などを少しでも簡単にできるようにするため、いくつかのキーバインドを設定しました。

```vim
" 大文字Ｋでカーソル上のヘルプが見られる設定
" 日本語ヘルプがあれば日本語版を、無ければ英語版を表示します。
" 事前に 'vim-jp/vimdoc-ja' をインストールする必要があります。
nnoremap <silent> K :<C-u>call <SID>show_documentation()<CR>
function! s:show_documentation() abort
  if index(['vim','help'], &filetype) >= 0
  try
    execute 'h ' . expand('<cword>') .. "@ja"
  catch /^Vim\%((\a\+)\)\=:E661:/
    execute 'h ' . expand('<cword>')
  endtry
  endif
endfunction

" qa で全てのバッファを閉じる
nnoremap qa qall<CR>

" ;w で保存
nnoremap ;w <Cmd>update<CR>

" ; 2連打でコマンドラインに移動
nnoremap ;; :

" ノーマルモードで BackSpace による削除を可能にする
nnoremap <BS> X
```

## 設定ファイル分割

最初は `init.vim` に全ての設定を書いていましたが、可読性に欠けるので次のような形で分割することにしました。

```bash
nvim
├── filetype.vim
├── ftplugin
│   └── review.vim
├── init.vim
├── init.vim.backup
├── minimal.lua
└── config_files
    ├── init
    │   ├── basic.vim
    │   ├── clipboard.vim
    │   ├── IME.vim
    │   ├── jetpack.vim
    │   ├── keymapping.vim
    │   ├── lsp.vim
    │   └── user_interface.vim
    └── plugin
        ├── ddc.vim
        ├── ddu.vim
        ├── ftpjn.vim
        └── lualine.vim
```

そして、この分割したファイルを `init.vim` の先頭で読み込んでいます。

```vim
source $HOME/.config/nvim/config_files/init/jetpack.vim
source $HOME/.config/nvim/config_files/init/basic.vim
source $HOME/.config/nvim/config_files/init/IME.vim
source $HOME/.config/nvim/config_files/init/clipboard.vim
source $HOME/.config/nvim/config_files/init/user_interface.vim
source $HOME/.config/nvim/config_files/init/keymapping.vim
source $HOME/.config/nvim/config_files/init/lsp.vim
source $HOME/.config/nvim/config_files/plugin/ddu.vim
source $HOME/.config/nvim/config_files/plugin/ddc.vim
source $HOME/.config/nvim/config_files/plugin/ftpjn.vim
source $HOME/.config/nvim/config_files/plugin/lualine.vim
```

なお、`runtime! config_files/init/*.vim`、`runtime! config_files/plugins/*.vim` の2行を `init.vim` の先頭に書いて自動的に設定ファイルを読み込む方法を紹介しているサイトがあり、私もその方法を一度採用しましたが、プラグインが機能しなかったため、上記のように愚直に設定ファイルを読み込む方法に変えました。


## Re:VIEWのシンタックスハイライト

Re:VIEW は Neovim にデフォルトで登録されているファイルタイプではないため、当然シンタックスハイライトも用意されていません。そのため、シンタックスハイライトは手動で設定する必要があります。

とはいえ、シンタックスハイライトの設定を公開（[tokorom/vim-review: Vim syntax for Re:VIEW](https://github.com/tokorom/vim-review)）してくださっている方がいますので、その方の設定を拝借することにしました。

手順は次のとおりです。なお、Re:VIEW のファイルタイプ判定は、上記の「アウトラインバッファの作成」を参照してください。

まず、`.config/nvim/ftplugin/review.vim` を作成して、次のコードを記述します。

```vim
" .config/nvim/ftplugin/review.vim
setl commentstring=#@#\ %s

if !exists('g:vim_review#include_filetypes')
  let g:vim_review#include_filetypes = []
endif

if !exists('g:vim_review#include_grouplists')
  let g:vim_review#include_grouplists = {}
  for ft in g:vim_review#include_filetypes
    let g:vim_review#include_grouplists[ft] = 'syntax/' . ft . '.vim'
  endfor
endif
```

それから、`.config/nvim/syntax/review.vim` を作成して次のコードを記述します。

```vim
" .config/nvim/syntax/review.vim
" Vim syntax file
" Language: Re:VIEW
" Maintainer: Yuta Tokoro <tokorom@gmail.com>

if exists("b:current_syntax")
    finish
endif

" ----------
" syntax

syn case match

syn match reviewHeading contains=reviewInlineCommand,reviewInlineStyleCommand
      \ "^=\+\%(\s\+\|{\|\[\).*"

syn region reviewInlineCommand oneline
      \ start="@<\w\+>{" end="}"
syn region reviewInlineStyleCommand transparent oneline
      \ matchgroup=reviewInlineCommand
      \ start="@<\%\(kw\|bou\|ami\|u\|b\|i\|strong\|em\|tt\|tti\|ttb\|code\|tcy\)>{"
      \ end="}"

syn region reviewBlockCommand transparent keepend
      \ matchgroup=reviewBlockDeclaration start="^//\w\+\[\?.*{\s*$" end="^//}\s*$"

syn match reviewBlockCommandWithoutContent
      \ "^//\w\+\[.*[^{]\s*$"
syn match reviewControlCommand
      \ "^//\<\%\(noindent\|blankline\|linebreak\|pagebreak\)\>\s*$"

syn region reviewItemize transparent oneline
      \ matchgroup=reviewItemizePrefix start="^\s\+\*\+\s\+" end="$"
syn region reviewOrderedItemize transparent oneline
      \ matchgroup=reviewItemizePrefix start="^\s\+[0-9]\+\.\s\+" end="$"
syn region reviewDefinitionList transparent oneline
      \ matchgroup=reviewItemizePrefix start="^\s\+\:\s\+" end="$"

syn match reviewComment contains=reviewTodo
      \ "^#@.*"
syn region reviewCommentBlock keepend contains=reviewTodo
      \ start="^//\<comment\>\[\?.*{\s*" end="^//}\s*$"
syn region reviewCommentInline oneline contains=reviewTodo
      \ start="@<comment>{" end="}"

syn match reviewPreProcCommand
      \ "^#@\<\%\(require\|provide\)\>\s\+.*"
syn region reviewPreProcBlockCommand keepend
      \ start="^#@\<\%\(mapfile\|maprange\|mapoutput\)\>(.*).*" end="^#@end\s*$"

syn region reviewWarning oneline
      \ matchgroup=reviewPreProcCommand start="^#@warn(" end=").*$"

syn case ignore
syn keyword reviewTodo MARK TODO FIXME contained
syn case match

" ----------
" include other languages

if exists('g:vim_review#include_grouplists')
  let include_grouplists = g:vim_review#include_grouplists
  let operations = '\<\%\(list\|listnum\|emlist\|emlistnum\)\>'

  for ft in keys(include_grouplists)
    let syntaxfile = include_grouplists[ft]
    execute 'syn include @' . ft . ' ' . syntaxfile
    let code_block_region = 'start="^//' . operations . '\[.*\[' . ft . '\]{\s*$"'
          \ . ' end="^//}\s*$"'
    let groupname = 'reviewCodeBlock_' . ft
    execute 'syn region ' . groupname . ' keepend contains=@' . ft
          \ . ' matchgroup=reviewBlockDeclaration'
          \ . ' ' . code_block_region

    if exists('b:current_syntax')
      unlet b:current_syntax
    endif
  endfor
endif

" ----------
" highlight

hi def link reviewHeading Conditional
hi def link reviewInlineCommand Function
hi def link reviewBlockDeclaration Identifier
hi def link reviewBlockCommandWithoutContent Identifier
hi def link reviewControlCommand Identifier
hi def link reviewItemizePrefix Special
hi def link reviewComment Comment
hi def link reviewCommentBlock Comment
hi def link reviewCommentInline Comment
hi def link reviewPreProcCommand PreProc
hi def link reviewPreProcBlockCommand PreProc
hi def link reviewWarning Underlined
hi def link reviewTodo Todo

" ----------

let b:current_syntax = "review"
```

なお、シンタックスハイライトを設定したのに一部のキーワードがハイライトされない場合、テーマの色とバッティングしている可能性があります。私も [shaunsingh/nord.nvim: Neovim theme based off of the Nord Color Palette, written in lua with tree sitter support](https://github.com/shaunsingh/nord.nvim) テーマを設定していたところ、一部のキーワードがハイライトされなかったので、テーマの色が邪魔をしているのではないかと疑って別のテーマにしたら全てのキーワードがハイライトされました。

ちなみに、変更後のテーマは [protesilaos/tempus-themes: [Mirror] Tempus is a collection of themes for Vim, text editors, and terminal emulators that are compliant at the very least with the WCAG AA accessibility standard for colour contrast](https://github.com/protesilaos/tempus-themes) の tempus_classic です。


## noice.nvim の導入

Neovim だとコマンドラインバッファがエディタの下の端にありますが、VSCode だとコマンドパレットがエディタの上半分の区域のちょうど良い場所にポップアップするので、Neovim でも同じような機能が欲しいと思って [folke/noice.nvim: 💥 Highly experimental plugin that completely replaces the UI for messages, cmdline and the popupmenu.](https://github.com/folke/noice.nvim/) を導入してみました。

ddc.vim も設定してコマンドライン補完もできるようにしたのですが、入力カーソルが表示されないという問題が発生し、公式リポジトリの Issues にも同じ症状が投稿（[Invisible cursor in cmdline popup · Issue #251 · folke/noice.nvim](https://github.com/folke/noice.nvim/issues/251)）されていましたので、問題が解消されるまで様子見かなと思い、この後に紹介する [VonHeikemen/fine-cmdline.nvim: Enter ex-commands in a nice floating input.](https://github.com/VonHeikemen/fine-cmdline.nvim) に切り替えました。

ところが、作者が「その問題はカラースキーマがカーソルのカラーを提供しないことが原因だ」と[コメント](https://github.com/folke/noice.nvim/issues/251#issuecomment-1367776788)したのを見て、カラースキーマを変えた今なら問題が解消されているかもと思ってプラグインを再び有効化したところ、問題なく入力カーソルが表示されました。そのため、本プラグインを引き続き利用することにしました。

現在の設定は次のとおりです。公式リポジトリの設定例などを継ぎ接ぎしたもので詳細は勉強中です。`noice.vim` ファイルで設定しているため、先頭に `lua << END` を追加し、末尾に `END` を追加しています。

```lua
lua << END
require("noice").setup({
  -- you can enable a preset for easier configuration
  presets = {
    bottom_search = false, -- use a classic bottom cmdline for search
    command_palette = true, -- position the cmdline and popupmenu together
    long_message_to_split = true, -- long messages will be sent to a split
    inc_rename = false, -- enables an input dialog for inc-rename.nvim
    lsp_doc_border = false, -- add a border to hover docs and signature help
  },
  messages = {
    view_search = 'notify',
  },
  routes = {
    {
      view = "notify",
      filter = { event = "msg_showmode" },
    },
    {
      filter = {
        event = "notify",
        warning = true,
        find = "failed to run generator.*is not executable",
      },
      opts = { skip = true },
    },
  },
  cmdline = {
    enabled = true,
    menu = 'popup',
  },
  views = {
    cmdline_popup = {
      position = {
        row = 5,
        col = "50%",
      },
      size = {
        width = 60,
        height = "auto",
      },
    },
    popupmenu = {
      relative = "editor",
      position = {
        row = 8,
        col = "50%",
      },
      size = {
        width = 60,
        height = 10,
      },
      border = {
        style = "rounded",
        padding = { 0, 1 },
      },
      win_options = {
        cursorline = true,
        cursorlineopt = 'line',
        winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
      },
    },
  },
})
END
```

## 導入したものの廃止したもの

### fine-cmdline.nvim

noice.nvim の使用を一度断念した後、同様の機能を持つプラグインである [VonHeikemen/fine-cmdline.nvim: Enter ex-commands in a nice floating input.](https://github.com/VonHeikemen/fine-cmdline.nvim) を使ってみました。

こちらは入力カーソルが消失するような不具合が無く、ddc.vim による補完もできるのですが、上下キーで履歴を移動する度に画面がちらつく上、動作もキビキビしているとは言い難かったため使用を断念しました。


## 参考にしたサイト・情報

- [vimgrepとQuickfix知らないVimmerはちょっとこっち来い - Qiita](https://qiita.com/yuku_t/items/0c1aff03949cb1b8fe6b)
- [Vimファイラの決定版「ddu-ui-filer」設定例を紹介 - アルパカログ](https://alpacat.com/blog/ddu-ui-filer)
- [Vimで技術書を執筆する環境 with Re:VIEW + RedPen + prh | Spinners Inc.](https://spinners.work/posts/vim-review/)
- [とある PR のおかげで Neovim がもはや VSCode な件について](https://wed.dev/blog/posts/neovim-statuline)
- [Vimの自動補完プラグイン「ddc.vim」の使い方](https://original-game.com/how-to-use-ddc-vim/)
- [vim - Vim起動時にウィンドウ縦分割→右側にファイルを開く方法 - スタック・オーバーフロー](https://ja.stackoverflow.com/questions/1685/vim%E8%B5%B7%E5%8B%95%E6%99%82%E3%81%AB%E3%82%A6%E3%82%A3%E3%83%B3%E3%83%89%E3%82%A6%E7%B8%A6%E5%88%86%E5%89%B2%E2%86%92%E5%8F%B3%E5%81%B4%E3%81%AB%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%82%92%E9%96%8B%E3%81%8F%E6%96%B9%E6%B3%95)
- [新世代の UI 作成プラグイン ddu.vim](https://zenn.dev/shougo/articles/ddu-vim-beta#ddu.vim-%E3%81%AE%E4%BD%BF%E7%94%A8%E6%96%B9%E6%B3%95)
- [自動補完プラグイン ddc.vim + pum.vim](https://zenn.dev/shougo/articles/ddc-vim-pum-vim)
- [新世代の UI 作成プラグイン ddu.vim](https://zenn.dev/shougo/articles/ddu-vim-beta)
- [新世代のファイラー UI ddu-ui-filer](https://zenn.dev/shougo/articles/ddu-ui-filer#ddu-ui-filer-%E3%81%AE%E4%BD%BF%E7%94%A8%E6%96%B9%E6%B3%95)
- [cmdheight=0 in neovim](https://zenn.dev/shougo/articles/set-cmdheight-0)
- [Neovimの補完をddc.vim + Built-in LSP へ移行した | ntsk](https://ntsk.jp/blog/ddc-vim/)
- [Vimファイラの決定版「ddu-ui-filer」設定例を紹介 - アルパカログ](https://alpacat.com/blog/ddu-ui-filer)
- [Neovimのコマンドラインや通知がリッチになるnoice.nvim使ってみた | DevelopersIO](https://dev.classmethod.jp/articles/eetann-noice-nvim-beginner/)
- Vim のヘルプファイル

