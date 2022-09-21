@echo on

:: crea una intro al video con las 3 imagenes dadas
:: para todos los videos de la carpeta
:: las imagenes se deben llamar: video.mp4.png, video.mp4_1.png, video.mp4_2.png
:: mantiene la fecha de modificacion de los videos originales
:: primero se crea un video a partir de cada imagen en la carpeta /temp
:: segundo se juntan los 3 sumado al original en una operacion
:: se debe crear previamente la carpeta temp

set /a dur1 = 2
set /a dur2 = 2
set /a dur3 = 1
set codec=libx264
set pix_fmt=yuv420p
echo codec: %codec%
echo pix_fmt: %pix_fmt%

set message=Hello World 
echo %message%

if not exist "%~dp0\temp" mkdir "%~dp0\temp"
if not exist "%~dp0\fix_procesado" mkdir "%~dp0\fix_procesado"

setlocal enableDelayedExpansion
for %%a in ("*.mp4", "*.mpg") do (

	echo se procesa el video %%a
	if exist "%~dp0\temp\%%a.txt" del "%~dp0\temp\%%a.txt"
	
	:: obtener video_track_timescale
	for /f "delims=" %%i in (
	'ffprobe -v error -select_streams v -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=time_base "%%a"'
	) do set time_base=%%i
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
	set "img1=%%a.png"
	set "img2=%%a_1.png"
	set "img3=%%a_2.png"
	echo !img1!
	echo !img2!
	echo !img3!
	
	:: nombres de videos a escribir
	set "vid1=temp/%%~na_0%%~xa"
	set "vid2=temp/%%~na_1%%~xa"
	set "vid3=temp/%%~na_2%%~xa"
	
	:: crear video con cada imagen
	ffmpeg -framerate !frame_rate! -loop 1 -i "!img1!" -f lavfi -i anullsrc=channel_layout=!channel!:sample_rate=!sample_rate! -t !dur1!^
	 -c:v !codec! -pix_fmt !pix_fmt! -t !dur1! -video_track_timescale !time_base! "!vid1!"

	ffmpeg -framerate !frame_rate! -loop 1 -i "!img2!" -f lavfi -i anullsrc=channel_layout=!channel!:sample_rate=!sample_rate! -t !dur2!^
	 -c:v !codec! -pix_fmt !pix_fmt! -t !dur2! -video_track_timescale !time_base! "!vid2!"
	 
	ffmpeg -framerate !frame_rate! -loop 1 -i "!img3!" -f lavfi -i anullsrc=channel_layout=!channel!:sample_rate=!sample_rate! -t !dur3!^
	 -c:v !codec! -pix_fmt !pix_fmt! -t !dur3! -video_track_timescale !time_base! "!vid3!"
	 
	::crear txt con videos
	echo file '!vid1!' >> "temp/%%a.txt"
	echo file '!vid2!' >> "temp/%%a.txt"
	echo file '!vid3!' >> "temp/%%a.txt"
	echo file '%%a' >> "temp/%%a.txt"
	
	:: crear video final
	ffmpeg -safe 0 -f concat -i "%~dp0\temp\%%a.txt" -c copy "%~dp0\fix_procesado\%%~na - fix%%~xa"
	
	:: poner fecha de modificacion original
	powershell  ^(ls '%~dp0\fix_procesado\%%~na - fix%%~xa'^).LastWriteTime = ^(ls '%%a'^).LastWriteTime
	
)
endlocal

@pause