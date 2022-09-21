@echo off

set "preset=veryfast"
set "crf=15"
set "audio=-c:a copy"

set "copiar_audio=si"

if "%copiar_audio%"=="no" (
set "audio=-c:a aac")

if not exist "%~dp0\1920encode" mkdir "%~dp0\1920encode"

for %%a in ("*.mp4", "*.mpg", "*.wmv", "*.avi", "*.mkv", "*.3gp") do (
	setlocal enableDelayedExpansion
		
	::obtener ancho
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=width "%%a"'
	) do set ancho=%%i
	echo ancho vale: !ancho!
	::obtener alto
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=height "%%a"'
	) do set alto=%%i
	echo alto vale: !alto!
	::obtener aspect DAR
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=display_aspect_ratio "%%a"'
	) do set dar=%%i
	echo dar vale: !dar!
	
	if "!dar!"=="N/A" (
	set "dar=!ancho!:!alto!")
	echo aspect ratio: !dar!
	
	set "fname=%%a"
	set "name=%%~na"
	set "ext=%%~xa"
	IF "%%~xa"==".wmv" (
	set "ext=.mkv")
	echo nombre: %%a
	

	IF !ancho! GTR !alto! (
	call :mayor_ancho) else (
	call :mayor_alto)
	
	
	call :fixfecha

	endlocal
)

echo Directorio: "%~dp0\1920encode"
echo/
echo end
pause


:mayor_ancho
set /a aspect = "((alto * 100000) / (ancho))"
echo aspect*100000: !aspect!
echo/
set /a nuevo_alto = "((1920 * aspect) / (100000))"
set /a decimal = 1920 * aspect
set /a decimal = !decimal:~4,-4!
echo decimal: !decimal!
IF "!decimal!" GTR "4" (
set /a "nuevo_alto=nuevo_alto+1")

set /a "div2= nuevo_alto %% 2"
if "!div2!" NEQ "0" (
set /a "nuevo_alto=nuevo_alto+1")

echo nuevo ancho: 1920
echo nuevo_alto: !nuevo_alto!
echo/
set "output=%~dp0\1920encode\!name!_1920!ext!"
ffmpeg -i "!fname!" -c:v libx264 -s 1920x!nuevo_alto! -aspect !dar! -preset !preset! -crf !crf! !audio! "!output!"
echo/
exit /b

:mayor_alto
set /a aspect = "((ancho * 100000) / (alto))"
echo aspect*100000: !aspect!
echo/
set /a nuevo_ancho = "((1920 * aspect) / (100000))"
set /a decimal = 1920 * aspect
set /a decimal = !decimal:~4,-4!
echo decimal: !decimal!
IF "!decimal!" GTR "4" (
set /a "nuevo_ancho=nuevo_ancho+1")

set /a "div2= nuevo_ancho %% 2"
if "!div2!" NEQ "0" (
set /a "nuevo_ancho=nuevo_ancho+1")

echo nuevo_ancho: !nuevo_ancho!
echo nuevo alto: 1920
echo/
set "output=%~dp0\1920encode\!name!_1920!ext!"
ffmpeg -i "!fname!" -c:v libx264 -s !nuevo_ancho!x1920 -aspect !dar! -preset !preset! -crf !crf! !audio! "!output!"
echo/
exit /b


:fixfecha
:: arreglar caracteres para que los lea el string powershell de tipo ''
set "path_mod=!output!"
set "path_mod=!path_mod:'=''!"
set "path_mod=!path_mod:[=``[!"
set "path_mod=!path_mod:]=``]!"

set "path_ori=!fname!"
set "path_ori=!path_ori:'=''!"
set "path_ori=!path_ori:[=``[!"
set "path_ori=!path_ori:]=``]!"

:: poner fecha de modificacion original
powershell  "(ls '!path_mod!').LastWriteTime = (ls '!path_ori!').LastWriteTime"
exit /b