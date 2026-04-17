# Scripts BAT - Mostrar Imagen en Red

Scripts para mostrar imágenes en equipos locales y remotos de una red Windows.

## 📋 Scripts disponibles

### 1. `probar-imagen-local.bat`
Script de prueba para verificar que la funcionalidad de mostrar imágenes funciona correctamente en tu equipo local.

**Uso:**
1. Edita la línea 5: `set IMAGEN=C:\ruta\a\tu\imagen.jpg`
2. Ejecuta el script
3. Si ves la imagen, todo funciona correctamente

### 2. `mostrar-imagen-red.bat`
Script principal para mostrar imágenes en múltiples equipos de la red.

**Configuración:**

1. **Edita la ruta de la imagen** (línea 20):
   - **Para equipo local:** `set IMAGEN=C:\imagenes\aviso.jpg`
   - **Para equipos remotos:** `set IMAGEN=\\SERVIDOR\compartido\aviso.jpg`

2. **Crea el archivo `equipos.txt`** con los equipos destino:
   ```text
   # Equipos a procesar
   10.35.240.230
   192.168.1.50
   PC-OFICINA-01
   localhost
   ```

3. **Instala PsExec** (solo para equipos remotos):
   - Descarga: https://learn.microsoft.com/en-us/sysinternals/downloads/psexec
   - Coloca `psexec.exe` en `C:\Windows\System32` o en la carpeta del script

4. **Ejecuta como administrador**

## 🔧 Configuración adicional

### Tiempo de visualización
Edita la línea 30 para cambiar cuánto tiempo se muestra la imagen:
```batchfile
set TIEMPO=120  :: 120 segundos (2 minutos)
set TIEMPO=0    :: Hasta que el usuario cierre manualmente
```

### Personalizar la ventana
Edita el script PowerShell generado para modificar:
- Tamaño de ventana: `New-Object System.Drawing.Size(900,700)`
- Título: `$form.Text = "MENSAJE IMPORTANTE"`
- Color de fondo: `$form.BackColor = [System.Drawing.Color]::Black`

## ⚠️ Requisitos

### Para equipo local:
- ✅ Windows con PowerShell
- ✅ Permisos para ejecutar scripts

### Para equipos remotos:
- ✅ PsExec instalado
- ✅ Ejecutar como administrador
- ✅ Credenciales de administrador en equipos destino
- ✅ Equipos accesibles en la red (ping exitoso)
- ✅ Firewall permite conexiones remotas (puerto 445)
- ✅ Imagen en carpeta compartida accesible por todos los equipos

## 📊 Logs

El script genera logs en: `%TEMP%\mostrar-imagen-red.log`

## 🐛 Solución de problemas

### La imagen no se muestra en mi equipo local
1. Prueba primero con `probar-imagen-local.bat`
2. Verifica que la ruta de la imagen sea correcta y local (no UNC)
3. Asegúrate de que el archivo existe: `dir C:\ruta\a\imagen.jpg`

### La imagen no se muestra en equipos remotos
1. Verifica que PsExec esté instalado: `where psexec`
2. Confirma conectividad: `ping 192.168.1.50`
3. Usa ruta de red compartida, no local
4. Verifica permisos de red y firewall

### Error "No se encuentra el archivo equipos.txt"
1. El archivo debe estar en la misma carpeta que el script .bat
2. Verifica el nombre exacto (sin doble extensión .txt.txt)
3. Asegúrate de ejecutar el script desde su propia carpeta

## 📝 Ejemplos

### Ejemplo 1: Mostrar solo en mi equipo
**equipos.txt:**
```text
localhost
```

**Configuración:**
```batchfile
set IMAGEN=C:\avisos\mantenimiento.jpg
```

### Ejemplo 2: Mostrar en varios equipos de la red
**equipos.txt:**
```text
192.168.1.10
192.168.1.11
192.168.1.12
```

**Configuración:**
```batchfile
set IMAGEN=\\SERVIDOR\compartido\aviso-urgente.jpg
```

### Ejemplo 3: Mezcla de local y remotos
**equipos.txt:**
```text
localhost
10.35.240.230
PC-OFICINA-01
```

**Configuración:**
```batchfile
set IMAGEN=C:\imagenes\aviso.jpg
```

> El script detecta automáticamente si el equipo es local o remoto y actúa en consecuencia.

## 📄 Licencia

Scripts de uso libre para administración de redes Windows.
