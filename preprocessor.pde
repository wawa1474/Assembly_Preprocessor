StringList _output;
String _outputFile;
boolean _exit = true;
StringDict _Vars;

PathReturn CurrentDirectory; // current working directory for file includes...
StringList _switch_Args = new StringList(); // stack for switch arguments
ArrayList<String[]> _while_Args = new ArrayList<String[]>(); // stack for while loop arguments
IntList _repeat_Args = new IntList(); // stack for repeat arguments
// TODO: recursive macros would require;
//           getVariable(String, boolean) and parseVariables(String)
//           as well as peekMacroArgs() and getFile()
//         to be able to reverse traverse the stack to grab args from previous bits

//processing-java's directory must be added to PATH
//--sketch refers to the directory, not the file
//anything after --run is passed as args
//processing-java.exe --sketch=%~dp0 --run 123 123

// takes in .asm files (w/ includes) and outputs single .obj file

/*
  has to handle includes as well, but should be able to be told not to bother
    #pragma noFloats #include "path/file.ext"
    #include "path/file.ext"
  needs to be told what needs to be converted, and how
    convert to hexadecimal (binary)
      f8(1234.5678)   8 bit floating point number - Quarter-Precision Float (1 byte)
      f16(1234.5678) 16 bit floating point number - Half-Precision Float (2 bytes)
      f32(1234.5678) 32 bit floating point number - Float (4 bytes)
      f64(1234.5678) 64 bit floating point number - Double (8 bytes)
*/

String _VERSION = "V1234";
void setup(){
  int time = millis();
  println("sketchPath() = " + sketchPath());
  
  if(args != null){ // allows input from command line
    for (int i = 0; i < args.length; i++) {
      String arg = args[i];
      if(arg.contains("--input")){
        PathReturn filename = splitFilepath(split(arg, '=')[1]);
        CurrentDirectory = filename;
        println("Input: " + filename + " [" + filename.Reverse + "]");
        _outputFile = filename.getPath() + filename.Name + ".obj";
        getNewFile(splitFilepath(sketchPath()), filename);
        _exit = false;
      }else if(arg.contains("--help")){
        _exit = true;
      }
    }
  }
  
  if(_exit){
    println("Assembly Preprocessor " + _VERSION);
    println();
    println("--help - Show this help text. Congratulations.");
    println();
    println("--input=<file.ext> - Specify the input file.");
    println("\tOutput filename will be <input-filename>.obj");
    println("\t#include's will be opened and concatenated into a single output file.");
  }else{
    _Vars = new StringDict();
    _output = new StringList();
    
    processInput(0, ParseState.Entry);
    
    printArray(_Vars);
    println(_outputFile);
    saveStrings(_outputFile, _output.toArray());
    
    println("Total Macros: " + Macros.size());
    println("Total Macro Args Pushed: " + MacroArgsStack.size()); // should be 0 when done
    //for(int i = 0; i < _Files[_Files_Macros].size(); i++){
    //  FileHolder tmp = _Files[_Files_Macros].get(i);
    //  println("Macro Name: " + tmp.file.Name);
    //  print("Macro Args: ");printArray(tmp.file.PathArray);
    //  print("Macro Contents: ");printArray(tmp.contents);
    //}
  }
  
  testRPN();
  println("program ran for: " + (millis() - time) + " millis.");
  exit();
}

FileHolder getFile(){
  return CurrentWorker.File;
}

int getIndex(){
  return CurrentWorker.LineIndex;
}

void setIndex(int i){
  CurrentWorker.LineIndex = i;
}

void incIndex(){
  CurrentWorker.LineIndex++;
}

void decIndex(){
  CurrentWorker.LineIndex--;
}

String getLine(){
  return CurrentWorker.getLine(CurrentWorker.LineIndex);
}

int getFileLength(){
  return CurrentWorker.getLength();
}

String getFileName(){
  return CurrentWorker.getFileName();
}

int getLastOutputLineLength(){
  if(_output.size() > 0){
    return _output.get(_output.size() - 1).length();
  }
  return -1;
}
