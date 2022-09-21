@echo off
:: extraer 4 previews del video para cada una de las dos grillas
:: juntarlas en grilla y agregarlas de intro
:: para todos los videos de la carpeta

set /a dura = 3
set /a primero = 15

set /a numerador = 90
set /a denominador = 100

set "append="

::reencodear los cuts evita problemas de duracion, que tienen que ser exactas para la grilla
set "reencode=si"

if "%reencode%"=="no" (
set "copy=-c copy")

if not exist "%~dp0\temp" mkdir "%~dp0\temp"
if not exist "%~dp0\fix_auto%append%" mkdir "%~dp0\fix_auto%append%"

for %%a in ("*.mp4", "*.wmv", "*.avi", "*mpg", "*.mkv", "*.webm") do (
	echo se procesa el video %%a
	if exist "%~dp0\temp\%%a_grillas.txt" del "%~dp0\temp\%%a_grillas.txt"
	
	:: nombre fuera de delayedExpansion para que funcionen filenames con !
	set "fname=%%a"
	set "name=%%~na"
	setlocal enableDelayedExpansion
	::obtener duracion y calculos
	for /f "delims=" %%i in (
	'ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "!fname!"'
	) do set output=%%i
	echo duracion obtenida: !output!
	::calculo de porcentaje de cobertura
	set /a cobertura = "((output * numerador * 1000) / (denominador * 1000)) - primero"
	echo cobertura: !cobertura!
	set /a intervalo = "cobertura / (8 - 1)"
	echo intervalo entre previews: !intervalo!
	
	set "ffname=!fname!"
	set "ffname=!ffname:'='\''!
	
	set "ext=%%~xa"
	
	::obtener codec audio
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams a -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=codec_name "!fname!"'
	) do set codec_audio=%%i
	echo codec_audio vale: !codec_audio!
		
	::obtener codec
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=codec_name "!fname!"'
	) do set codec_name=%%i
	echo codec_name vale: !codec_name!
	
	if "!codec_name!"=="hevc" (
	set "codec=-c:v libx265")
	if "!codec_name!"=="h264" (
	set "codec=-c:v libx264")
	if "!codec_name!"=="wmv2" (
	set "codec=-c:v wmv2")
	if "!codec_name!"=="vp9" (
	set "codec=-c:v libvpx-vp9 -strict -2")
	
	if "!codec!"=="" (
	echo falta setear codec (si no existe probar sin reencode, pero la grilla igual reencodea)
	if "!codec!"=="" (
	pause)

	::obtener format
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=pix_fmt "!fname!"'
	) do set format=%%i
	echo format vale: !format!

	:: obtener time_base porque aveces al cortar videos se cambia
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=time_base "!fname!"'
	) do set time_base=%%i
	set time_base=!time_base:~2!
	echo time_base obtenido: !time_base!
	
	::obtener alto
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=height "!fname!"'
	) do set alto=%%i
	echo alto vale: !alto!
	::obtener ancho
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=width "!fname!"'
	) do set ancho=%%i
	echo ancho vale: !ancho!

	:: obtener primer stream
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams 0 -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=codec_type "!fname!"'
	) do set stream_0=%%i
	echo stream 0 vale: !stream_0!
	:: guardarse el orden de los streams
	IF "!stream_0!"=="video" (
	set "stream_order=-map 0:v -map 0:a") else (
	set "stream_order=-map 0:a -map 0:v")
	echo stream_order vale: !stream_order!
	IF "!stream_0!"=="video" (
	set "stream_order_gr=-map [v] -map [a]") else (
	set "stream_order_gr=-map [a] -map [v]")
	echo stream_order_gr vale: !stream_order_gr!
	
	::crear las previews para la grilla. Con reencode para tener tiempo exacto
	set /a current = primero
	for /l %%x in (1,1,8) do (
		echo preview %%x en instante: !current!

		set "ruta=temp\!name!_prev_%%x!ext!"
		ffmpeg -ss !current! -i "!fname!" !codec! -pix_fmt !format! -t !dura! -video_track_timescale !time_base! ^
		!stream_order! -c:a !codec_audio! !copy! "!ruta!"
		set "ruta[%%x]=!ruta!"
		echo ruta[%%x] vale: !ruta[%%x]!
		
		set /a current = current + intervalo
	)
	
	::Crear ambas grillas. Es el segundo reencode pero es como el primero porque se achican 1/4
	set "grilla1=temp\!name!_grilla1!ext!"
	set "grilla2=temp\!name!_grilla2!ext!"
	
	ffmpeg -i "!ruta[1]!" -i "!ruta[2]!" -i "!ruta[3]!" -i "!ruta[4]!" ^
	-filter_complex "[0:v][1:v]hstack[top];[2:v][3:v]hstack[bottom];[top][bottom]vstack,format=!format!,scale=!ancho!x!alto![v];[0:a][1:a][2:a][3:a]amerge=inputs=4[a]" ^
	!codec! -video_track_timescale !time_base! !stream_order_gr! -ac 2 -c:a !codec_audio! "!grilla1!"

	ffmpeg -i "!ruta[5]!" -i "!ruta[6]!" -i "!ruta[7]!" -i "!ruta[8]!" ^
	-filter_complex "[0:v][1:v]hstack[top];[2:v][3:v]hstack[bottom];[top][bottom]vstack,format=!format!,scale=!ancho!x!alto![v];[0:a][1:a][2:a][3:a]amerge=inputs=4[a]" ^
	!codec! -video_track_timescale !time_base! !stream_order_gr! -ac 2 -c:a !codec_audio! "!grilla2!"
	
	
	:: agregar nombres de videos a leer al txt
	echo file '!grilla1!' >> "temp/!fname!_grillas.txt"
	echo file '!grilla2!' >> "temp/!fname!_grillas.txt"
	echo file '!ffname!' >> "temp/!fname!_grillas.txt"
	
	::realizar el concat
	ffmpeg -safe 0 -f concat -i "%~dp0\temp\!fname!_grillas.txt" -c copy -dn "%~dp0\fix_auto!append!\!name! - fix!ext!"
	
	
	
	:: arreglar caracteres para que los lea el string powershell de tipo ''
	set "path_mod=%~dp0\fix_auto!append!\!name! - fix!ext!"
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

echo Directorio: "%~dp0\fix_auto%append%"
echo/
echo end
@pause



	
