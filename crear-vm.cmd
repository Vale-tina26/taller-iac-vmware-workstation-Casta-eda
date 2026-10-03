@echo off
rem =====================================================================
rem  crear-vm.cmd - Crea una VM en VMware Workstation (Infraestructura
rem  como Codigo con cmd.exe). Solo ASCII a proposito (ver informe, Q8).
rem  ETAPA 2: validaciones, herramientas, idempotencia y --dry-run.
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
set "CREATED=0"

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
rem ---------- [1/7] Validacion de entradas (antes de tocar el disco) ----------
echo "%NAME%"| findstr /r /c:"^\"[A-Za-z0-9_][A-Za-z0-9._-]*\"$" >nul
if errorlevel 1 goto :badname

call :chknum --cpus "%CPUS%" || exit /b 2
call :chknum --mem  "%MEM%"  || exit /b 2
call :chknum --disk "%DISK%" || exit /b 2

set "NETOK=0"
if /i "%NET%"=="nat"      set "NETOK=1" & set "NET=nat"
if /i "%NET%"=="bridged"  set "NETOK=1" & set "NET=bridged"
if /i "%NET%"=="hostonly" set "NETOK=1" & set "NET=hostonly"
if "%NETOK%"=="0" goto :badnet

if not defined ISO goto :isook
if not exist "%ISO%" goto :badiso
for %%I in ("%ISO%") do set "ISO=%%~fI"
:isook

for %%I in ("%BASEDIR%") do set "BASEDIR=%%~fI"
if "%BASEDIR:~-1%"=="\" set "BASEDIR=%BASEDIR:~0,-1%"
set "VMDIR=%BASEDIR%\%NAME%"
set "VMX=%VMDIR%\%NAME%.vmx"
set "VMDK=%VMDIR%\%NAME%.vmdk"

rem ---------- Herramientas de VMware ----------
set "VMWDIR="
if defined VMWARE_HOME if exist "%VMWARE_HOME%\vmrun.exe" set "VMWDIR=%VMWARE_HOME%"
if not defined VMWDIR if exist "%ProgramFiles(x86)%\VMware\VMware Workstation\vmrun.exe" set "VMWDIR=%ProgramFiles(x86)%\VMware\VMware Workstation"
if not defined VMWDIR if exist "%ProgramFiles%\VMware\VMware Workstation\vmrun.exe" set "VMWDIR=%ProgramFiles%\VMware\VMware Workstation"
if not defined VMWDIR goto :notools
if not exist "%VMWDIR%\vmware-vdiskmanager.exe" goto :notools
set "VMRUN=%VMWDIR%\vmrun.exe"
set "VDM=%VMWDIR%\vmware-vdiskmanager.exe"
goto :toolsok

:notools
if "%DRY%"=="1" (
    echo [AVISO] No se encontraron las herramientas de VMware ^(modo dry-run: continuo^).
    set "VMRUN=vmrun.exe"
    set "VDM=vmware-vdiskmanager.exe"
    goto :toolsok
)
echo ERROR: no se encontraron vmrun.exe / vmware-vdiskmanager.exe.
echo        Instale VMware Workstation o defina VMWARE_HOME con su carpeta.
exit /b 1

:toolsok
echo.
echo === crear-vm: configuracion ===
echo   Nombre : %NAME%
echo   Carpeta: %VMDIR%
echo   CPUs   : %CPUS%   RAM: %MEM% MB   Disco: %DISK% GB ^(dinamico^)
echo   Red    : %NET%
if defined ISO ( echo   ISO    : "%ISO%" ) else ( echo   ISO    : ^(ninguna^) )
echo   Start=%START%  Dry-run=%DRY%  Force=%FORCE%
echo.

rem ---------- Idempotencia ----------
set "EXISTS=0"
if exist "%VMDIR%" set "EXISTS=1"
if "%EXISTS%"=="0" goto :plan
if "%FORCE%"=="0" goto :already
if not exist "%VMX%" goto :notvm

:plan
if "%DRY%"=="0" goto :real
echo [dry-run] Simulacion: no se crea ni se modifica nada.
echo [dry-run] 1. Validar parametros y herramientas ......... OK
if "%EXISTS%"=="1" echo [dry-run] 2. Eliminar VM existente ^(--force^): "%VMDIR%"
echo [dry-run] 2. Crear carpeta: "%VMDIR%"
echo [dry-run] 3. "%VDM%" -c -s %DISK%GB -a lsilogic -t 0 "%VMDK%"
echo [dry-run] 4. Generar "%VMX%"
echo [dry-run] 5. Registro: Workstation no lo requiere ^(basta abrir el .vmx^)
if "%START%"=="1" echo [dry-run] 6. "%VMRUN%" -T ws start "%VMX%" nogui
echo [dry-run] 7. Validar existencia de archivos ^(y ejecucion si --start^)
exit /b 0

:real
echo ^(Etapa 2: la creacion real aun no esta implementada.^)
exit /b 0

rem ---------- Subrutinas ----------
:chknum
echo "%~2"| findstr /r /c:"^\"[1-9][0-9]*\"$" >nul
if errorlevel 1 (
    echo ERROR: %~1 debe ser un entero positivo.
    echo        Valor recibido: "%~2"
    exit /b 1
)
exit /b 0

rem ---------- Manejo de errores ----------



:already
echo ERROR: la VM ya existe en "%VMDIR%". Use --force para recrearla.
exit /b 1

:notvm
echo ERROR: la carpeta existe pero no contiene "%NAME%.vmx"; no se toca.
exit /b 1


:badname
echo ERROR: --name solo admite letras, numeros, punto, guion y guion bajo.
echo        Valor recibido: "%NAME%"
exit /b 2

:badnet
echo ERROR: --net debe ser nat, bridged o hostonly. Recibido: "%NET%"
exit /b 2

:badiso
echo ERROR: la ISO no existe: "%ISO%"
exit /b 2

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
