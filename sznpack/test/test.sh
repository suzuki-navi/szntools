
rm -f ./var/out.sh
../bin/sznpack

ls -l ./var/out.sh

./var/out.sh > var/result.txt
diff -u src/main.sh var/result.txt && echo OK

