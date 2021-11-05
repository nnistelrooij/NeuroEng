@echo off

set cd=%~dp0
FOR %%A IN ("%~dp0.") DO SET parent=%%~dpA
IF %cd:~-1%==\ SET cd=%cd:~0,-1%

set sourcePath=%cd%\projects\SNN_Perceptron\output_files\MKRVIDOR4000.ttf
set targetPath=%parent%\Arduino\FPGA_Bitstream.h
set tempFile=%cd%\tempStream.ttf

if exist "%tempFile%" (
del "%tempFile%"
)

echo Converting FPGA Bitstream...
java ReverseByte "%sourcePath%" "%tempFile%"

if not exist "%tempFile%" (
echo Error while converting!
pause
exit
)

if exist "%targetPath%" (
del "%targetPath%"
)

copy "%tempFile%" "%targetPath%"

if not exist "%targetPath%" (
echo Error: Failed to replace bitstream!
pause
exit
) else (
del "%tempFile%"
)

echo Successfully replaced bitstream!
pause
exit