@echo off
echo ==========================================
echo    BUSCANDO IMPRESORAS USB INSTALADAS
echo ==========================================
echo.
echo Impresoras instaladas en el sistema:
echo.
wmic printer get name,portname /format:table
echo.
echo ==========================================
echo Busca tu impresora termica en la lista
echo y copia el NOMBRE exacto para usar en la app
echo ==========================================
pause