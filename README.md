# Taller de IaC: creación de una VM en VMware Workstation con un script `.cmd`

**Autor:** Valentina Castañeda · **Curso:** Diplomado Seguridad en Devops · **Fecha:** 03/10/2026

`crear-vm.cmd` es un script de `cmd.exe` que crea (y opcionalmente enciende) una
máquina virtual en **VMware Workstation** a partir de parámetros. Es un ejemplo
básico de **Infraestructura como Código (IaC)**: la VM se describe y se crea
siempre de la misma manera, sin pasos manuales.

## Requisitos

- Windows con **VMware Workstation** instalado (se usan `vmrun.exe` y
  `vmware-vdiskmanager.exe`).
- Una imagen ISO de instalación (por ejemplo, Ubuntu) si se quiere instalar un sistema.
- Solo se usan comandos de Windows y las utilidades incluidas con Workstation.
  No hay PowerShell, Python ni otros lenguajes.

El script busca VMware en este orden: la variable de entorno `VMWARE_HOME`, luego
`%ProgramFiles(x86)%\VMware\VMware Workstation` y por último
`%ProgramFiles%\VMware\VMware Workstation`. No contiene rutas personales fijas.

## Uso

```
crear-vm.cmd [opciones]
```

| Parámetro | Valor por defecto | Descripción |
|---|---|---|
| `--name NOMBRE` | `VM_Taller` | Nombre de la VM. Solo letras, números, punto, guion y guion bajo. Nombra la carpeta y los archivos. |
| `--dir RUTA` | `Documents\Virtual Machines` del usuario | Carpeta base donde se crea la carpeta de la VM. |
| `--iso RUTA` | *(ninguna)* | Imagen ISO de instalación. Si se indica y no existe, el script falla. |
| `--cpus N` | `2` | Procesadores virtuales (entero positivo). |
| `--mem MB` | `2048` | Memoria RAM en MB (entero positivo). |
| `--disk GB` | `20` | Tamaño del disco en GB (disco de crecimiento dinámico). |
| `--net MODO` | `nat` | Modo de red: `nat`, `bridged` o `hostonly`. |
| `--start` | desactivado | Enciende la VM al terminar y comprueba que esté en ejecución. |
| `--dry-run` | desactivado | Simula: muestra lo que haría sin crear ni modificar nada. |
| `--force` | desactivado | Recrea una VM que ya existe (solo si está apagada). |
| `-h`, `--help` | | Muestra la ayuda y termina. |

El sistema operativo invitado es **Ubuntu de 64 bits** (`ubuntu-64`).

### Ejemplos

```
:: Ver la ayuda
crear-vm.cmd --help

:: Simular, sin crear nada
crear-vm.cmd --name prueba --dry-run

:: Crear una VM con ISO
crear-vm.cmd --name ubuntu1 --dir C:\VMs\pruebas --iso C:\isos\ubuntu.iso

:: Crear con parámetros personalizados y encender
crear-vm.cmd --name vm4 --cpus 4 --mem 4096 --disk 30 --net bridged --iso C:\isos\ubuntu.iso --start

:: Recrear una VM existente (apagada)
crear-vm.cmd --name ubuntu1 --dir C:\VMs\pruebas --iso C:\isos\ubuntu.iso --force
```

## Códigos de salida

| Código | Significado |
|---|---|
| `0` | Todo correcto |
| `1` | Falló la ejecución (herramientas no encontradas, la VM ya existe, error al crear o encender) |
| `2` | Parámetros inválidos |

Para ver el código después de ejecutar: `echo %errorlevel%`.

## Qué hace el script

1. **Valida** los parámetros y las herramientas de VMware antes de tocar el disco.
2. **Comprueba** si la VM ya existe (idempotencia): si existe, se detiene salvo que se use `--force`.
3. **Crea** la carpeta de la VM.
4. **Crea** el disco virtual dinámico con `vmware-vdiskmanager`.
5. **Genera** el archivo `.vmx` a partir de los parámetros.
6. **Registro:** Workstation no exige registrar la VM; el archivo `.vmx` ya se puede abrir.
7. **Enciende** la VM con `vmrun` solo si se pidió `--start`, y **valida** el resultado.

Si algo falla durante la creación, el script elimina la carpeta que él mismo creó.

## Pruebas de aceptación

Las evidencias (capturas) están en la carpeta [`evidencias/`](evidencias/).

| # | Prueba | Resultado esperado |
|---|---|---|
| T1 | `--help` | Muestra la ayuda; código `0` |
| T2 | `--name prueba --dry-run` | Muestra los pasos; no crea archivos; código `0` |
| T3 | `--name "mi vm"` | Rechaza el nombre; código `2` |
| T4 | `--cpus 0` y `--mem abc` | Rechaza los valores; código `2` |
| T5 | `--net wifi` | Rechaza el modo de red; código `2` |
| T6 | `--iso` con ruta inexistente | Falla antes de crear nada; código `2` |
| T7 | Creación real con ISO | Carpeta con `.vmx` y `.vmdk`; la VM abre en Workstation |
| T8 | Repetir T7 | Se detiene sin modificar la VM; código `1` |
| T9 | Repetir T7 con `--force` | Recrea la VM |
| T10 | Creación real con `--start` | La VM queda encendida y el script lo comprueba |
| T11 | `--cpus 4 --mem 4096 --disk 30 --net bridged` | La VM refleja esos valores |

## Estructura del repositorio

```
.
├── crear-vm.cmd        # el script
├── README.md           # este archivo
├── informe/            # informe en PDF (APA 7)
├── evidencias/         # capturas de las pruebas T1 a T11
├── .gitignore          # no se suben discos virtuales, ISOs ni logs
└── .gitattributes      # mantiene finales de línea CRLF en los .cmd
```

## Notas

- El script es solo ASCII y usa finales de línea CRLF a propósito: `cmd.exe` es
  sensible a ambos (ver el informe).
- No se suben archivos `.vmdk`, `.iso`, `.nvram` ni otros archivos pesados de VM.
- Si una ruta de ISO contiene caracteres con tilde, pueden no guardarse bien en
  el `.vmx` por la codificación de `cmd`; use rutas sin acentos.

## Licencia

MIT (ver `LICENSE`).
