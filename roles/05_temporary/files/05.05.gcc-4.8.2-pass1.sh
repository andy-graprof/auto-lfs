#!/bin/bash

set -e
set -u
set -x

tar -xf ../sources/gcc-4.8.2.tar.bz2
cd gcc-4.8.2

tar -xf ../../sources/mpfr-3.1.2.tar.xz
mv mpfr-3.1.2 mpfr
tar -xf ../../sources/gmp-5.1.3.tar.xz
mv gmp-5.1.3 gmp
tar -xf ../../sources/mpc-1.0.2.tar.gz
mv mpc-1.0.2 mpc

for file in \
  $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
    -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure

mkdir ../gcc-build
cd ../gcc-build

../gcc-4.8.2/configure                              \
  --target=$LFS_TGT                                 \
  --prefix=/tools                                   \
  --with-sysroot=$LFS                               \
  --with-newlib                                     \
  --without-headers                                 \
  --with-local-prefix=/tools                        \
  --with-native-system-header-dir=/tools/include    \
  --disable-nls                                     \
  --disable-shared                                  \
  --disable-multilib                                \
  --disable-decimal-float                           \
  --disable-threads                                 \
  --disable-libatomic                               \
  --disable-libgomp                                 \
  --disable-libitm                                  \
  --disable-libmudflap                              \
  --disable-libquadmath                             \
  --disable-libsanitizer                            \
  --disable-libssp                                  \
  --disable-libstdc++-v3                            \
  --enable-languages=c,c++                          \
  --with-mpfr-include=$(pwd)/../gcc-4.8.2/mpfr/src  \
  --with-mpfr-lib=$(pwd)/mpfr/src/.libs

make ${LFS_MFLAGS:-}

make install

ln -sv libgcc.a `$LFS_TGT-gcc -print-libgcc-file-name | sed 's/libgcc/&_eh/'`

cd ..
rm -rf gcc-build
rm -rf gcc-4.8.2
