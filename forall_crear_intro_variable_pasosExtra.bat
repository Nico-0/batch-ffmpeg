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

set "dura=0.5"
set codec=libx264
set pix_fmt=yuv420p
echo codec: %codec%
echo pix_fmt: %pix_fmt%

set message=Hello World 
echo %message%

if not exist "%~dp0\temp" mkdir "%~dp0\temp"
if not exist "%~dp0\fix_procesado" mkdir "%~dp0\fix_procesado"

setlocal enableDelayedExpansion
for %%a in ("*.mp4", "*.mpg", "*.wmv") do (

	echo se procesa el video %%a
	if exist "%~dp0\temp\%%a.txt" del "%~dp0\temp\%%a.txt"
	
	:: obtener codec
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=time_base "%%a"'
	) do set codec_name=%%i
	echo codec_name obtenido: !codec_name!
	IF "!codec_name!"=="hevc" (
	set codec=libx265)
	
	:: obtener video_track_timescale
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=time_base "%%a"'
	) do set time_base=%%i
	set time_base=!time_base:~2!
	echo time_base obtenido: !time_base!
	:: obtener framerate
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=r_frame_rate "%%a"'
	) do set frame_rate=%%i
	echo frame_rate obtenido: !frame_rate!
	:: obtener audio sample rate
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams a -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=sample_rate "%%a"'
	) do set sample_rate=%%i
	echo sample_rate obtenido: !sample_rate!
	:: obtener audio channel layout
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams a -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=channel_layout "%%a"'
	) do set channel=%%i
	echo channel layout obtenido: !channel!

	:: nombres de imagenes a leer
	:: crear un video por cada imagen y agregarlo al txt
	set /a contador = 0
	for %%m in ("%%a*.png") do (
		set /a "contador = contador + 1"
		set imagen[!contador!]="%%m"
		
		ffmpeg -framerate !frame_rate! -loop 1 -i "%%m" -f lavfi -i anullsrc=channel_layout=!channel!:sample_rate=!sample_rate! -t !dura!^
		 -c:v !codec! -pix_fmt !pix_fmt! -t !dura! -video_track_timescale !time_base! "temp/%%~na_!contador!%%~xa"
		
		echo file '%%~na_!contador!%%~xa' >> "temp/%%a.txt"
	)
	echo file '..\%%a' >> "temp/%%a.txt"
	
	echo contador: !contador!
	
	:: imprimir nombres de imagenes tomadas
	for /l %%x in (1,1,!contador!) do (
		echo imagen %%x: !imagen[%%x]!
	)
	
	:: obtener cantidad de streams del video original
	for /f "delims=" %%i in (
	'ffprobe -v error -of default^=noprint_wrappers^=1:nokey^=1 -show_entries format^=nb_streams "%%a"'
	) do set streams=%%i
	echo nb_streams obtenido: !streams!
	
	:: checkear que no tenga mas de dos streams
	:: crear video con solo dos streams
	IF !streams! GTR 2 (
	if not exist "%~dp0\extra_streams" mkdir "%~dp0\extra_streams")

	IF !streams! GTR 2 (
	move "%~dp0\%%a" %~dp0\extra_streams)

	IF !streams! GTR 2 (
	ffmpeg -i "%~dp0\extra_streams\%%a" -c copy -dn "%~dp0\%%a")

	IF !streams! GTR 2 (
	powershell  ^(ls '%~dp0\%%a'^).LastWriteTime = ^(ls '%~dp0\extra_streams\%%a'^).LastWriteTime)

	IF !streams! GTR 2 (
	ren "%~dp0\extra_streams\%%a" "%%~na_orig%%~xa")
	

	:: crear video final
	ffmpeg -safe 0 -f concat -i "%~dp0\temp\%%a.txt" -c copy -dn "%~dp0\fix_procesado\%%~na - fix%%~xa"

	:: poner fecha de modificacion original
	powershell  ^(ls '%~dp0\fix_procesado\%%~na - fix%%~xa'^).LastWriteTime = ^(ls '%%a'^).LastWriteTime

)
endlocal

echo completado
@pause