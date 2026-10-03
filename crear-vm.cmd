@echo off
rem =====================================================================
rem  crear-vm.cmd - Crea una VM en VMware Workstation (IaC con cmd.exe)
rem  ETAPA 1: lectura de parametros y ayuda. Aun no crea nada.
rem
rem  Codigos de salida: 0 = correcto | 1 = fallo de ejecucion
rem                     2 = parametros invalidos
rem =====================================================================
setlocal EnableExtensions DisableDelayedExpansion

rem ---------- Valores por defecto ----------
set "NAME=VM_Taller"
set "BASEDIR=%USERPROFILE%\Documents\Virtual Machines"
set "ISO="
set "CPUS=2"
set "MEM=2048"
set "DISK=20"
set "NET=nat"
set "START=0"
set "DRY=0"
set "FORCE=0"

rem ---------- Lectura de parametros ----------
:parse
if "%~1"=="" goto :parsed
set "ARG=%~1"
if /i "%ARG%"=="-h"      goto :help
if /i "%ARG%"=="--help"  goto :help
if /i "%ARG%"=="--start"   set "START=1" & shift & goto :parse
if /i "%ARG%"=="--dry-run" set "DRY=1"   & shift & goto :parse
if /i "%ARG%"=="--force"   set "FORCE=1" & shift & goto :parse
set "KEY="
if /i "%ARG%"=="--name" set "KEY=NAME"
if /i "%ARG%"=="--dir"  set "KEY=BASEDIR"
if /i "%ARG%"=="--iso"  set "KEY=ISO"
if /i "%ARG%"=="--cpus" set "KEY=CPUS"
if /i "%ARG%"=="--mem"  set "KEY=MEM"
if /i "%ARG%"=="--disk" set "KEY=DISK"
if /i "%ARG%"=="--net"  set "KEY=NET"
if not defined KEY goto :unknown
if "%~2"=="" goto :missing
set "%KEY%=%~2"
shift
shift
goto :parse

:parsed
echo.
echo === crear-vm: configuracion recibida ===
echo   Nombre : %NAME%
echo   Carpeta: %BASEDIR%
echo   CPUs   : %CPUS%   RAM: %MEM% MB   Disco: %DISK% GB
echo   Red    : %NET%
if defined ISO ( echo   ISO    : "%ISO%" ) else ( echo   ISO    : ^(ninguna^) )
echo   Start=%START%  Dry-run=%DRY%  Force=%FORCE%
echo.
echo ^(Etapa 1: todavia no se crea nada.^)
exit /b 0

rem ---------- Errores de parametros ----------
:unknown
echo ERROR: parametro desconocido "%ARG%". Use --help.
exit /b 2

:missing
echo ERROR: falta el valor de %ARG%. Use --help.
exit /b 2

:help
echo Uso: crear-vm.cmd [opciones]
echo.
echo   --name NOMBRE   Nombre de la VM ^(defecto: VM_Taller^)
echo   --dir RUTA      Carpeta base ^(defecto: Documents\Virtual Machines^)
echo   --iso RUTA      Imagen ISO de instalacion ^(si no existe, falla^)
echo   --cpus N        Procesadores virtuales ^(defecto: 2^)
echo   --mem MB        Memoria RAM en MB ^(defecto: 2048^)
echo   --disk GB       Tamano del disco en GB, dinamico ^(defecto: 20^)
echo   --net MODO      nat ^| bridged ^| hostonly ^(defecto: nat^)
echo   --start         Enciende la VM al terminar
echo   --dry-run       Simula sin crear ni modificar nada
echo   --force         Recrea la VM si ya existe ^(y esta apagada^)
echo   -h, --help      Muestra esta ayuda
echo.
echo Salida: 0 correcto, 1 fallo de ejecucion, 2 parametros invalidos.
echo Ejemplo: crear-vm.cmd --name ubuntu1 --iso C:\isos\ubuntu.iso --start
exit /b 0
