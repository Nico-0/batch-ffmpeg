@echo off

set "ext=.mp4"

if not exist "%~dp0\_to_video_mjpeg" mkdir "%~dp0\_to_video_mjpeg"
if not exist "%~dp0\temp" mkdir "%~dp0\temp"

for %%a in ("*.mp3", "*.wav", "*.amr", "*.aac", "*.opus", "*.wma") do (
	setlocal enableDelayedExpansion

::para no crear otro stream
::ffmpeg -i "%%a" -c copy "_to_video_mjpeg\%%~na!ext!"
ffmpeg -i "%%a" "temp\%%~na.jpg"
ffmpeg -loop 1 -i "temp\%%~na.jpg" -i "%%a" -c:v libx264 -tune stillimage -r 1 -c:a copy -shortest "_to_video_mjpeg\%%~na!ext!"	


	:: arreglar caracteres para que los lea el string powershell de tipo ''
	set "path_mod=%~dp0\_to_video_mjpeg\%%~na!ext!"
	set "path_mod=!path_mod:'=''!"
	set "path_mod=!path_mod:[=``[!"
	set "path_mod=!path_mod:]=``]!"
	
	set "path_ori=%%a"
	set "path_ori=!path_ori:'=''!"
	set "path_ori=!path_ori:[=``[!"
	set "path_ori=!path_ori:]=``]!"

	:: poner fecha de modificacion original
	powershell  "(ls '!path_mod!').LastWriteTime = (ls '!path_ori!').LastWriteTime"
	
	endlocal
)

echo Directorio: "%~dp0\_to_video_mjpeg"
echo/
echo end
pause
