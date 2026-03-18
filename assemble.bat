processing-java.exe --sketch=%~dp0 --run --input %*
.\input\customasm_v0.13.13.exe %1.obj -f binary -o %1.obin -- -f annotated -o %1.olst -- -f symbols -o %1.osym