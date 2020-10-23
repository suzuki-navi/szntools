
rm -f ./var/out.sh
mkdir -p var
../bin/sznpack -o var/out.sh

ls -l ./var/out.sh

./var/out.sh > var/result.txt
diff -u src/main.sh var/result.txt && echo OK

