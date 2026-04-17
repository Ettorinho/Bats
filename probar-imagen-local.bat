@echo off
:: Script de prueba para mostrar imagen localmente

:: CAMBIA ESTA RUTA por tu imagen real
set IMAGEN=C:\ruta\a\tu\imagen.jpg

echo Verificando imagen...
if not exist "%IMAGEN%" (
    echo [ERROR] No se encuentra la imagen: %IMAGEN%
    pause
    exit /b 1
)

echo [OK] Imagen encontrada
echo.
echo Mostrando imagen...

:: Crear script PowerShell temporal
set SCRIPT_PS=%TEMP%\test_imagen.ps1

(
echo Add-Type -AssemblyName System.Windows.Forms
echo Add-Type -AssemblyName System.Drawing
echo.
echo try {
echo     $form = New-Object System.Windows.Forms.Form
echo     $form.Text = "PRUEBA - MENSAJE IMPORTANTE"
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
echo     $form.Controls.Add^($pictureBox^)
echo     $form.Add_Shown^({$form.Activate^(^)}^)
echo     [void]$form.ShowDialog^(^)
echo     $pictureBox.Image.Dispose^(^)
echo     Write-Host "[OK] Imagen mostrada correctamente"
echo } catch {
echo     Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
echo     pause
echo }
) > "%SCRIPT_PS%"

:: Ejecutar PowerShell (SIN ocultar ventana para ver errores)
powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_PS%"

echo.
echo Proceso completado
pause

:: Limpiar
del "%SCRIPT_PS%" 2>nul
