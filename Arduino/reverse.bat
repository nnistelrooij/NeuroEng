@echo off

set cd=%~dp0
IF %cd:~-1%==\ SET cd=%cd:~0,-1%

set sourcePath=%cd%\MKRVIDOR4000\projects\JTAG_Interface\output_files\MKRVIDOR4000.ttf
set targetPath=%cd%\FPGA_Arduino\FPGA_Bitstream.h
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