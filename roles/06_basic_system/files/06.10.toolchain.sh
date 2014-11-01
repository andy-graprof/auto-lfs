#!/bin/bash

set +h
set -e
set -u
set -x

mv /tools/bin/{ld,ld-old}
mv /tools/$(gcc -dumpmachine)/bin/{ld,ld-old}
mv /tools/bin/{ld-new,ld}
ln -s /tools/bin/ld /tools/$(gcc -dumpmachine)/bin/ld

gcc -dumpspecs | sed -e 's@/tools@@g'                 \
  -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
  -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
  `dirname $(gcc --print-libgcc-file-name)`/specs

echo 'main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib' | grep '/lib[64]*/ld-linux'

grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log

grep -B1 '^ /usr/include' dummy.log

grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'

grep "/lib.*/libc.so.6 " dummy.log

grep found dummy.log

rm -v dummy.c a.out dummy.log
