@echo on

:: crea una intro al video con los videos preview que haya en la carpeta
:: para todos los videos de la carpeta
:: los videos se encuentran de la forma: nombrevideo-wildcard-.ext
:: mantiene la fecha de modificacion de los videos originales
:: se puede poner un unico video de 5 seg, pero si hay varios en la carpeta los toma todos en orden
:: powershell nombres no pueden tener doble espacio, ni parentesis ni corchetes


if not exist "%~dp0\temp" mkdir "%~dp0\temp"
if not exist "%~dp0\fix_intro_vid" mkdir "%~dp0\fix_intro_vid"

for %%a in ("*.mp4", "*.mpg", "*.wmv", "*.avi", "*.mkv") do (
	echo se procesa el video %%a
	if exist "%~dp0\temp\%%a_vid.txt" del "%~dp0\temp\%%a_vid.txt"
	
	:: para nombres con !
	set "fname=%%a"
	set "name=%%~na"
	setlocal enableDelayedExpansion
	set "a=!fname!"
	set "a=!a:'='\''!
	
	set "ext=%%~xa"
	IF "%%~xa"==".wmv" (
	set "ext=.mkv")
	
	:: agregar nombres de videos a leer al txt
	set /a contador = 0
	for %%v in ("prevs\!name!*!ext!") do (
		:: fix para nombres con !
		setlocal DisableDelayedExpansion
		set "mname=%%v"
		setlocal enableDelayedExpansion
		set "nv=!mname!"
		set "nv=!nv:'='\''!
		
		set /a "contador = contador + 1"
		
		echo file '!nv!' >> "temp/!fname!_vid.txt"
		setlocal DisableDelayedExpansion
	)
	setlocal enableDelayedExpansion
	echo file '!a!' >> "temp/!fname!_vid.txt"
	
	echo contador: !contador! videos tomados
	
	:: crear video final
	:: -dn para no copiar los streams data. Audio y video se ordenaron previamente segun el video original
	ffmpeg -safe 0 -f concat -i "%~dp0\temp\!fname!_vid.txt" -c copy -dn "%~dp0\fix_intro_vid\!name! - fix!ext!"

	:: arreglar caracteres para que los lea el string powershell de tipo ''
	set "path_mod=%~dp0\fix_intro_vid\!name! - fix!ext!"
	set "path_mod=!path_mod:'=''!"
	set "path_mod=!path_mod:[=``[!"
	set "path_mod=!path_mod:]=``]!"
	
	set "path_ori=!fname!"
	set "path_ori=!path_ori:'=''!"
	set "path_ori=!path_ori:[=``[!"
	set "path_ori=!path_ori:]=``]!"

	:: poner fecha de modificacion original
	powershell  "(ls '!path_mod!').LastWriteTime = (ls '!path_ori!').LastWriteTime"
	
	endlocal
)


echo completado
@pause




	:: arreglar caracteres para que los lea el string powershell de tipo ''
	set "path_mod=%~dp0\fix_intro_vid\!name! - fix!ext!"
	set path_mod=!path_mod:'=''!
	:: magia para lo que se fumaron los de powershell
	:: no funciona porque toma tambien los ``[ en los `[
	set "path_mod=!path_mod:```[=Æ!"
	set "path_mod=!path_mod:```]=æ!"
	set "path_mod=!path_mod:`[=Ç!"
	set "path_mod=!path_mod:`]=ç!"
	
	set "path_mod=!path_mod:[=``[!"
	set "path_mod=!path_mod:]=``]!"
	
	set "path_mod=!path_mod:Ç=`[!"
	set "path_mod=!path_mod:ç=`]!"
	set "path_mod=!path_mod:Æ=```[!"
	set "path_mod=!path_mod:æ=```]!"
	
	set "path_ori=!fname!"
	set path_ori=!path_ori:'=''!
	
	set "path_ori=!path_ori:```[=Æ!"
	set "path_ori=!path_ori:```]=æ!"
	set "path_ori=!path_ori:`[=Ç!"
	set "path_ori=!path_ori:`]=ç!"
	
	set "path_ori=!path_ori:[=``[!"
	set "path_ori=!path_ori:]=``]!"
	
	set "path_ori=!path_ori:Ç=`[!"
	set "path_ori=!path_ori:ç=`]!"
	set "path_ori=!path_ori:Æ=```[!"
	set "path_ori=!path_ori:æ=```]!"
	
§