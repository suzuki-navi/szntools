#!/bin/bash

set -Ceu
# -C リダイレクトでファイルを上書きしない
# -e コマンドの終了コードが1つでも0以外になったら直ちに終了する
# -u 設定されていない変数が参照されたらエラー

: "${SZNPACK_SOURCE_PARENT_DIR_NAME:=.sznpack}"

: "$SZNPACK_SOURCE_DIR"
# SZNPACK_SOURCE_DIR はsznpackでビルド時に定義される。
# 未定義の場合にエラーとする。

target_source_dir=
output=out.sh
while [ $# -gt 0 ]; do
    if [ "$1" = "-o" ]; then
        output=$2
        shift
    elif [ -z "$target_source_dir" ]; then
        target_source_dir=$1
    else
        echo "Unknown parameter" >&2
        exit 1
    fi
    shift
done

if [ -z "$target_source_dir" ]; then
    target_source_dir=src
fi

cp -r $target_source_dir $SZNPACK_SOFT_WORKING_DIR/src

(
cd $SZNPACK_SOFT_WORKING_DIR

mkdir -p var/target

target_sources=$(cd src; ls)
target_sources2=$(echo $(cd src; ls | sed "s#^#var/target/#g"))

dirflag=""
if grep "SZNPACK_SOFT_WORKING_DIR" src/main.sh >/dev/null; then
    # `SZNPACK_SOFT_WORKING_DIR` という文字列が src/main.sh に含まれる場合
    dirflag="$dirflag soft_working_dir"
fi
if grep "SZNPACK_HARD_WORKING_DIR" src/main.sh >/dev/null; then
    # `SZNPACK_HARD_WORKING_DIR` という文字列が src/main.sh に含まれる場合
    dirflag="$dirflag hard_working_dir"
fi

(

cat <<EOF
var/out.sh: var/TARGET_VERSION_HASH
	cat $SZNPACK_SOURCE_DIR/boot.sh | sed "s/XXXX_VERSION_HASH_XXXX/\$\$(cat var/TARGET_VERSION_HASH)/g" | sed "s#XXXX_SZNPACK_SOURCE_DIR_XXXX#$SZNPACK_SOURCE_PARENT_DIR_NAME#g" | perl $SZNPACK_SOURCE_DIR/preprocess.pl $dirflag > var/out.sh.tmp
	(cd var/target; perl $SZNPACK_SOURCE_DIR/szntar.pl) | gzip -n -c >> var/out.sh.tmp
	chmod 755 var/out.sh.tmp
	mv var/out.sh.tmp var/out.sh

EOF

for f in $target_sources; do
    cat <<EOF
var/target/$f: src/$f
	cp src/$f var/target/$f

EOF
done

cat <<EOF
var/TARGET_VERSION_HASH: $target_sources2
	cat $target_sources2 | shasum | cut -b1-40 > var/TARGET_VERSION_HASH.tmp
	mv var/TARGET_VERSION_HASH.tmp var/TARGET_VERSION_HASH

EOF

) >| var/makefile.tmp
mv var/makefile.tmp var/makefile

make -s -f var/makefile
)

result=$?

if [ $result = 0 ]; then
    mv $SZNPACK_SOFT_WORKING_DIR/var/out.sh $output
fi

exit $result

