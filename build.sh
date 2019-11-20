#!/usr/bin/env bash

ARCH=aarch64
HOST=$ARCH-w64-mingw32
PREFIX=$PWD/filezilla-$HOST
PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig

MINGW_ROOT=$PWD/llvm-mingw
PATH=$PATH:$MINGW_ROOT/bin
LDFLAGS="-L$MINGW_ROOT/lib/clang/9.0.0/lib/windows -lclang_rt.builtins-aarch64"
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PREFIX/lib

# gmp
pushd gmp
./configure --prefix=$(PREFIX) --host=$(HOST) --disable-static --enable-shared --disable-cxx --disable-assembly || exit 1
make install -j8 || exit 1
popd

# nettle
pushd nettle
./configure --prefix=$(PREFIX) --host=$(HOST) --disable-static --enable-shared --disable-assembler || exit 1
make install -j8 || exit 1
popd

# gnutls
pushd gnutls
./configure --prefix=$(PREFIX) --host=$(HOST) --disable-static --enable-shared --without-p11-kit --with-included-libtasn1 --with-included-unistring --enable-local-libopts --disable-srp-authentication --disable-dtls-srtp-support --disable-heartbeat-support --disable-psk-authentication --disable-anon-authentication --disable-openssl-compatibility --without-tpm --disable-cxx --disable-hardware-acceleration --disable-tools --disable-doc || exit 1
make install -j8 || exit 1
popd

# sqlite
pushd sqlite
./configure --prefix=$(PREFIX) --host=$(HOST) --disable-static --enable-shared || exit 1
make install -j8 || exit 1
popd

# libfilezilla
#curl 'https://dl1.cdn.filezilla-project.org/libfilezilla/libfilezilla-0.18.1.tar.bz2?h=wbiDjBgwuLHoc6O_BRRFPA&x=1566413717' -o libfilezilla.tar.bz2 || exit 1
#tar -xjf libfilezilla.tar.bz2 || exit 1
#cd libfilezilla
#./configure --prefix=$(PREFIX) --host=$(HOST) --disable-shared --disable-doxygen-doc

# wxwidgets
pushd wxwidgets
./configure --prefix=$(PREFIX) --host=$(HOST) --disable-static --enable-shared --enable-monolithic --without-opengl || exit 1
make install -j8 || exit 1
popd

# filezilla
#curl https://dl3.cdn.filezilla-project.org/client/FileZilla_3.44.2_src.tar.bz2?h=cXaccyaUk41EyGl4z04-cQ&x=1566413973 -o filezilla.tar.bz2 || exit 1
#tar -xjf filezilla.tar.bz2 || exit 1
#cd filezilla
#./configure --prefix=$(PREFIX) --host=$(HOST) --disable-shellext --with-wx-config=$(PREFIX)/bin/wx-config

find $PWD/filezilla-$HOST
