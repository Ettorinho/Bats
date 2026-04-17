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

:: Ruta de la imagen
:: IMPORTANTE:
:: - Para equipo local: usa ruta local (ej: C:\imagenes\aviso.jpg)
:: - Para equipos remotos: usa carpeta compartida de red (ej: \\SERVIDOR\compartido\aviso.jpg)
:: - La imagen debe ser accesible desde todos los equipos destino
set IMAGEN=C:\ruta\a\tu\imagen.jpg

:: Archivo con lista de equipos (IPs o nombres)
:: Formato del archivo equipos.txt:
::   - Una IP o nombre de equipo por línea
::   - Líneas vacías o que empiezan con # son ignoradas
::   - Ejemplos: 10.35.240.230, localhost, PC-OFICINA-01
set LISTA_EQUIPOS=equipos.txt

:: Tiempo de visualización en segundos (0 = hasta que usuario cierre)
set TIEMPO=30

:: Archivo de log
set LOG=%TEMP%\mostrar-imagen-red.log

:: ==========================================
:: DETECCION DE EQUIPO LOCAL
:: ==========================================
:: Obtener nombre del equipo local
set LOCAL_NAME=%COMPUTERNAME%

:: Obtener IP local (primera IPv4 encontrada)
set LOCAL_IP=
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    if not defined LOCAL_IP (
        set LOCAL_IP=%%a
        set LOCAL_IP=!LOCAL_IP: =!
    )
)

:: ==========================================
:: VERIFICACIONES
:: ==========================================
echo.
echo ==========================================
echo   MOSTRAR IMAGEN EN EQUIPOS DE RED
echo ==========================================
echo.

:: Inicializar log
echo ========================================== > "%LOG%"
echo   MOSTRAR IMAGEN EN EQUIPOS DE RED >> "%LOG%"
echo   %DATE% %TIME% >> "%LOG%"
echo ========================================== >> "%LOG%"
echo   Equipo local: %LOCAL_NAME% >> "%LOG%"
echo   IP local:     %LOCAL_IP% >> "%LOG%"
echo ========================================== >> "%LOG%"
echo. >> "%LOG%"

echo   Equipo local: %LOCAL_NAME%
echo   IP local:     %LOCAL_IP%
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
echo localhost
echo.
pause
exit /b 1
)

:: Verificar que existe psexec (advertencia, no error fatal)
set PSEXEC_OK=0
where psexec >nul 2>nul
if %errorlevel% equ 0 set PSEXEC_OK=1
if %PSEXEC_OK%==0 (
echo [ADVERTENCIA] No se encuentra PsExec - los equipos remotos no podran procesarse
echo   Descarga PsExec de: https://learn.microsoft.com/en-us/sysinternals/downloads/psexec
echo   Coloca psexec.exe en C:\Windows\System32 o en esta carpeta
echo.
echo [ADVERTENCIA] PsExec no disponible - solo se procesaran equipos locales >> "%LOG%"
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
pause
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
echo     $form.Controls.Add^($pictureBox^)
echo     $form.Add_Shown^({$form.Activate^(^)}^)
echo     [void]$form.ShowDialog^(^)
echo     $pictureBox.Image.Dispose^(^)
echo } catch {
echo     [System.Windows.Forms.MessageBox]::Show^("Error al mostrar imagen: $($_.Exception.Message)"^)
echo }
) > "%SCRIPT_PS%"

