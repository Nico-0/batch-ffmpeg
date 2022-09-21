@echo off
:: Extrae una cantidad definida de previews de video de duracion dada
:: dar numerador y denominador que define el porcentaje a abarcar desde el comienzo
:: 3/4 son 75%
:: 1/3 son 33%
:: 1 es todo (el ultimo video quedara de 0 seg)
:: 9/10 es 90%

set /a cantidad = 6
set /a dura = 5
set /a numerador = 80
set /a denominador = 100

if not exist "%~dp0\prevs" mkdir "%~dp0\prevs"


for %%a in ("*.mp4", "*.wmv", "*.avi") do (
	echo se procesa el video %%a
	
	:: nombre fuera de delayedExpansion para que funcionen filenames con !
	set "fname=%%a"
	set "name=%%~na"
	setlocal enableDelayedExpansion
	for /f "delims=" %%i in (
	'ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "!fname!"'
	) do set output=%%i
	echo duracion obtenida: !output!
	set /a intervalo = "(output * numerador * 1000) / (denominador * 1000)"
	echo intervalo: !intervalo!
	set /a fraccion = "intervalo / cantidad"
	echo primer fraccion: !fraccion!
	
	IF "%%~xa"==".wmv" (
	set /a durac = "dura - 2") else (
	set /a durac = dura)
	
	set "ext=%%~xa"
	IF "%%~xa"==".wmv" (
	set "ext=.mkv")
	
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
	
	set /a current = 0
	for /l %%x in (1,1,%cantidad%) do (
		set /a current = current + fraccion
		echo fraccion actual: !current!
		echo duracion total: !output!
		echo %NL% fraccion %%x: !current! %NL%
		set /a actual = %%x
		ffmpeg -ss !current! -i "!fname!" -t !durac! -video_track_timescale !time_base! !stream_order! -c copy "prevs\!name!_prev%%x!ext!"
	)
	
	echo %cantidad% videos de %dura%s creados, chequee la carpeta
	endlocal
)


@pause
