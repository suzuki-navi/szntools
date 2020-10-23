
set -Ceu
set -o pipefail

cd $(dirname $0)/..

mkdir -p test/var

(
    cd ../.git
    ../szntar/szntar >| ../szntar/test/var/archive.sh
)

(
    cd test/var

    rm -rf g
    mkdir g

    (
        cd g
        bash ../archive.sh
    )

)

diff -r ../.git test/var/g && echo OK

