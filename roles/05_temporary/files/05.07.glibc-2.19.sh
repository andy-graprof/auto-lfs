#!/bin/bash

if [ -z "$1" ]; then
  cd $LFS/sources && $0 go &> $LFS/logs/$(basename $0).log
  exit $?
fi

set -e
set -u
set -x

tar -xf glibc-2.19.tar.xz
cd glibc-2.19

if [ ! -r /usr/include/rpc/types.h ]; then
  su -c 'mkdir -pv /usr/include/rpc'
  su -c 'cp -v sunrpc/rpc/*.h /usr/include/rpc'
fi

mkdir -v ../glibc-build
cd ../glibc-build

../glibc-2.19/configure                         \
  --prefix=/tools                               \
  --host=$LFS_TGT                               \
  --build=$(../glibc-2.19/scripts/config.guess) \
  --disable-profile                             \
  --enable-kernel=2.6.32                        \
  --with-headers=/tools/include                 \
  libc_cv_forced_unwind=yes                     \
  libc_cv_ctors_header=yes                      \
  libc_cv_c_cleanup=yes

make

make install

echo 'main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools' | grep ld-linux.so.2

cd ..
rm -rf glibc-build
rm -rf glibc-2.19
