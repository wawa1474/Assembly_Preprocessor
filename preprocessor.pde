String[] input;
StringList _output;
IntDict defines;
String link = "0";
boolean _followIncludes = true;
ArrayList<FileHolder> _FileHolder;
boolean _exit = true;
FileHolder tmpFileHolder = new FileHolder();
ArrayList<Macro> _Macros;

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
  while(tmpFileHolder.indexArray < tmpFileHolder.contents.length){
    skip = false;
    String line = tmpFileHolder.contents[tmpFileHolder.indexArray];
    tmpFileHolder.indexArray++;
    
    if(line.contains(".macro")){
      buildMacro(line);
      continue;
    }
    //else if(line.contains("dfw")){
    //  output_dfw(breakLine(tmpFileHolder.indexArray, "dfw", 4, line));
    //}
    else{
      for(int i = 0; i < _Macros.size(); i++){
        Macro m = _Macros.get(i);
        if(line.contains(m.name)){
          outputMacro(m, breakLine(tmpFileHolder.indexArray-1, m.name, m.name.length()+1, line));
          skip = true; break;
        }
      }
    }
    
    //if(line.contains("defword")){
    //  output_defword(breakLine(i, "defword", 8, line));
    //  continue;
    //}else if(input[i].contains("defcode")){
    //  output_defcode(breakLine(i, "defcode", 8, line));
    //  continue;
    //}else if(input[i].contains("defvar")){
    //  output_defvar(breakLine(i, "defvar", 7, line));
    //  continue;
    //}else if(input[i].contains("defconst")){
    //  output_defconst(breakLine(i, "defconst", 9, line));
    //  continue;
    //}else if(line.contains("#def")){
    //  String[] def = split(line, ' ');
    //  if(defines.hasKey(def[1])){
    //    println("\"" + def[1] + "\" already defined!");
    //  }else{
    //    defines.set(def[1],0);
    //  }
    //  continue;
    //}else if(line.contains("#ifdef")){
    //  String[] def = split(line, ' ');
    //  if(defines.hasKey(def[1])){
    //    while(!line.contains("#endifdef")){
    //      line = tmpFileHolder.contents[i++];
    //      output.append(line); // append lines for assembly
    //    }
    //  }else{
    //    while(!line.contains("#endifdef")){
    //      line = tmpFileHolder.contents[i++]; // eat input
    //    }
    //    i--;
    //  }
    //  continue;
    //}else if(line.contains("#ifndef")){
    //  String[] def = split(line, ' ');
    //  if(!defines.hasKey(def[1])){
    //    while(!line.contains("#endifndef")){
    //      line = tmpFileHolder.contents[i++];
    //      output.append(line); // append lines for assembly
    //    }
    //  }else{
    //    while(!line.contains("#endifndef")){
    //      line = tmpFileHolder.contents[i++]; // eat input
    //    }
    //    i--;
    //  }
    //  continue;
    //}
    
    if(!skip){
      _output.append(line);
    }
  }
  
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
  String[] output;
  
  Macro(String n, String[] o){
    name = n;
    output = o;
  }
}

//String[] breakLine(int lineNum, String macro, int pos, String line){
//  //println(lineNum);
//  StringList out = new StringList();
//  String tmp = "";
//  boolean str = false;
//  //boolean comment = false;
//  int start = line.indexOf(macro) + macro.length();
//  //println(start);
//  if(start != pos){ println(lineNum); return null; }
  
//  for(int i = start; i < line.length(); i++){
//    char c = line.charAt(i);
//    if(c == '"'){ if(line.contains("\"\"\"")){ out.append("\"\"\""); tmp = ""; i+=1; continue; } str = !str; }
//    if(c == ';' && !(line.charAt(i-1) == '"' && line.charAt(i+1) == '"')){ break; }
//    if(c == ' '){ continue; }
//    //if(c == ',' && !(line.charAt(i-1) == '"' && line.charAt(i+1) == '"')){
//    if(c == ','){
//      if(str != true){
//        out.append(tmp);
//        tmp = "";
//        continue;
//      }
//    }
//    tmp += c;
//  }
//  out.append(tmp);
  
//  return out.toArray();
//}

String[] breakLine(int lineNum, String macro, int pos, String line){
  //println(lineNum);
  StringList out = new StringList();
  String tmp = "";
  boolean str = false;
  //boolean comment = false;
  int start = line.indexOf(macro) + macro.length();
  //println(start);
  //if(start != pos){ println(lineNum); return null; }
  
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
