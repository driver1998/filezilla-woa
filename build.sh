
HOST=$ARCH-w64-mingw32
PREFIX=$PWD/$HOST
PREFIX_AUTOMAKE=$PWD/automake

export MINGW_ROOT=$PWD/$(find llvm-mingw* -maxdepth 1 -type d | head -n 1)
export PATH=$PREFIX_AUTOMAKE/bin:$PATH:$MINGW_ROOT/bin:$PREFIX/bin:$PREFIX/lib:$MINGW_ROOT/$HOST/bin
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig

export CFLAGS="-Wno-unused-function -Wno-unused-lambda-capture -Wno-unused-variable \
               -Wno-ignored-attributes -Wno-inconsistent-missing-override \
               -Wno-inconsistent-dllimport -O2"
export CXXFLAGS=$CFLAGS

echo Building for $HOST

# For some reason MinGW ARM is missing serveral libs compared to x86
# Build lib for $ARCH from i686 version
# $1 : The lib filename, in MinGW convention
#      xyz.dll -> libxyz.a
function build_lib() {
    LIBFILE=$1
    MODULE=$(echo $LIBFILE | sed 's/lib\(.*\?\)\.a/\1/g')
    DLLFILE=$(echo $MODULE | tr '/a-z/' '/A-Z/').dll
    (
        echo LIBRARY $DLLFILE
        echo EXPORTS
        $HOST-nm $MINGW_ROOT/i686-w64-mingw32/lib/$LIBFILE --just-symbol-name |
            sed '/^$/d' | sed "/^$DLLFILE/d" | sed '/\.idata/d' | sed '/__imp/d' | sed '/__NULL_IMPORT/d' |
            sed '/_NULL_THUNK_DATA/d' | sed '/__IMPORT_DESCRIPTOR/d' | sed 's/@.*$//g' | sed 's/^_//g'
    ) > $MODULE.def
    $HOST-dlltool -d $MODULE.def -l $MINGW_ROOT/$HOST/lib/$LIBFILE
}

if [ $ARCH == "aarch64" ]
then
    build_lib "libpowrprof.a"
    build_lib "libsetupapi.a"
fi

# automake
pushd $(find automake* -maxdepth 1 -type d | head -n 1)
./configure --prefix=$PREFIX_AUTOMAKE || exit 1
make || exit 1
make install || exit 1
popd

# gmp
pushd $(find gmp* -maxdepth 1 -type d | head -n 1)
if [ $ARCH == "armv7" ]; then GMP_ASSEMBLY_FLAG="--disable-assembly"; fi
./configure --prefix=$PREFIX --host=$HOST --disable-static --enable-shared \
            --disable-cxx $GMP_ASSEMBLY_FLAG || exit 1
make -j $(nproc) || exit 1
make install     || exit 1
popd

# nettle
pushd $(find nettle* -maxdepth 1 -type d | head -n 1)
./configure --prefix=$PREFIX --host=$HOST --disable-static --enable-shared --disable-assembler \
            --with-include-path=$PREFIX/include --with-lib-path=$PREFIX/lib || exit 1
make -j $(nproc) || exit 1
make install     || exit 1
popd

# gnutls
pushd $(find gnutls* -maxdepth 1 -type d | head -n 1)
GMP_CFLAGS="-I$PREFIX/include" GMP_LIBS="-L$PREFIX/lib -lgmp" \
./configure --prefix=$PREFIX --host=$HOST --disable-static --enable-shared --disable-cxx \
            --without-p11-kit --with-included-libtasn1 --with-included-unistring --enable-local-libopts \
            --disable-srp-authentication --disable-dtls-srtp-support --disable-heartbeat-support \
            --disable-psk-authentication --disable-anon-authentication --disable-openssl-compatibility --without-tpm \
            --disable-hardware-acceleration --disable-tools --disable-doc || exit 1
make -j $(nproc) || exit 1
make install     || exit 1
popd

# sqlite
pushd $(find sqlite* -maxdepth 1 -type d | head -n 1)
./configure --prefix=$PREFIX --host=$HOST --disable-static --enable-shared || exit 1
make         || exit 1
make install || exit 1
popd

# libfilezilla
pushd $(find libfilezilla* -maxdepth 1 -type d | head -n 1)
for p in ../patches/libtool/*.patch; do patch -p1 < "$p"; done
autoconf
./configure --prefix=$PREFIX --host=$HOST --disable-static --enable-shared --disable-doxygen-doc || exit 1
make -j $(nproc) || exit 1
make install     || exit 1
popd  

# filezilla
pushd $(find filezilla* -maxdepth 1 -type d | head -n 1)
for p in ../patches/libtool/*.patch;   do patch -p1 < "$p"; done
for p in ../patches/filezilla/*.patch; do patch -p1 < "$p"; done
autoconf
pushd src/fzshellext
autoconf
popd
./configure --prefix=$PREFIX --host=$HOST --with-wx-config=$PREFIX/bin/wx-config --disable-manualupdatecheck || exit 1
make -j $(nproc) || exit 1
make install     || exit 1

$HOST-strip src/interface/.libs/filezilla.exe \
            src/putty/.libs/fzsftp.exe \
            src/putty/.libs/fzputtygen.exe \
            src/fzshellext/32/.libs/libfzshellext-0.dll \
            src/fzshellext/64/.libs/libfzshellext-0.dll \
            data/dlls/*.dll

pushd data
sh makezip.sh $PREFIX
mv FileZilla.zip ../../

if [ $ARCH != "armv7" ]
then
  wine "../../nsis/makensis.exe" install.nsi
  mv FileZilla_3_setup.exe ../../
fi
popd
popd
