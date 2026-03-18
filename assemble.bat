processing-java.exe --sketch=%~dp0 --run --input=%1.asm
.\input\customasmV0.13.5.exe %1.obj -f binary -o %1.obin -- -f annotated -o %1.olst