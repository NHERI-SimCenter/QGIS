#!/bin/bash

QT=/Users/fmckenna/Qt/6.10.1/macos
PREFIX=$(pwd)/DEPS

rm -fr build
mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX

export VCPKG_KEEP_ENV_VARS="CMAKE_PREFIX_PATH"
export VCPKG_ROOT="$HOME/.vcpkg"
export PATH=$(brew --prefix bison)/bin:$(brew --prefix flex)/bin:$(brew --prefix libtool)/bin:$PATH
TRIPLET=arm64-osx-release
export CC=/usr/bin/clang
export CXX=/usr/bin/clang++

vcpkg install --x-manifest-root="$PWD/vcpkg"  --x-install-root="$PWD/build/vcpkg_installed"   --triplet arm64-osx

cmake .. \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DWITH_VCPKG=ON \
      -DWITH_AUTH=TRUE \
      -DWITH_PYTHON=OFF \
      -DVCPKG_EXECUTABLE=$HOME/.vcpkg/vcpkg \
      -DVCPKG_PREFER_SYSTEM_LIBS=ON \
      -DCMAKE_TOOLCHAIN_FILE=$HOME/.vcpkg/scripts/buildsystems/vcpkg.cmake \
      -DVCPKG_MANIFEST_DIR=/Users/fmckenna/NHERI/QGIS/vcpkg \
      -DVCPKG_INSTALLED_DIR=/Users/fmckenna/NHERI/QGIS/build/vcpkg_installed \
      -DVCPKG_TARGET_TRIPLET=arm64-osx  \
      -DCMAKE_PREFIX_PATH="$QT;$PREFIX"\ 
      -DQt6_DIR=$QT/lib/cmake/Qt6 \
      -DQt6SerialPort_DIR=$QT/lib/cmake/Qt6SerialPort \
      -DQt6Keychain_DIR=$PREFIX/lib/cmake/Qt6Keychain \
      -DQWT_LIBRARY=$PREFIX/lib/libqwt.dylib \
      -DQWT_INCLUDE_DIR=$PREFIX/include/qwt \
      -DQCA_DIR=$PREFIX/lib/cmake/Qca-qt6 \
      -DPython_EXECUTABLE=/Users/fmckenna/python_env/python3-qgis/bin/python3 \
      -DSIP_BUILD_EXECUTABLE=/Users/fmckenna/python_env/python3-qgis/bin/sip-build \
      -DQSCINTILLA_INCLUDE_DIR=/Users/fmckenna/Qt/6.10.1/macos/include \
      -DQSCINTILLA_LIBRARY=/Users/fmckenna/Qt/6.10.1/macos/lib/libqscintilla2_qt6.dylib \
      -DUSE_OPENCL=OFF 

cmake --build . --config Release --parallel $(sysctl -n hw.ncpu)

cd ..
      
echo "-----------------------------------------------"
echo "Build Complete!" .. have a look in build/output
echo "-----------------------------------------------"
