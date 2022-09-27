@echo on
echo bienvenido, inserte el nombre del video a obtener la duracion
set /p video=
echo se procesa el video %video%
for /f "delims=" %%i in (
'ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 %video%'
) do set output=%%i
echo obtenido: %output%
set /a doble= "output * 2"
echo x2: %doble%
@pause
