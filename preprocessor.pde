StringList _output;
String _outputFile;
boolean _exit = true;
FileHolder _tmpFileHolder = new FileHolder(); // tmp variable to hold current working file
StringDict _Vars;

ArrayList<FileHolder>[] _Files = new ArrayList[2]; // macros as arrays of strings would allow reuse of main parsing loop...
String _macro_Name = "";
String[] _macro_Args;
ArrayList<String[]> _macro_Args2 = new ArrayList<String[]>(); // stack for macro arguments
StringList _switch_Args = new StringList(); // stack for switch arguments
ArrayList<String[]> _while_Args = new ArrayList<String[]>(); // stack for while loop arguments
StringList _repeat_Args = new StringList(); // stack for repeat arguments
StringList _macro_Content = new StringList();
final static int _Files_Inputs = 0;
final static int _Files_Macros = 1;
int _Files_Type = _Files_Inputs; // select between parsing a macro/input file
// /\ this might want to be pushed/popped to allow recursive macro stuff...
final static int _PathReturn_Reverse_Macro = -1; // _tmpFileHolder.file.Reverse
// /\ PathReturn's Reverse can be 'reused' to mark a 'file' as a macro via setting it to -1, a value that can't otherwise be gotten
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
  println("sketchPath() = " + sketchPath());
  _Files[0] = new ArrayList<FileHolder>();
  _Files[1] = new ArrayList<FileHolder>();
  
  if(args != null){ // allows input from command line
    for (int i = 0; i < args.length; i++) {
      String arg = args[i];
      if(arg.contains("--input")){
        PathReturn filename = splitFilepath(split(arg, '=')[1]);
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
    
    println("Total Macros: " + _Files[_Files_Macros].size());
    println("Total Macro Args Pushed: " + _macro_Args2.size()); // should be 0 when done
    //for(int i = 0; i < _Files[_Files_Macros].size(); i++){
    //  FileHolder tmp = _Files[_Files_Macros].get(i);
    //  println("Macro Name: " + tmp.file.Name);
    //  print("Macro Args: ");printArray(tmp.file.PathArray);
    //  print("Macro Contents: ");printArray(tmp.contents);
    //}
  }
  
  setup2();
  exit();
}

FileHolder getFile(){
  return _tmpFileHolder;
}

int getIndex(){
  return _tmpFileHolder.indexArray;
}

void setIndex(int i){
  _tmpFileHolder.indexArray = i;
}

void incIndex(){
  _tmpFileHolder.indexArray++;
}

void decIndex(){
  _tmpFileHolder.indexArray--;
}

String getLine(){
  return _tmpFileHolder.contents[_tmpFileHolder.indexArray];
}

int getFileLength(){
  if(_tmpFileHolder.contents != null){
    return _tmpFileHolder.contents.length;
  }
  return 0;
}
