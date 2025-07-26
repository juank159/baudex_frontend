@echo off
echo ==========================================
echo    VERIFICANDO COLA DE IMPRESION
echo ==========================================
echo.
echo Trabajos en cola de impresion:
echo.
wmic printjob get name,status,document,pagesprinted
echo.
echo ==========================================
echo Estado de las impresoras:
echo.
wmic printer get name,workoffline,printerstatus
echo.
echo ==========================================
echo Si hay trabajos en cola, ve a:
echo Panel de Control ^> Impresoras ^> POSPrinter POS-80C
echo y verifica si esta pausada o hay errores
echo ==========================================
pause