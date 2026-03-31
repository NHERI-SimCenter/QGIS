@echo off
setlocal enabledelayedexpansion

rem --------------------------------------------------
rem Config
rem --------------------------------------------------
set "QT=C:\Qt6\6.10.2\msvc2022_64"
set "PREFIX=%CD%\DEPS"
set "SRC=%CD%\sources"




rem If vcvars64.bat is not already loaded, call it here.
rem Adjust this path to your VS install:
rem call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
rem if errorlevel 1 (
rem echo Failed to load Visual Studio build environment
rem exit /b 1
rem )

set "CMAKE_PREFIX_PATH=%PREFIX%;%QT%"

rem --------------------------------------------------
rem Clean + create dirs
rem --------------------------------------------------
if exist "%PREFIX%" rmdir /s /q "%PREFIX%"
if exist "%SRC%" rmdir /s /q "%SRC%"

mkdir "%PREFIX%"
mkdir "%SRC%"

cd /d "%SRC%"

call "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" -arch=x64 -host_arch=x64
vcpkg install openssl:x64-windows pkgconf:x64-windows

rem --------------------------------------------------
rem 2. Build QCA
rem --------------------------------------------------
echo --- Building QCA ---
git clone https://github.com/KDE/qca.git
if errorlevel 1 exit /b 1

cd qca

cmake -S . -B build -G Ninja ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_PREFIX_PATH="%QT%;%USERPROFILE%\installed\x64-windows;%PREFIX%" ^
  -DCMAKE_INSTALL_PREFIX="%PREFIX%" ^
  -DBUILD_TESTING=OFF ^
  -DQt6_DIR="%QT%\lib\cmake\Qt6" ^
  -DCMAKE_TOOLCHAIN_FILE=%USERPROFILE%/vcpkg/scripts/buildsystems/vcpkg.cmake ^
  -DVCPKG_TARGET_TRIPLET=x64-windows ^
  -DBUILD_WITH_QT6=ON 


if errorlevel 1 exit /b 1

cmake --build build --config Release --parallel
if errorlevel 1 exit /b 1

cmake --install build
if errorlevel 1 exit /b 1

cd /d "%SRC%"

rem --------------------------------------------------
rem 3. Build QtKeychain
rem --------------------------------------------------
echo --- Building QtKeychain ---
git clone https://github.com/frankosterfeld/qtkeychain.git
if errorlevel 1 exit /b 1

cd qtkeychain

cmake -S . -B build -G Ninja ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_PREFIX_PATH="%QT%;%USERPROFILE%/installed/x64-windows;%PREFIX%" ^
  -DCMAKE_INSTALL_PREFIX="%PREFIX%" ^
  -DBUILD_TESTING=OFF ^
  -DQt6_DIR="%QT%\lib\cmake\Qt6" ^
  -DCMAKE_TOOLCHAIN_FILE=%USERPROFILE%/vcpkg/scripts/buildsystems/vcpkg.cmake ^
  -DVCPKG_TARGET_TRIPLET=x64-windows ^
  -DBUILD_WITH_QT6=ON 


if errorlevel 1 exit /b 1

cmake --build build --config Release --parallel
if errorlevel 1 exit /b 1

cmake --install build
if errorlevel 1 exit /b 1

cd /d "%SRC%"

rem --------------------------------------------------
rem 4. Build Qwt
rem --------------------------------------------------
echo --- Building Qwt ---
set "VERSION=6.3.0"

curl -L -o qwt.tar.bz2 https://sourceforge.net/projects/qwt/files/qwt/%VERSION%/qwt-%VERSION%.tar.bz2/download
if errorlevel 1 exit /b 1

tar -xjf qwt.tar.bz2
if errorlevel 1 exit /b 1

cd qwt-%VERSION%

rem Edit qwtconfig.pri using PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='%CD%\qwtconfig.pri';" ^
  "$c=Get-Content $p;" ^
  "$c=$c -replace '^\s*QWT_INSTALL_PREFIX\s*=.*', 'QWT_INSTALL_PREFIX = %PREFIX:\=\\%';" ^
  "$c=$c -replace '^\s*QWT_CONFIG\s*\+=\s*QwtFramework', '# QWT_CONFIG += QwtFramework';" ^
  "Set-Content $p $c"

if errorlevel 1 exit /b 1

rem Make sure qmake from your Qt install is used
set "PATH=%QT%\bin;%PATH%"

qmake
if errorlevel 1 exit /b 1

nmake
if errorlevel 1 exit /b 1

nmake install
if errorlevel 1 exit /b 1

if not exist "%PREFIX%\include\qwt" mkdir "%PREFIX%\include\qwt"

rem Move Qwt headers into include\qwt
for %%F in ("%PREFIX%\include\qwt*.h") do move /Y "%%~fF" "%PREFIX%\include\qwt\" >nul 2>&1
for %%F in ("%PREFIX%\include\Qwt*.h") do move /Y "%%~fF" "%PREFIX%\include\qwt\" >nul 2>&1

cd /d "%SRC%"


rem --------------------------------------------------
rem 5. Build QScintilla
rem --------------------------------------------------
echo --- Building QScintilla ---
set "QSCI_VERSION=2.14.1"

curl -L -o QScintilla_src-%QSCI_VERSION%.zip ^
  https://www.riverbankcomputing.com/static/Downloads/QScintilla/%QSCI_VERSION%/QScintilla_src-%QSCI_VERSION%.zip
if errorlevel 1 exit /b 1

tar -xf QScintilla_src-%QSCI_VERSION%.zip
if errorlevel 1 exit /b 1

#rem Upstream warns old installed Qsci headers can confuse the build on Windows
#if exist "%PREFIX%\include\Qsci" rmdir /s /q "%PREFIX%\include\Qsci"

cd QScintilla_src-%QSCI_VERSION%\src

rem Make sure Qt's qmake is first on PATH
set "PATH=%QT%\bin;%PATH%"

qmake qscintilla.pro
if errorlevel 1 exit /b 1

nmake
if errorlevel 1 exit /b 1

rem --------------------------------------------------
rem Install into %PREFIX% manually
rem --------------------------------------------------
if not exist "%PREFIX%\bin" mkdir "%PREFIX%\bin"
if not exist "%PREFIX%\lib" mkdir "%PREFIX%\lib"
if not exist "%PREFIX%\include\Qsci" mkdir "%PREFIX%\include\Qsci"

rem Copy DLL(s)
for /r %%F in (qscintilla2*.dll) do copy /Y "%%~fF" "%PREFIX%\bin\" >nul

rem Copy import/static libs
for /r %%F in (qscintilla2*.lib) do copy /Y "%%~fF" "%PREFIX%\lib\" >nul

rem Copy headers from the source tree
if exist ".\Qsci" (
  copy /Y ".\Qsci\*.h" "%PREFIX%\include\Qsci\" >nul
)

rem Optional: copy qmake feature file so qmake projects can use CONFIG += qscintilla2
if exist "features\qscintilla2.prf" (
  if not exist "%PREFIX%\mkspecs\features" mkdir "%PREFIX%\mkspecs\features"
  copy /Y "features\qscintilla2.prf" "%PREFIX%\mkspecs\features\" >nul
)

cd /d "%SRC%"

rem --------------------------------------------------
rem Cleanup
rem --------------------------------------------------
cd /d "%CD%\.."
if exist "%SRC%" rmdir /s /q "%SRC%"

echo -----------------------------------------------
echo Build Complete!
echo Files installed to: %PREFIX%
echo -----------------------------------------------

endlocal