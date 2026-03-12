#!/bin/bash

QT=/Users/fmckenna/Qt/6.10.1/macos
PREFIX=$(pwd)/DEPS

rm -fr $PREFIX sources
mkdir -p "$PREFIX"
mkdir -p "sources"

export CC=/usr/bin/clang
export CXX=/usr/bin/clang++
export CMAKE_PREFIX_PATH=$PREFIX

cd sources

# 1. Build OpenSSL (Includes Crypto)
echo "--- Building OpenSSL ---"
curl -LO https://www.openssl.org/source/openssl-3.4.1.tar.gz
tar xf openssl-3.4.1.tar.gz
cd openssl-3.4.1
./Configure darwin64-arm64-cc \
  --prefix=$PREFIX
  --openssldir=$PREFIX
make -j$(sysctl -n hw.ncpu)
make install_sw
cd ..

# 2. Build QCA (Qt Cryptographic Architecture), pointing to recently built openssl
echo "--- Building QCA ---"
git clone https://github.com/KDE/qca.git
cd qca
cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$QT" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DOSX_FRAMEWORK=OFF \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DBUILD_TESTING=OFF \
  -DBUILD_WITH_QT6=ON \
  -DOPENSSL_ROOT_DIR=$PREFIX

cmake --build build --config Release --parallel $(sysctl -n hw.ncpu)
cmake --install build
cd ..

# 3. Build QtKeyChain
echo "--- Building Qtkeychain ---"
git clone https://github.com/frankosterfeld/qtkeychain.git
cd qtkeychain

cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$QT" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DBUILD_WITH_QT6=ON

cmake --build build --config Release --parallel $(sysctl -n hw.ncpu)
cmake --install build
cd ..


# 4. Build Qwt
echo "--- Building Qwt ---"
VERSION=6.3.0

curl -L -o qwt.tar.bz2 https://sourceforge.net/projects/qwt/files/qwt/$VERSION/qwt-$VERSION.tar.bz2/download
tar -xjf qwt.tar.bz2
cd qwt-$VERSION

# configure the install to be placed in PREFIX .. have to chabfe the qwtcinfig.pri file
sed -i.bak \
  -e "s|^[[:space:]]*QWT_INSTALL_PREFIX[[:space:]]*=.*|QWT_INSTALL_PREFIX = $PREFIX|" \
  -e "/^unix[[:space:]]*{/,/^}/ s|^[[:space:]]*QWT_INSTALL_PREFIX[[:space:]]*=.*|    QWT_INSTALL_PREFIX = $PREFIX|" \
  -e "s|^[[:space:]]*QWT_CONFIG[[:space:]]*+= QwtFramework|# &|" \
  qwtconfig.pri


qmake
make -j$(sysctl -n hw.ncpu 2>/dev/null || nproc)
make install
mkdir $PREFIX/include/qwt
mv $PREFIX/include/qwt* $PREFIX/include/qwt
mv $PREFIX/include/Qwt* $PREFIX/include/qwt
cd ..

rm -fr sources

echo "-----------------------------------------------"
echo "Build Complete!"
echo "Files installed to: $PREFIX"
echo "-----------------------------------------------"
