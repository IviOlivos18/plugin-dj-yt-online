# YouTube Plugin Online

Plugin personal para VirtualDJ Pro en Windows x64. Busca videos de YouTube y prepara un MP4 con imagen y sonido para cargarlo en un deck. La primera carga descarga el video a la cachÃ© local.

## InstalaciÃ³n

Ejecuta el instalador de Windows y sigue las instrucciones. Requiere internet, VirtualDJ Pro y Windows 10 u 11 de 64 bits. Usa el puerto local 8766 y no modifica VDJ Companion Source. Reinicia VirtualDJ y abre Online Music > YouTube Plugin Online.

Los MP4 quedan en `data/video-cache` y todavÃ­a no se borran automÃ¡ticamente. La limpieza automÃ¡tica y el historial son trabajo pendiente. El plugin es una adaptaciÃ³n de [VDJ Companion](https://github.com/rcsy-px/vdj-stream), bajo licencia MIT; conserva LICENSE. No estÃ¡ afiliado a YouTube ni a VirtualDJ. El uso de videos estÃ¡ sujeto a las condiciones del servicio y a los derechos del contenido.

## Preparar una distribución

En Windows con .NET Framework y PowerShell, ejecuta `powershell -ExecutionPolicy Bypass -File scripts/build-installer.ps1`. Se generan un instalador `.exe` y un archivo SHA-256 en `dist`. El instalador requiere conexión y debe ejecutarse con VirtualDJ cerrado.

El comprobador consulta este repositorio, no el repositorio original. GitHub no ofrece acceso anónimo a versiones de un repositorio privado: hasta que se configure un canal de actualizaciones autorizado, la aplicación puede mostrar que la consulta no está disponible. No incluye credenciales ni instala actualizaciones automáticamente.

Antes de una distribución pública, revisar permisos para los contenidos y la fuente, las licencias de dependencias y SDK, el nombre y las reglas de la tienda. El hecho de que el código original tenga licencia MIT no concede derechos sobre contenido de YouTube.

## Publicar una actualización

Cada versión debe usar el mismo número en `VERSION` y `pyproject.toml`. Genera el instalador con `scripts/build-installer.ps1`, crea una versión de GitHub con etiqueta `vX.Y.Z` y adjunta `Plugin-Online-X.Y.Z-windows-x64-setup.exe` junto con su archivo `.sha256`. El instalador incluye el servicio y la DLL de esa misma versión. El comprobador identifica solamente el instalador correspondiente a la etiqueta y el hash SHA-256 devuelto por GitHub. Un repositorio privado no puede consultarse sin acceso autorizado.

## Comprobación en segundo plano

Al iniciar el servicio se consulta la última versión publicada de GitHub, y después se repite la consulta cada seis horas mientras el servicio siga activo. Si la versión es más reciente y tiene un instalador con el nombre y el SHA-256 esperados, se descarga y verifica en `data/updates`. Esta fase no ejecuta el instalador ni cambia la instalación. Requiere un repositorio y una versión públicos o un mecanismo de acceso autorizado, que no se incluye. No guarda credenciales.

La huella que devuelve GitHub verifica integridad frente a los metadatos de la versión; no sustituye la firma del ejecutable ni una atestación de procedencia. La instalación automática, la ventana de confirmación y la integración con Komi Store aún no están implementadas.
