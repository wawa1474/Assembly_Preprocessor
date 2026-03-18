import java.util.UUID; // used for generation of unique local labels
import java.util.Map; // used for handling of _TmpGlobalVars

StringList _output;
String _outputFile;
boolean _exit = true;
StringDict _Vars; // variables that can be changed
StringDict _Equates; // variables that are set once and can't be changed
StringDict _TmpMacroVars; // transitory variables that are deleted at the end of a macro
ArrayList<StringDict> _TmpMacroVarsArr; // transitory variables that are deleted at the end of a macro
HashMap<String, String> _TmpGlobalVars = new HashMap<String, String>(); // ditto, but a way to easily save and restore global variables
ArrayList<HashMap<String, String>> _TmpGlobalVarsArr; // ditto, but a way to easily save and restore global variables
HashMap<String, StringList> Stacks = new HashMap<String, StringList>(); // hashmap of data stacks for use in complex preprocessing
String storageOrigin = ""; // for use with .org and .dfs, allowing automatic address assignment for assembly variables
int storageOffset = 0;      // ditto

boolean maintainComments = false; // should comments be passed on, or cleaned up
boolean showLines = false; // show all lines, including 'eaten' ones
boolean concatenateFiles = true; // combine all input files into one output file
boolean hyperVerboseOutput = false; // will all the println's in the universe be printed? (might be an int in the future...)
boolean initEmptyStacks = false; // will an uninintialized stack be created on push, or generate an error?

String ext_db = "\t#d8"; // what is the assemblers form for db
String ext_db_wrapStart = "(("; // do we have to output something to signify a byte?
String ext_db_wrapEnd = ")`8)";
String ext_dw = "\t#d16"; // what is the assemblers form for dw
String ext_dw_wrapStart = "(("; // do we have to output something to signify a word?
String ext_dw_wrapEnd = ")`16)";
String ext_drw = "\t#d16"; // what is the assemblers form for drw
String ext_drw_wrapStart = "le(("; // do we have to output something to signify a reverse word?
String ext_drw_wrapEnd = ")`16)";

PathReturn CurrentDirectory; // current working directory for file includes...
StringList _switch_Args = new StringList(); // stack for switch arguments
ArrayList<String[]> _while_Args = new ArrayList<String[]>(); // stack for while loop arguments
IntList _repeat_Args = new IntList(); // stack for repeat arguments

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

String _program_name = "Assembly Preprocessor";
String _version_major = "2";
String _version_minor = "1";
String _version_patch = "0";
String _version_preRelease;// = "1";
String _VERSION = "V" + _version_major + "." + _version_minor + "." + _version_patch + (_version_preRelease != null ? "-pr." + _version_preRelease : "");
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
    
    _output.append("; This .obj file was produced by: " + _program_name + " " + _VERSION); // append some data to the start of the output file
    _output.append("; " + getLabelUUID());
    _output.append(""); _output.append("");
    
    updateVariable("__concatenateFiles", "true");
    updateVariable("__maintainComments", "false");
    updateVariable("__showLines", "false");
    updateVariable("__hyperVerboseOutput", "false");
    updateVariable("__initEmptyStacks", "false");
    
    updateVariable("__ext_db", "\t#d8");
    updateVariable("__ext_db_wrapStart", "((");
    updateVariable("__ext_db_wrapEnd", ")`8)");
    updateVariable("__ext_dw", "\t#d16");
    updateVariable("__ext_dw_wrapStart", "((");
    updateVariable("__ext_dw_wrapEnd", ")`16)");
    updateVariable("__ext_drw", "\t#d16");
    updateVariable("__ext_drw_wrapStart", "le((");
    updateVariable("__ext_drw_wrapEnd", ")`16)");
    
    processInput(0, ParseState.Entry);
    
    print("Stacks: "); printArray(Stacks);
    print("Variables: "); printArray(_Vars);
    println("Output file: " + _outputFile);
    saveStrings(_outputFile, _output.toArray());
    
    print("Total Macros: " + Macros.size());printArray(Macros);
    println("Total Macro Args Pushed: " + MacroArgsStack.size()); // should be 0 when done
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

String getLastOutputLine(){
  if(_output.size() > 0){
    return _output.get(_output.size() - 1);
  }
  return "";
}
