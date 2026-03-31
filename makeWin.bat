@echo on
setlocal enabledelayedexpansion


@echo off
setlocal

:: 1. Initial Paths (Using backslashes is fine here; we sanitize next)
set "QT=C:/Qt6/6.10.2/msvc2022_64"
set "PYTHON_EXECUTABLE=%USERPROFILE%\python_env\python3.12-qgis\Scripts\python.exe"
set "ROOT=%CD%"
set "VCPKG_ROOT=%USERPROFILE%\vcpkg"
set "VCPKG_MANIFEST_DIR=%ROOT%\vcpkg"
set "VCPKG_INSTALLED_DIR=%ROOT%\build\vcpkg_installed"
set "TRIPLET=x64-windows"

:: 2. Sanitize ALL (Convert \ to / and remove trailing spaces)
set "QT=%QT:\=/%"
set "PYTHON_EXECUTABLE=%PYTHON_EXECUTABLE:\=/%"
set "ROOT=%ROOT:\=/%"
set "VCPKG_ROOT=%VCPKG_ROOT:\=/%"
set "VCPKG_MANIFEST_DIR=%VCPKG_MANIFEST_DIR:\=/%"
set "VCPKG_INSTALLED_DIR=%VCPKG_INSTALLED_DIR:\=/%"

:: 3. Dependent Paths
set "PREFIX=%ROOT%/DEPS"
set "SRC=%ROOT%/sources"
set "CMAKE_PREFIX_PATH=%PREFIX%;%QT%"



rem Optional Python config
rem set "SIP_BUILD_EXECUTABLE=%"

rem --------------------------------------------------
rem Clean build dir
rem --------------------------------------------------

rem if exist "%BUILD%" rmdir /s /q "%BUILD%"

if not exist build (
    mkdir build
    if errorlevel 1 exit /b 1
)

cd build

set "CMAKE_PREFIX_PATH=%PREFIX%;%QT%"
set "VCPKG_KEEP_ENV_VARS=CMAKE_PREFIX_PATH"
set "PATH=%QT%\bin;%PREFIX%\bin;%VCPKG_INSTALLED_DIR%\%TRIPLET%\bin;%PATH%"

echo CURRENT_PATH_IS: %PATH%

:: Save to a file in your build folder for reference
echo %PATH% > path_debug.txt

"%VCPKG_ROOT%\vcpkg.exe" install ^
  --x-manifest-root="%VCPKG_MANIFEST_DIR%" ^
  --x-install-root="%VCPKG_INSTALLED_DIR%" ^
  --triplet %TRIPLET%

if errorlevel 1 exit /b 1

echo on 

cmake .. ^
  -G Ninja ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DWITH_VCPKG=ON ^
  -DVCPKG_BUILD=Release ^
  -DWITH_AUTH=TRUE ^
  -DWITH_PYTHON=OFF ^
  -DVCPKG_EXECUTABLE="%VCPKG_ROOT%/vcpkg.exe" ^
  -DVCPKG_PREFER_SYSTEM_LIBS=ON ^
  -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake" ^
  -DVCPKG_MANIFEST_DIR="%VCPKG_MANIFEST_DIR%" ^
  -DVCPKG_INSTALLED_DIR="%VCPKG_INSTALLED_DIR%" ^
  -DVCPKG_TARGET_TRIPLET=%TRIPLET% ^
  -DCMAKE_PREFIX_PATH="%QT%;%PREFIX%" ^
  -DQt6_DIR="%QT%/lib/cmake/Qt6" ^
  -DQt6SerialPort_DIR="%QT%/lib\cmake/Qt6SerialPort" ^
  -DQt6Keychain_DIR="%PREFIX%\lib/cmake/Qt6Keychain" ^
  -DQWT_LIBRARY="%PREFIX%/lib/qwt.lib" ^
  -DQWT_INCLUDE_DIR="%PREFIX%/include/qwt" ^
  -DQCA_DIR="%PREFIX%/lib/cmake/Qca-qt6" ^
  -DPython_EXECUTABLE="%PYTHON_EXECUTABLE%" ^
  -DFLEX_EXECUTABLE="C:/Users/fmcke/NHERI/win_flex_bison/win_flex.exe" ^
  -DBISON_EXECUTABLE="C:/Users/fmcke/NHERI/win_flex_bison/win_bison.exe" ^
  -DSIP_BUILD_EXECUTABLE="%USERPROFILE%/NHERI/win_flex_bison" ^
  -DQSCINTILLA_INCLUDE_DIR="%PREFIX%/include" ^
  -DQSCINTILLA_LIBRARY="%PREFIX%/lib/qscintilla2_qt6.lib" ^
  -DUSE_OPENCL=OFF ^
  -DENABLE_TESTS=OFF


if errorlevel 1 exit /b 1


endlocal