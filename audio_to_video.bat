@echo off

set "ext=.mp4"
set "res=1920x1080"

if not exist "%~dp0\_to_video" mkdir "%~dp0\_to_video"

for %%a in ("*.mp3", "*.wav", "*.amr", "*.aac", "*.opus", "*.wma", "*.ogg", "*.flac", "*.m4a") do (
	setlocal enableDelayedExpansion

	IF "%%~xa"==".amr" (
	set "res=1408x1152")
	IF "%%~xa"==".amr" (
	set "ext=.3gp")
	IF "%%~xa"==".wma" (
	set "ext=.avi")
	IF "%%~xa"==".wav" (
	set "ext=.avi")
	IF "%%~xa"==".flac" (
	set "ext=.mkv")

ffmpeg -f lavfi -i color=size=!res!:rate=1:color=black -i "%%a" ^
-vf "drawtext=fontsize=72:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2:text='%%~na'" ^
-c:a copy -strict -1 -shortest "_to_video\%%~na!ext!"
	

	:: arreglar caracteres para que los lea el string powershell de tipo ''
	set "path_mod=%~dp0\_to_video\%%~na!ext!"
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

echo Directorio: "%~dp0\_to_video"
echo/
echo end
pause
