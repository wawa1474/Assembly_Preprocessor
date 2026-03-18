StringList _output;
String _outputFile;
boolean _exit = true;
FileStack _FileStack; // stack to hold loaded files
FileHolder _tmpFileHolder = new FileHolder(); // tmp variable to hold current working file
ArrayList<Macro> _Macros;
StringDict _Vars;

ArrayList<FileHolder>[] _Files = new ArrayList[2]; // macros as arrays of strings would allow reuse of main parsing loop...
String _macro_Name = "";
String[] _macro_Args;
StringList _macro_Content = new StringList();
final static int _Files_Inputs = 0;
final static int _Files_Macros = 1;
int _Files_Type = _Files_Inputs; // select between parsing a macro/input file
int _Files_Current = 0; // contains the current macro, or last pushed file

String getNextLine(){
  return _Files[_Files_Type].get(_Files_Current).getNextLine();
}

//@echo off
//java -Djava.ext.dirs=lib -Djava.library.path=lib floatToHex

//processing-java's directory must be added to PATH
//--sketch refers the the directory, not the file
//anything after --run is passed as args
//processing-java.exe --sketch=%~dp0 --run 123 123

// takes in .asm files (w/ includes) and outputs .obj files

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
  
  if(args != null){ // allows input from command line
    for (int i = 0; i < args.length; i++) {
      String arg = args[i];
      if(arg.contains("--input")){
        PathReturn filename = splitFilepath(split(arg, '=')[1]);
        println("Input: " + filename + filename.Reverse);
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
    _FileStack = new FileStack();
    _Macros = new ArrayList<Macro>();
    _Vars = new StringDict();
    _Files[0] = new ArrayList<FileHolder>();
    _Files[1] = new ArrayList<FileHolder>();
    
    processInput();
    
    
    println("Total Macros: " + _Files[_Files_Macros].size());
    if(_Files[_Files_Macros].size() > 0){
      FileHolder tmp = _Files[_Files_Macros].get(_Files[_Files_Macros].size() - 1);
      println("Macro Name: " + tmp.file.Name);
      print("Macro Args: ");printArray(tmp.file.PathArray);
      print("Macro Contents: ");printArray(tmp.contents);
    }
  }
  
  exit();
}

void processInput(){
  _output = new StringList();
  
  for(; _tmpFileHolder.indexArray < _tmpFileHolder.contents.length; _tmpFileHolder.indexArray++){
    String line = _tmpFileHolder.contents[_tmpFileHolder.indexArray];
    TokenReturn token = getNextToken(line,0);
    boolean skip = true;
    //println("processInput [" + _tmpFileHolder.indexArray + "] " + line);
    
    switch(token.string){
      case ".include": // .include macro|file "path/name.ext"
        checkIncludeFile(line, token.nextIndex);
        break;
      case ".macro":
        parseMacro(line, token.nextIndex);
        break;
      case ".if":
        parseIf(line, token.nextIndex, 0);
        break;
      case ".let":
        parseLet(line, token.nextIndex);
        break;
      default:
        skip = checkMacros(token.string, line); // will skip outputting a raw macro line, but otherwise will append all lines
        break;
    }
    
    if(!skip){
      _output.append(line);
    }
    
    popFileIfLastLine();
  }
  
  printArray(_Vars);
  
  println(_outputFile);
  saveStrings(_outputFile, _output.toArray());
}
