StringList _output;
String _outputFile;
boolean _exit = true;
FileStack _FileStack; // stack to hold loaded files
FileHolder _tmpFileHolder = new FileHolder(); // tmp variable to hold current working file
ArrayList<Macro> _Macros;
StringDict _Vars;

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
  if(args != null){ // allows input from command line
    //println(args.length);
    for (int i = 0; i < args.length; i++) {
      String arg = args[i];
      //println(arg);
      if(arg.contains("--input")){
        PathReturn filename = splitFilepath(split(arg, '=')[1]);
        println("Input: " + filename);
        _outputFile = filename.getPath() + filename.Name + ".obj";
        getNewFile("", filename);
        _exit = false;
      }else if(arg.contains("--help")){
        _exit = true;
      }
    }
  }
  
  println(sketchPath());
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
    
    processInput();
  }
  exit();
}

void processInput(){
  _output = new StringList();
  
  boolean skip = false;
  while(_tmpFileHolder.indexArray < _tmpFileHolder.contents.length){ //1890){//
    skip = false;
    String line = _tmpFileHolder.contents[_tmpFileHolder.indexArray];
    _tmpFileHolder.indexArray++;
    
    TokenReturn firstToken = getNextToken(line, 0);
    
    if(firstToken.string.equals(".include")){ // include macro definition file ('.' may need to be configurable based on assembler)
      println((_tmpFileHolder.indexArray-1) + " : " + line);
      buildMacro(loadStrings(_tmpFileHolder.baseDirectory + split(line, " ")[1]));
      skip = true;
    }else if(firstToken.string.equals("#include")){ // include assembly file, which will be concatenated into one large .obj output file
      println((_tmpFileHolder.indexArray-1) + " : " + line);
      /*
        preprocessor will work through a file until it hits a #include
        at which point, it will load and push the included file
        and begin working through the new file until reaching another include or it reaches the end of the file
        if it reaches the end of the current file, pop it from the stack
        and continue working on existing files
        if no more files exist, then we are done!
      */
      //_FileStack.push(_tmpFileHolder);
      //getNewFile(_tmpFileHolder.baseDirectory, getNextToken(line, firstToken.nextIndex).string.replace("\"", ""));
    }else if(firstToken.string.equals(".if")){
      boolean ifTrue = checkIf(line, firstToken.nextIndex);
      boolean con = true;
      boolean eat = false;
      println((_tmpFileHolder.indexArray-1) + " : " + line + " = " + ifTrue);
      if(ifTrue){
        while(con == true && _tmpFileHolder.indexArray < _tmpFileHolder.contents.length){
          line = _tmpFileHolder.contents[_tmpFileHolder.indexArray];
          _tmpFileHolder.indexArray++;
          firstToken = getNextToken(line, 0);
          switch(firstToken.string){
            case ".if": // needs to be recursive! or state-based with a depth counter!
            case ".else":
            case ".elseif":
              eat = true;
              break;
            case ".endif":
              con = false;
              eat = false;
              break;
            default:
              _output.append(line);
              break;
          }
        }
        if(eat){
          while(_tmpFileHolder.indexArray < _tmpFileHolder.contents.length){
            line = _tmpFileHolder.contents[_tmpFileHolder.indexArray];
            _tmpFileHolder.indexArray++;
            firstToken = getNextToken(line, 0);
            if(firstToken.string.equals(".endif")){
              break;
            }
          }
        }
      }else{
        while(_tmpFileHolder.indexArray < _tmpFileHolder.contents.length){
          line = _tmpFileHolder.contents[_tmpFileHolder.indexArray];
          _tmpFileHolder.indexArray++;
          firstToken = getNextToken(line, 0);
          if(firstToken.string.equals(".endif")){
            break;
          }
        }
      }
      skip = true;
    }
    
    for(int i = 0; i < _Macros.size(); i++){
      Macro tmp = _Macros.get(i);
      if(tmp.name.equals(firstToken.string)){
        //println(line);
        _output.append(parseMacro(tmp, line));
        skip = true;
      }
    }
    
    //if(line.contains(".let")){
    //  setVariable(line);
    //  continue;
    //}
    
    if(!skip){
      _output.append(line);
    }
    
    if(_tmpFileHolder.indexArray >= _tmpFileHolder.contents.length && _FileStack.size > 0){
      print("pop file: " + _tmpFileHolder.filename);
      _tmpFileHolder = _FileStack.pop();
      println(" for: " + _tmpFileHolder.filename);
    }
  }
  
  printArray(_Vars);
  
  println(_outputFile);
  saveStrings(_outputFile, _output.toArray());
}
