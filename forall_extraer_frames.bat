@echo off
:: Extrae una cantidad definida de imagenes de la primera mitad del video con divisor = 2
:: "4/3" son 3/4
:: 3 son 1/3
:: 1 es todo

set /a cantidad = 4
set /a numerador = 9
set /a denominador = 10

for %%a in ("*.mp4") do (
	echo se procesa el video %%a
	
	for /f "delims=" %%i in (
	'ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "%%a"'
	) do set output=%%i
	echo duracion obtenida: !output!
	set /a intervalo = "(output * numerador * 1000) / (denominador * 1000)"
	echo intervalo: !intervalo!
	set /a fraccion = "intervalo / cantidad"
	echo primer fraccion: !fraccion!
	
	:: nombre fuera de delayedExpansion para que funcionen filenames con !
	set "fullname=%%a"
	setlocal enableDelayedExpansion
	for /l %%x in (1,1,%cantidad%) do (
		set /a current = current + fraccion
		echo current: !current!
		echo %NL% fraccion %%x: !current! %NL%
		set /a actual = %%x
		
		IF !actual! LSS 10 (
		ffmpeg -ss !current! -i "!fullname!" -vframes 1 "!fullname!_0%%x.png") else (
		ffmpeg -ss !current! -i "!fullname!" -vframes 1 "!fullname!_%%x.png")

	)
	endlocal
	echo %cantidad% frames creados, chequee la carpeta
)

@pause
