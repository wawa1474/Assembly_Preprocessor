String[] input;
StringList _output;
IntDict defines;
String link = "0";
boolean _followIncludes = true;
ArrayList<FileHolder> _FileHolder;
boolean _exit = true;
FileHolder tmpFileHolder = new FileHolder();
ArrayList<Macro> _Macros;
//ArrayList<Variable> _Vars;
StringDict _Vars;
String baseDirectory = "";

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
        tmpFileHolder.filename = split(arg, '=')[1];
        _exit = false;
      }else if(arg.contains("--no-include")){
        _followIncludes = false;
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
    println("\tOutput filenames will be <input-filename>.obj");
    println("\tIncludes will use their respective filename. <include-directory>\\<include-filename>.obj");
    println("--no-include - Don't recurse through includes.");
    println("\tYou can also disable recursing certain includes by preceding it with #no-include. (#no-include \"include.ext\")");
  }else{
    _FileHolder = new ArrayList<FileHolder>();
    _Macros = new ArrayList<Macro>();
    _Vars = new StringDict(); //ArrayList<Variable>();
    //for(int i = tmpFileHolder.filename.length() - 1; i >= 0; i--){
    //  if(tmpFileHolder.filename.charAt(i) == '\\' || tmpFileHolder.filename.charAt(i) == '/'){
    //    //baseDirectory = tmpFileHolder.filename.lastIndexOf()
    //    //baseDirectory = tmpFileHolder.filename.subSequence(0,i);
    //    //baseDirectory = tmpFileHolder.filename.substring(0,i);
    //    String b = tmpFileHolder.filename;
    //    baseDirectory = b.substring(0,b.contains("/")?b.lastIndexOf("/"):b.lastIndexOf("\\"));
    //    println(baseDirectory);
    //    break;
    //  }
    //}
    String b = tmpFileHolder.filename;
    baseDirectory = b.substring(0, 1 + (b.contains("/")?b.lastIndexOf("/"):b.lastIndexOf("\\")));
    println(baseDirectory);
    processInput();
  }
  
  exit();
}

void processInput(){
  println(tmpFileHolder.filename);
  tmpFileHolder.contents = loadStrings(tmpFileHolder.filename);
  String[] stmp = split(tmpFileHolder.filename, ".\\");
  tmpFileHolder.output = split(stmp[stmp.length-1], '.')[0] + ".obj";
  tmpFileHolder.followIncludes = _followIncludes;
  tmpFileHolder.indexArray = 0;
  tmpFileHolder.indexChar = 0;
  
  _output = new StringList();
  defines = new IntDict();
  
  boolean skip = false;
  while(tmpFileHolder.indexArray < 140){//tmpFileHolder.contents.length){
    skip = false;
    String line = tmpFileHolder.contents[tmpFileHolder.indexArray];
    tmpFileHolder.indexArray++;
    
    //print(tmpFileHolder.indexArray);
    //printArray(cleanTokens(splitToken(line)));
    //println();
    
    if(line.contains(".include")){ // include macro definition file ('.' may need to be configurable based on assembler)
      println((tmpFileHolder.indexArray-1) + " : " + line);
      buildMacro(loadStrings(baseDirectory + split(line, " ")[1]));
    }else if(line.contains("#include")){ // include assembly file, which will be concatenated into one large .obj output file
      println((tmpFileHolder.indexArray-1) + " : " + line);
    }
    
    //if(line.contains(".let")){
    //  setVariable(line);
    //  continue;
    //}
    
    //if(line.contains(".macro")){
    //  buildMacro(line);
    //  continue;
    //}
    ////else if(line.contains("dfw")){
    ////  output_dfw(breakLine("dfw", line));
    ////}
    //else{
    //  for(int i = 0; i < _Macros.size(); i++){
    //    Macro m = _Macros.get(i);
    //    if(line.contains(m.name)){
    //      outputMacro(m, breakLine(m.name, line));
    //      skip = true; break;
    //    }
    //  }
    //}
    
    if(!skip){
      _output.append(line);
    }
  }
  
  printArray(_Vars);
  
  println(tmpFileHolder.output);
  saveStrings(tmpFileHolder.output, _output.toArray());
}

class FileHolder{
  String filename;
  String output;
  boolean followIncludes;
  String[] contents;
  int indexArray;
  int indexChar;
}

class Macro{
  String name;
  String[] args;
  String[] output;
  Token[] Tokens;
  
  Macro(){}
  
  Macro(String n, String[] o){
    name = n;
    output = o;
  }
  
  Macro(String n, Token[] t){
    name = n;
    Tokens = t;
  }
  
  String argString(){
    String tmp = name + ": [" + args.length + "] " + args[0];
    for(int i = 1; i < args.length; i++){
      tmp += ", " + args[i];
    }
    return tmp;
  }
}

class Token{
  TokenType Type = TokenType.Null;
  String Str;
  String Value;
  Macro macro;
  
  Token(){}
  
  Token(TokenType t){
    Type = t;
  }
  
  Token(TokenType t, String s){
    Type = t;
    Str = s;
  }
  
  String toString(){
    if(Type == TokenType.Macro){
      return "{Macro} " + macro.argString();
    }else if(Type == TokenType.Let){
      return "{Let} " + Str + " = " + Value;
    }else if(Type == TokenType.GlobalLabel || Type == TokenType.Argument){
      return "{" + Type.name() + "} " + Value;
    }else{
      return "{" + Type.name() + "} " + Str;
    }
  }
}

class Variable{
  String name;
  String value;
  
  Variable(String n, String v){
    name = n;
    value = v;
  }
}

String[] breakLine(String macro, String line){
  StringList out = new StringList();
  String tmp = "";
  boolean str = false;
  int start = line.indexOf(macro) + macro.length();
  
  for(int i = start; i < line.length(); i++){
    char c = line.charAt(i);
    if(c == '\\' && str){
      tmp += "\\u{";
      i++;
      tmp += hex(line.charAt(i),2);
      tmp += "}";
      continue;
    }
    else if(c == '"'){ str = !str; }
    else if(c == ';' && !str){ break; }
    else if(c == ' '){ continue; }
    //if(c == ',' && !(line.charAt(i-1) == '"' && line.charAt(i+1) == '"')){
    else if(c == ','){
      if(str != true){
        out.append(tmp);
        tmp = "";
        continue;
      }
    }
    tmp += c;
  }
  out.append(tmp);
  
  return out.toArray();
}
