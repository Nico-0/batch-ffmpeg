@echo off

:: crea una intro al video con las x cantidad de imagenes que haya, 1 seg cada una
:: para todos los videos de la carpeta
:: las imagenes se encuentran de la forma: nombrevideo-wildcard-.png  (crear con forall_extraer_frames.bat y mover de directorio)
:: adentro de un vector se va guardando cada nombre de imagen, y se tiene un contador que se incrementa con cada una
:: mantiene la fecha de modificacion de los videos originales
:: primero se crea un video a partir de cada imagen en la carpeta /temp
:: segundo se juntan los x sumado al original en una operacion
:: se recomienda minimo una imagen para que salga de miniatura, y maximo 5 para llenar los 5 seg de google photos
:: powershell nombres no pueden tener doble espacio, ni parentesis ni corchetes
:: ffmpeg nombres no pueden tener guiones


set "dura=1"
set codec=libx264
set pix_fmt=yuv420p
echo codec: %codec%
echo pix_fmt: %pix_fmt%

set message=Hello World 
echo %message%

if not exist "%~dp0\temp" mkdir "%~dp0\temp"
if not exist "%~dp0\fix_procesado" mkdir "%~dp0\fix_procesado"

for %%a in ("*.mp4", "*.mpg", "*.wmv", "*.mkv") do (
	
	:: para nombres con !
	set "fname=%%a"
	set "name=%%~na"
	
	setlocal enableDelayedExpansion
	set "a=!fname!"
	set "a=!a:'='\''!
	set "na=!name!"
	set "na=!na:'='\''!

	echo se procesa el video !fname!
	if exist "%~dp0\temp\!fname!.txt" del "%~dp0\temp\!fname!.txt"
	
	:: obtener codec
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=time_base "!fname!"'
	) do set codec_name=%%i
	echo codec_name obtenido: !codec_name!
	IF "!codec_name!"=="hevc" (
	set codec=libx265)
	
	:: obtener video_track_timescale
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=time_base "!fname!"'
	) do set time_base=%%i
	set time_base=!time_base:~2!
	echo time_base obtenido: !time_base!
	:: obtener framerate
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=r_frame_rate "!fname!"'
	) do set frame_rate=%%i
	echo frame_rate obtenido: !frame_rate!
	:: obtener audio sample rate
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams a -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=sample_rate "!fname!"'
	) do set sample_rate=%%i
	echo sample_rate obtenido: !sample_rate!
	:: obtener audio channel layout
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams a -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=channel_layout "!fname!"'
	) do set channel=%%i
	echo channel layout obtenido: !channel!

	:: obtener primer stream
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams 0 -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=codec_type "!fname!"'
	) do set stream_0=%%i
	echo stream 0 vale: !stream_0!
	:: guardarse el orden de los streams
	IF "!stream_0!"=="video" (
	set "stream_order=-map 0:v -map 1:a") else (
	set "stream_order=-map 1:a -map 0:v")
	
	:: nombres de imagenes a leer
	:: crear un video por cada imagen y agregarlo al txt
	set /a contador = 0
	
	for %%m in ("!fname!*.png") do (
		:: fix para nombres con !
		setlocal DisableDelayedExpansion
		set "mname=%%m"
		setlocal enableDelayedExpansion

		set /a "contador = contador + 1"
		set imagen[!contador!]="!mname!"

		ffmpeg -framerate !frame_rate! -loop 1 -i "!mname!" -f lavfi -i anullsrc=channel_layout=!channel!:sample_rate=!sample_rate! -t !dura!^
		 -c:v !codec! -pix_fmt !pix_fmt! -t !dura! -video_track_timescale !time_base! !stream_order! "temp/!name!_!contador!%%~xa"

		echo file '!na!_!contador!%%~xa' >> "temp/!fname!.txt"
		setlocal DisableDelayedExpansion
	)
	setlocal enableDelayedExpansion
	echo file '..\!a!' >> "temp/!fname!.txt"
	
	echo contador: !contador!
	
	:: imprimir nombres de imagenes tomadas
	for /l %%x in (1,1,!contador!) do (
		echo imagen %%x: !imagen[%%x]!
	)
	
	
	:: crear video final
	:: -dn para no copiar los streams data. Audio y video se ordenaron previamente segun el video original
	ffmpeg -safe 0 -f concat -i "%~dp0\temp\!fname!.txt" -c copy -dn "%~dp0\fix_procesado\!name! - fix%%~xa"

	:: arreglar caracteres para que los lea el string powershell de tipo ''
	:: comando entre comillas para que lea doble espacios
	:: ' se reemplaza por ''
	:: [ se reemplaza por ``[
	:: ( no necesita trato adentro de ''
	set "path_mod=%~dp0\fix_procesado\!name! - fix%%~xa"
	set "path_mod=!path_mod:'=''!"
	set "path_mod=!path_mod:[=``[!"
	set "path_mod=!path_mod:]=``]!"
	
	set "path_ori=!fname!"
	set path_ori=!path_ori:'=''!
	set "path_ori=!path_ori:[=``[!"
	set "path_ori=!path_ori:]=``]!"

	:: poner fecha de modificacion original
	powershell  "(ls '!path_mod!').LastWriteTime = (ls '!path_ori!').LastWriteTime"

endlocal
)

echo completado
@pause