@echo on

:: crea una intro al video con los videos preview que haya en la carpeta
:: para todos los videos de la carpeta
:: los videos se encuentran de la forma: nombrevideo-wildcard-.ext
:: mantiene la fecha de modificacion de los videos originales
:: se puede poner un unico video de 5 seg, pero si hay varios en la carpeta los toma todos en orden
:: powershell nombres no pueden tener doble espacio, ni parentesis ni corchetes


if not exist "%~dp0\temp" mkdir "%~dp0\temp"
if not exist "%~dp0\fix_intro_vid" mkdir "%~dp0\fix_intro_vid"

setlocal enableDelayedExpansion
for %%a in ("*.mp4", "*.mpg", "*.wmv") do (

	echo se procesa el video %%a
	if exist "%~dp0\temp\%%a_vid.txt" del "%~dp0\temp\%%a_vid.txt"
	
	
	:: agregar nombres de videos a leer al txt
	set /a contador = 0
	for %%v in ("prevs\%%~na*%%~xa") do (
		set /a "contador = contador + 1"
		
		echo file '%%v' >> "temp/%%a_vid.txt"
	)
	echo file '%%a' >> "temp/%%a_vid.txt"
	
	echo contador: !contador! videos tomados
	

	:: crear video final
	:: -dn para no copiar los streams data. Audio y video se ordenaron previamente segun el video original
	ffmpeg -safe 0 -f concat -i "%~dp0\temp\%%a_vid.txt" -c copy -dn "%~dp0\fix_intro_vid\%%~na - fix%%~xa"

	:: poner fecha de modificacion original
	powershell  ^(ls '%~dp0\fix_intro_vid\%%~na - fix%%~xa'^).LastWriteTime = ^(ls '%%a'^).LastWriteTime

)
endlocal

echo completado
@pause