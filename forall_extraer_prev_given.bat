@echo off
::setear la duracion todas las prevs
::setear los instantes de cada given prev
::no reencodea nada

set /a dura = 3

set /a cantidad = 2
set /a prev[1] = 60
set /a prev[2] = 300

set "reencode=no"

call :vars_if
echo reencode: %reencode%
echo copy: %copy%
echo codec: "%codec%"

if not exist "%~dp0\prevs" mkdir "%~dp0\prevs"

for %%a in ("*.mp4", "*.wmv", "*.avi", "*.mkv") do (
	echo se procesa el video %%a
	
	:: nombre fuera de delayedExpansion para que funcionen filenames con !
	set "fname=%%a"
	set "name=%%~na"
	setlocal enableDelayedExpansion
	for /f "delims=" %%i in (
	'ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "!fname!"'
	) do set output=%%i
	echo duracion obtenida: !output!
	
	IF "%%~xa"==".wmv" (
	set /a durac = "dura - 2") else (
	set /a durac = dura)
	
	set "ext=%%~xa"
	IF "%%~xa"==".wmv" (
	set "ext=.mkv")
	
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
	
	if "!codec!"=="" (
	echo falta setear codec (si no existe probar sin reencode)
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
	

	for /l %%x in (1,1,%cantidad%) do (
		
		set "current=!prev[%%x]!"
		echo current: !current!

		ffmpeg -ss !current! -i "!fname!" !codec! -pix_fmt !format! -t !durac! -video_track_timescale !time_base! !stream_order! ^
		-c:a !codec_audio! !copy! "prevs\!name!_gprev%%x!ext!"
	)
	
	::con endlocal se borran todas las variables seteadas dentro del for
	endlocal
)
echo/
echo prevs creadas con reencode: %reencode%
echo end
@pause


:vars_if
if "%reencode%"=="no" (
set "copy=-c copy")
if "%reencode%"=="no" (
set "codec= ")

exit /b