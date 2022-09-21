@echo off
:: Extrae una cantidad definida de imagenes de la primera mitad del video con divisor = 2
:: "4/3" son 3/4
:: 3 son 1/3
:: 1 es todo

set /a cantidad = 14
set /a divisor = "1"

for %%a in ("*.mp4") do (
	echo se procesa el video %%a
	for /f "delims=" %%i in (
	'ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "%%a"'
	) do set output=%%i
	echo duracion obtenida: %output%
	set /a mitad= "output / divisor"
	echo mitad: %mitad%
	set /a fraccion = "mitad / cantidad"
	echo %fraccion%
	setlocal enableDelayedExpansion
	for /l %%x in (1,1,%cantidad%) do (
		set /a current = current + fraccion
		echo !current!
		echo %NL% fraccion %%x: !current! %NL%
		set /a actual = %%x
		IF !actual! LSS 10 (
		ffmpeg -ss !current! -i "%%a" -vframes 1 "%%a_0%%x.png") else (
		ffmpeg -ss !current! -i "%%a" -vframes 1 "%%a_%%x.png")
	)
	endlocal
	echo %cantidad% frames creados, chequee la carpeta
)

@pause
