@echo off
echo Build ALL for Dynamic Link Library
if not exist rsrc.rc goto over1
\masm32\bin\rc /v rsrc.rc
\masm32\bin\cvtres /machine:ix86 rsrc.res
:over1

if exist %1.dll del %1.dll
if exist %1.obj del %1.obj

\masm32\bin\ml /c /Fl /Sn /coff %1.asm /Sa
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

echo Resources were found

\masm32\bin\Link /DLL /SUBSYSTEM:WINDOWS /DEF:%1.def /LIBPATH:c:\masm32\lib %1.obj rsrc.obj 
if errorlevel 1 goto errlink
goto TheEnd

:nores
echo No resources found
\masm32\bin\Link /DLL /SUBSYSTEM:WINDOWS /DEF:%1.def /LIBPATH:c:\masm32\lib %1.obj 
if errorlevel 1 goto errlink
goto TheEnd

:errlink
echo _
echo >> Link error
goto alldone

:errasm
echo _
echo >> Assembly Error
goto alldone

:TheEnd
echo GOOD BUILD
dir %1

:alldone
pause
