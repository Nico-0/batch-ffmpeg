@echo off
:: Extrae una cantidad definida de imagenes de la primera mitad del video
set /a cantidad = 6
set NLM=^


set NL=^^^%NLM%%NLM%^%NLM%%NLM%

echo bienvenido, inserte el nombre del video a extraer 6 frames
set /p video=
echo se procesa el video %video%
for /f "delims=" %%i in (
'ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 %video%'
) do set output=%%i
echo duracion obtenida: %output%
set /a mitad= "output / 2"
echo mitad: %mitad%
set /a fraccion = "mitad / cantidad"
echo %fraccion%
setlocal enableDelayedExpansion
for /l %%x in (1,1,%cantidad%) do (
	set /a current = current + fraccion
	echo !current!
	echo %NL% fraccion %%x: !current! %NL%
	ffmpeg -ss !current! -i !video! -vframes 1 !video!_%%x.png
)
endlocal
echo %cantidad% frames creados, chequee la carpeta
@pause
