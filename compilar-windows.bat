@echo off
setlocal
rem ============================================================
rem  Baudex - compilar para Windows con doble clic.
rem  Crea los archivos .env que faltan (apuntan al servidor real),
rem  compila y, si esta Inno Setup, arma el instalador en dist\.
rem ============================================================
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] No encuentro Flutter en este equipo. Instalalo y vuelve a intentar.
  goto :fin_error
)

for %%f in (.env .env.production .env.development .env.staging) do (
  if not exist "%%f" (
    echo Creando %%f ...
    (
      echo SERVER_IP=baudex.baudity.tech
      echo SERVER_PORT=443
      echo APP_ENV=production
      echo API_TIMEOUT=30000
      echo DEBUG_MODE=false
      echo SHOW_LOGS=false
    )>"%%f"
  )
)

echo.
echo === Descargando dependencias ===
call flutter pub get
if errorlevel 1 goto :fin_error

echo.
echo === Compilando (tarda varios minutos) ===
call flutter build windows --release --dart-define=FLAVOR=production
if errorlevel 1 goto :fin_error

set "VER="
for /f "tokens=2 delims=: " %%v in ('findstr /b /c:"version:" pubspec.yaml') do set "VER=%%v"
for /f "tokens=1 delims=+" %%v in ("%VER%") do set "VER=%%v"

set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if exist "%ISCC%" (
  echo.
  echo === Armando el instalador %VER% ===
  if not exist dist mkdir dist
  "%ISCC%" "/DAppVersion=%VER%" windows\installer\baudex.iss
  if errorlevel 1 goto :fin_error
  echo.
  echo LISTO: dist\Baudex-Setup-%VER%.exe
  if not defined CI start "" explorer "%~dp0dist"
) else (
  echo.
  echo LISTO: la app quedo en build\windows\x64\runner\Release\Baudex.exe
  echo (Para armar tambien el instalador, instala Inno Setup 6 y vuelve a ejecutar.^)
  if not defined CI start "" explorer "%~dp0build\windows\x64\runner\Release"
)
if not defined CI pause
exit /b 0

:fin_error
echo.
echo [ERROR] No se pudo compilar. Copia el texto de arriba y enviamelo.
if not defined CI pause
exit /b 1
