:: al usar -ss antes de -i, el corte se aproxima mas al keyframe cercano

@echo off
echo Archivo abierto:
echo "%~1"
echo/
IF "%~1" == "" (
exit /b)

echo Bienvenido al asistende de split de video. Inserte los tiempos separados por enter.
echo Para tomar hasta el final y terminar ingrese 0.
echo/

set /a "contador=1"
set /a "previo=0"
set "stamp[0]=0"
:start
set /p "stamp[%contador%]=Instante:  "


set "tempp=stamp[%previo%]"
call set temppp=%%%tempp%%%
set "tempc=stamp[%contador%]"
call set tempcc=%%%tempc%%%
IF "%tempcc%"=="0" (
goto proceso)

echo Segmento %contador%:
echo De %temppp% hasta %tempcc%
echo/

set /a "contador=contador+1"
set /a "previo=previo+1"

goto start

:proceso
setlocal enableDelayedExpansion
set "name=%~1"
set name=!name:~0,-4!
set "ext=%~1"
set ext=!ext:~-3!

	for /f "delims=" %%i in (
	'ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "%~1"'
	) do set dura=%%i
setlocal disableDelayedExpansion

echo Segmento %contador%:
echo De %temppp% hasta %dura%
echo/

set /a "limit=contador-1"
setlocal enableDelayedExpansion
for /l %%x in (1,1,!limit!) do (
	set /a "prev=%%x-1"
	call set "desde=%%stamp[!prev!]%%"
	call set "hasta=!stamp[%%x]!"
	echo Se crea segmento %%x: !desde! - !hasta!
	
	ffmpeg -ss !desde! -to !hasta! -i "%~1" -c copy "!name! - Scene0%%x.!ext!"

)
::call set "desde=%%stamp[!contador!]%%"
echo ultimo video desde: !hasta!
echo/
echo/
echo/
pause
ffmpeg -ss !hasta! -i "%~1" -c copy "!name! - Scene0!contador!.!ext!"

setlocal disableDelayedExpansion

echo end

pause
exit





echo Command line: %0 %*
echo Command line argument 1: "%~1"
echo Command line argument 2: "%~2"