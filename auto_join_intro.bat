@echo off
:: todos los videos juntarlos en uno, con sus grillas preview al principio.
:: de cada video, crear una grilla cada 5min, minimo que haya 1min
:: si dura menos, pone una sola prev en full screen
:: se inscribe en la grilla el nombre de archivo
:: juntar todas las grillas y videos finales

:: todo hacer que entre el nombre en videos verticales


:: duration for each preview
set /a dura = 3

:: seconds from the start and from the end, to pick the first and last previews
set /a primero = 10
set /a ultimo = 10

set "font=c\\:/Windows/Fonts/ARLRDBD.TTF"
:: set "font=c\\:/Users/user/AppData/Local/Microsoft/Windows/Fonts/installed font.ttf"

set "fontcolor=yellow@0.9"
set "shadowcolor=0x000000"

:: reencodear los cuts evita problemas de duracion. No es necesario si el video tiene muchos keyframes
set "reencode=no"

:: duplicate width and height of the grids. (The final concat will result in different resolutions at different points in time)
set "grid4x=false"

:: -----------------------------------------------------------------------------------------------------

if "%reencode%"=="no" (
set "copy=-c copy")

if not exist "%~dp0\tempj" mkdir "%~dp0\tempj"
if not exist "%~dp0\tempGrillj" mkdir "%~dp0\tempGrillj"
if exist "%~dp0\grillas.txt" del "%~dp0\grillas.txt"

for %%a in ("*.mp4", "*.wmv", "*.avi", "*mpg", "*.mkv", "*.webm") do (
	echo se procesa el video %%a
	
	:: nombre fuera de delayedExpansion para que funcionen filenames con !
	set "fname=%%a"
	set "name=%%~na"
	setlocal enableDelayedExpansion
	::obtener duracion
	for /f "delims=" %%i in (
	'ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "!fname!"'
	) do set /a output=%%i
	echo duracion obtenida: !output!
	
	for /f "delims=" %%i in (
	'ffprobe -v error -show_entries format^=duration -sexagesimal -of default^=noprint_wrappers^=1:nokey^=1 "!fname!"'
	) do set horasexa=%%i
	set horasexa=!horasexa:~0,7!
	if "!horasexa:~0,1!"=="0" (
	set horasexa=!horasexa:~2!)
	set horasexa=!horasexa::=\:!
	echo duracion obtenida: !horasexa!

	
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
	
	IF "!grid4x!"=="true" (
	set /a "ancho=!ancho!*2"
	set /a "alto=!alto!*2")
	

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
	
	set /a "fontsize=!alto!/30"
	
	:: calcular cuantas grillas voy a necesitar
	echo duracion: !output!
	
	set /a ngrills = "((!output! - 60) / 300) + 1"
	echo ngrills: !ngrills!
	
	IF !output! LSS 60 (
	echo "dura menos de 1 min"
	set /a ngrills = 0)
	
	set /a "segmento=!output! - !primero! - !ultimo!"
	set /a "incremento=((100 * !segmento!) / !ngrills! / 4) / 100"
	echo segmento: !segmento!
	echo incremento: !incremento!
	
	
	::crear las previews para la grilla. Con reencode para tener tiempo exacto
	set /a current = primero
	set /a "nprevs=!ngrills! * 4"
	for /l %%x in (1,1,!nprevs!) do (
		echo preview %%x en instante: !current!

		set "ruta=tempj\!name!_prev_%%x!ext!"
		ffmpeg -n -ss !current! -i "!fname!" !codec! -pix_fmt !format! -t !dura! -video_track_timescale !time_base! ^
		!stream_order! -c:a !codec_audio! !copy! "!ruta!"
		
		set /a current = current + incremento
	)
	
	
	IF !alto! LSS !ancho! (
	set /a "shad=1 + !alto!/720") else (
	set /a "shad=1 + !ancho!/720")
	
	::Crear las grillas necesarias. Es el segundo reencode pero igual se achican de tamaño 1/4
	for /l %%x in (1,1,!ngrills!) do (
		echo grilla numero %%x
		
		set "grilla=tempGrillj\!name!_grilla%%x!ext!"
		set /a "offset=4 * (%%x - 1)"
		echo "grilla: !grilla! (offset !offset!) para !name!"

		set /a "n1=1 + offset"
		set /a "n2=2 + offset"
		set /a "n3=3 + offset"
		set /a "n4=4 + offset"
		set "ruta[1]=tempj\!name!_prev_!n1!!ext!"
		set "ruta[2]=tempj\!name!_prev_!n2!!ext!"
		set "ruta[3]=tempj\!name!_prev_!n3!!ext!"
		set "ruta[4]=tempj\!name!_prev_!n4!!ext!"
		
		ffmpeg -i "!ruta[1]!" -i "!ruta[2]!" -i "!ruta[3]!" -i "!ruta[4]!" ^
		-filter_complex "[0:v][1:v]hstack[top];[2:v][3:v]hstack[bottom];[top][bottom]vstack,format=!format!,scale=!ancho!x!alto![v];[0:a][1:a][2:a][3:a]amerge=inputs=4[a];[v]drawtext=x=(w-text_w)/2:y=(h-text_h)/2:fontsize=!fontsize!:fontfile=!font!:fontcolor=!fontcolor!:shadowy=!shad!:shadowx=!shad!:shadowcolor=!shadowcolor!:text='!name! - !horasexa!'[v]" ^
		!codec! -video_track_timescale !time_base! !stream_order_gr! -ac 2 -c:a !codec_audio! "!grilla!"

		:: agregar nombres de videos a leer al txt
		echo file '!grilla!' >> "grillas.txt"
	)
	
	
	:: video corto, crear unica preview en lugar de grilla
	IF !output! LSS 60 (
	set "grilla=tempGrillj\!name!_prev!ext!"
	echo !grilla! 
	
	ffmpeg -ss 0 -i "!fname!" -vf "scale=!ancho!x!alto!,drawtext=fontsize=!fontsize!:fontcolor=white:x=(w-text_w)/2:y=2:fontfile=!font!:fontcolor=!fontcolor!:shadowy=2:shadowx=2:shadowcolor=!shadowcolor!:text='!name! - !horasexa!'" !codec! -pix_fmt !format! -t !dura! -video_track_timescale !time_base! ^
	!stream_order! -c:a !codec_audio! "!grilla!"
	
	echo file '!grilla!' >> "grillas.txt")

	
	endlocal
	
)

:: agregar los videos al txt
for %%a in ("*.mp4", "*.wmv", "*.avi", "*mpg", "*.mkv", "*.webm") do (
	echo file '%%a' >> "grillas.txt"
)

::realizar el concat
ffmpeg -safe 0 -f concat -i "%~dp0\grillas.txt" -c copy -dn "%~dp0\__result.mp4"


echo/
echo finalizo el programa
echo end
@pause



	
