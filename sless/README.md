
# 対応するフォーマット

- JSON
- JSON Lines
- TSV
- plain text
- batコマンドが対応している各種言語
- zip
- tar
- バイナリファイル
- 圧縮ファイル
    - gzip
    - xz
- directory


# オプション

-N: 行番号が変わるフォーマットの変更を抑制
-n: 行番号を非表示


# 依存性

- perl
- gunzip
    - gzip圧縮ファイルを表示する場合
- xz
    - xz圧縮ファイルを表示する場合
- ls
    - ディレクトリを表示する場合
- jq
    - JSONファイルを表示する場合
- bat (batcat)
    - 各種言語のファイルを表示する場合
- zip
    - zipファイルを表示する場合
- tar
    - tarファイルを表示する場合
- hexdump
    - バイナリファイルを表示する場合

