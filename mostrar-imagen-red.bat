@echo off
setlocal enabledelayedexpansion
:: ==========================================
:: MOSTRAR IMAGEN EN EQUIPOS DE RED
:: Repositorio: Ettorinho/Bats
:: ==========================================

title Mostrar Imagen en Red
color 0A

:: ==========================================
:: CONFIGURACION
:: ==========================================

:: Ruta de la imagen (debe estar en carpeta compartida de red)
set IMAGEN=\\SERVIDOR\compartido\alerta.jpg

:: Archivo con lista de equipos (IPs o nombres)
set LISTA_EQUIPOS=equipos.txt

:: Tiempo de visualización en segundos (0 = hasta que usuario cierre)
set TIEMPO=30

:: ==========================================
:: VERIFICACIONES
:: ==========================================
echo.
echo ==========================================
echo   MOSTRAR IMAGEN EN EQUIPOS DE RED
echo ==========================================
echo.

:: Verificar que existe el archivo de equipos
if not exist "%LISTA_EQUIPOS%" (
echo [ERROR] No se encuentra el archivo: %LISTA_EQUIPOS%
echo.
echo Crea el archivo "%LISTA_EQUIPOS%" con la lista de equipos
echo (una IP o nombre de equipo por linea)
echo.
echo Ejemplo:
echo 192.168.1.10
echo 192.168.1.11
echo PC-OFICINA-01
echo.
echo pause
exit /b 1
)

:: Verificar que existe psexec
where psexec >nul 2>nul
if %errorlevel% neq 0 (
echo [ERROR] No se encuentra PsExec
echo.
echo Descarga PsExec de: https://learn.microsoft.com/en-us/sysinternals/downloads/psexec
echo Coloca psexec.exe en C:\Windows\System32 o en esta carpeta
echo.
echo pause
exit /b 1
)

:: Verificar que existe la imagen
if not exist "%IMAGEN%" (
echo [ERROR] No se encuentra la imagen: %IMAGEN%
echo.
echo Verifica que:
echo 1. La ruta sea correcta
echo 2. La carpeta este compartida en red
echo 3. Tengas permisos de acceso
echo.
echo pause
exit /b 1
)

echo [OK] Imagen encontrada: %IMAGEN%
echo [OK] Lista de equipos: %LISTA_EQUIPOS%
echo.

:: Mostrar equipos a procesar
echo Equipos a procesar:
echo ------------------
set CONTADOR=0
for /f "usebackq tokens=* delims=" %%i in ("%LISTA_EQUIPOS%") do (
set LINEA=%%i
    :: Ignorar líneas vacías y comentarios
    if not "!LINEA!"=="" (
echo !LINEA! | findstr /r "^#" >nul
        if errorlevel 1 (
            set /a CONTADOR+=1
            echo   [!CONTADOR!] %%i
        )
    )
)

if %CONTADOR%==0 (
echo [ERROR] No hay equipos válidos en %LISTA_EQUIPOS%
echo.
pause
exit /b 1
)

echo ------------------
echo Total: %CONTADOR% equipo(s)
echo.
pause

:: ==========================================
:: CREAR SCRIPT POWERSHELL TEMPORAL
:: ==========================================
set SCRIPT_PS=%TEMP%\mostrar_imagen_%RANDOM%.ps1

echo Creando script PowerShell...

(
echo Add-Type -AssemblyName System.Windows.Forms
echo Add-Type -AssemblyName System.Drawing
echo.
echo try {
echo     $form = New-Object System.Windows.Forms.Form
echo     $form.Text = "MENSAJE IMPORTANTE"
echo     $form.Size = New-Object System.Drawing.Size^(900,700^)
echo     $form.StartPosition = "CenterScreen"
echo     $form.TopMost = $true
echo     $form.FormBorderStyle = "FixedDialog"
echo     $form.MaximizeBox = $false
echo     $form.BackColor = [System.Drawing.Color]::Black
echo.
echo     $pictureBox = New-Object System.Windows.Forms.PictureBox
echo     $pictureBox.Image = [System.Drawing.Image]::FromFile^('%IMAGEN%'^)
echo     $pictureBox.SizeMode = "Zoom"
echo     $pictureBox.Dock = "Fill"
echo.
echo     # Auto-cerrar después de X segundos
echo     if^(%TIEMPO% -gt 0^) {
echo         $timer = New-Object System.Windows.Forms.Timer
echo         $timer.Interval = %TIEMPO% * 1000
echo         $timer.Add_Tick^({$form.Close^(^)}^)
echo         $timer.Start^(^)
echo     }
echo.
echo     $form.Add_Shown^({$form.Activate^(^)}^)
echo     [void]$form.ShowDialog^(^)
echo     $pictureBox.Image.Dispose^(^)
echo } catch {
echo     [System.Windows.Forms.MessageBox]::Show^("Error al mostrar imagen: $_"^)
echo }
) > "%SCRIPT_PS%"

echo [OK] Script creado
echo.

:: ==========================================
:: ENVIAR A EQUIPOS
:: ==========================================
echo Enviando imagen a equipos...
echo.

set EXITOSOS=0
set FALLIDOS=0

for /f "usebackq tokens=* delims=" %%E in ("%LISTA_EQUIPOS%") do (
set EQUIPO=%%E
    
    :: Ignorar líneas vacías y comentarios
    if not "!EQUIPO!"=="" (
echo !EQUIPO! | findstr /r "^#" >nul
        if errorlevel 1 (
echo [*] Conectando con: !EQUIPO!
            
            :: Verificar conectividad
            ping -n 1 -w 1000 !EQUIPO! >nul 2>nul
            if !errorlevel! equ 0 (
echo     [OK] Equipo accesible
                
                :: Ejecutar script remoto
                psexec \\!EQUIPO! -s -d -i 1 powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT_PS%" 2>nul
                
                if !errorlevel! equ 0 (
echo     [OK] Imagen enviada correctamente
                    set /a EXITOSOS+=1
                ) else (
echo     [ERROR] No se pudo ejecutar remotamente
                    set /a FALLIDOS+=1
                )
            ) else (
echo     [ERROR] Equipo no responde
                set /a FALLIDOS+=1
            )
echo.
        )
    )
)

:: ==========================================
:: LIMPIEZA
:: ==========================================
echo Limpiando archivos temporales...
del "%SCRIPT_PS%" 2>nul

echo.
echo ==========================================
echo   RESUMEN DEL PROCESO
echo ==========================================
echo.
echo Exitosos: %EXITOSOS%
echo Fallidos:  %FALLIDOS%
echo Total:     %CONTADOR%
echo.
echo ==========================================
echo   PROCESO COMPLETADO
echo ==========================================
echo.
pause
