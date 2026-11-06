# YouTube Plugin Online

Plugin personal para VirtualDJ Pro en Windows x64. Busca videos de YouTube y prepara un MP4 con imagen y sonido para cargarlo en un deck. La primera carga descarga el video a la cachÃ© local.

## InstalaciÃ³n

Ejecuta el instalador de Windows y sigue las instrucciones. Requiere internet, VirtualDJ Pro y Windows 10 u 11 de 64 bits. Usa el puerto local 8766 y no modifica VDJ Companion Source. Reinicia VirtualDJ y abre Online Music > YouTube Plugin Online.

Los MP4 quedan en `data/video-cache` y todavÃ­a no se borran automÃ¡ticamente. La limpieza automÃ¡tica y el historial son trabajo pendiente. El plugin es una adaptaciÃ³n de [VDJ Companion](https://github.com/rcsy-px/vdj-stream), bajo licencia MIT; conserva LICENSE. No estÃ¡ afiliado a YouTube ni a VirtualDJ. El uso de videos estÃ¡ sujeto a las condiciones del servicio y a los derechos del contenido.

## Preparar una distribución

En Windows con .NET Framework y PowerShell, ejecuta `powershell -ExecutionPolicy Bypass -File scripts/build-installer.ps1`. Se generan un instalador `.exe` y un archivo SHA-256 en `dist`. El instalador requiere conexión y debe ejecutarse con VirtualDJ cerrado.

El comprobador consulta este repositorio, no el repositorio original. GitHub no ofrece acceso anónimo a versiones de un repositorio privado: hasta que se configure un canal de actualizaciones autorizado, la aplicación puede mostrar que la consulta no está disponible. No incluye credenciales ni instala actualizaciones automáticamente.

Antes de una distribución pública, revisar permisos para los contenidos y la fuente, las licencias de dependencias y SDK, el nombre y las reglas de la tienda. El hecho de que el código original tenga licencia MIT no concede derechos sobre contenido de YouTube.