echo [OK] Script creado: %SCRIPT_PS%
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
            :: Detectar si es equipo local
            set ES_LOCAL=0
            if /i "!EQUIPO!"=="localhost"   set ES_LOCAL=1
            if /i "!EQUIPO!"=="127.0.0.1"  set ES_LOCAL=1
            if /i "!EQUIPO!"=="%LOCAL_IP%" set ES_LOCAL=1
            if /i "!EQUIPO!"=="%LOCAL_NAME%" set ES_LOCAL=1

            if !ES_LOCAL! equ 1 (
                echo [LOCAL] Procesando: !EQUIPO!
                echo [LOCAL] Procesando: !EQUIPO! >> "%LOG%"

                :: Ejecutar directamente sin PsExec
                echo     [INFO] Ejecutando localmente: powershell.exe -ExecutionPolicy Bypass -WindowStyle Normal -File "%SCRIPT_PS%"
                echo     [INFO] Ejecutando localmente: powershell.exe -ExecutionPolicy Bypass -WindowStyle Normal -File "%SCRIPT_PS%" >> "%LOG%"

                start /wait powershell.exe -ExecutionPolicy Bypass -WindowStyle Normal -File "%SCRIPT_PS%"
                set EXIT_CODE=!errorlevel!

                echo     [INFO] Codigo de salida: !EXIT_CODE!
                echo     [INFO] Codigo de salida: !EXIT_CODE! >> "%LOG%"

                if !EXIT_CODE! equ 0 (
                    echo     [OK] Imagen mostrada correctamente ^(LOCAL^)
                    echo     [OK] Imagen mostrada correctamente ^(LOCAL^) >> "%LOG%"
                    set /a EXITOSOS+=1
                ) else (
                    echo     [ERROR] Fallo al mostrar la imagen localmente
                    echo     [ERROR] Fallo al mostrar la imagen localmente >> "%LOG%"
                    set /a FALLIDOS+=1
                )
            ) else (
                echo [REMOTO] Procesando: !EQUIPO!
                echo [REMOTO] Procesando: !EQUIPO! >> "%LOG%"

                if %PSEXEC_OK%==0 (
                    echo     [ERROR] PsExec no disponible - omitiendo equipo remoto
                    echo     [ERROR] PsExec no disponible - omitiendo equipo remoto >> "%LOG%"
                    set /a FALLIDOS+=1
                ) else (
                    :: Verificar conectividad
                    ping -n 1 -w 1000 !EQUIPO! >nul 2>nul
                    if !errorlevel! equ 0 (
                        echo     [OK] Equipo accesible

                        :: Ejecutar remotamente con PsExec mejorado
                        echo     [INFO] Ejecutando: psexec \\!EQUIPO! -i powershell.exe -ExecutionPolicy Bypass -WindowStyle Normal -File "%SCRIPT_PS%"
                        echo     [INFO] Ejecutando: psexec \\!EQUIPO! -i powershell.exe -ExecutionPolicy Bypass -WindowStyle Normal -File "%SCRIPT_PS%" >> "%LOG%"

                        psexec \\!EQUIPO! -i powershell.exe -ExecutionPolicy Bypass -WindowStyle Normal -File "%SCRIPT_PS%"
                        set EXIT_CODE=!errorlevel!

                        echo     [INFO] Codigo de salida: !EXIT_CODE!
                        echo     [INFO] Codigo de salida: !EXIT_CODE! >> "%LOG%"

                        if !EXIT_CODE! equ 0 (
                            echo     [OK] Imagen enviada correctamente ^(REMOTO^)
                            echo     [OK] Imagen enviada correctamente ^(REMOTO^) >> "%LOG%"
                            set /a EXITOSOS+=1
                        ) else (
                            echo     [ERROR] No se pudo ejecutar remotamente
                            echo     [ERROR] No se pudo ejecutar remotamente >> "%LOG%"
                            set /a FALLIDOS+=1
                        )
                    ) else (
                        echo     [ERROR] Equipo no responde
                        echo     [ERROR] Equipo no responde >> "%LOG%"
                        set /a FALLIDOS+=1
                    )
                )
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
echo Log guardado en: %LOG%
echo.
echo ==========================================
echo   PROCESO COMPLETADO
echo ==========================================
echo.

:: Guardar resumen en log
echo. >> "%LOG%"
echo ========================================== >> "%LOG%"
echo   RESUMEN >> "%LOG%"
echo   Exitosos: %EXITOSOS% >> "%LOG%"
echo   Fallidos:  %FALLIDOS% >> "%LOG%"
echo   Total:     %CONTADOR% >> "%LOG%"
echo ========================================== >> "%LOG%"

pause
