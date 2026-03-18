String[] input;
StringList output;
IntDict defines;
String link = "0";

//@echo off
//java -Djava.ext.dirs=lib -Djava.library.path=lib floatToHex

//processing-java's directory must be added to PATH
//--sketch refers the the directory, not the file
//anything after --run is passed as args
//processing-java.exe --sketch=%~dp0 --run 123 123

/*
  has to handle includes as well, but should be able to be told not to bother
    #pragma noFloats #include "path/file.ext"
    #include "path/file.ext"
*/

void setup(){
  //input = loadStrings("../jonesforthPreprocessor.asm");
  //output = new StringList();
  //defines = new IntDict();
  
  //for(int i = 0; i < input.length; i++){
  //  //if(input[i].contains("####PREPROCESSOR")){
  //  //  println(input[i]);
  //  //}
  //  //if(input[i].contains("defcode")){
  //  //  String[] line = breakLine("defcode", input[i]);
  //  //  if(line != null){ println(line); }
  //  //}
  //  if(input[i].contains("defword")){
  //    output_defword(breakLine(i, "defword", 8, input[i]));
  //    continue;
  //  }
  //  if(input[i].contains("defcode")){
  //    output_defcode(breakLine(i, "defcode", 8, input[i]));
  //    continue;
  //  }
  //  if(input[i].contains("defvar")){
  //    output_defvar(breakLine(i, "defvar", 7, input[i]));
  //    continue;
  //  }
  //  if(input[i].contains("defconst")){
  //    output_defconst(breakLine(i, "defconst", 9, input[i]));
  //    continue;
  //  }
  //  if(input[i].contains("#def")){
  //    String[] def = split(input[i], ' ');
  //    if(defines.hasKey(def[1])){
  //      println("\"" + def[1] + "\" already defined!");
  //    }else{
  //      defines.set(def[1],0);
  //    }
  //    continue;
  //  }
  //  if(input[i].contains("#ifdef")){
  //    String[] def = split(input[i], ' ');
  //    if(defines.hasKey(def[1])){
  //      while(!input[i].contains("#endifdef")){
  //        i++;
  //        output.append(input[i]); // append lines for assembly
  //      }
  //    }else{
  //      while(!input[i].contains("#endifdef")){
  //        i++; // eat input
  //      }
  //    }
  //    continue;
  //  }
  //  if(input[i].contains("#ifndef")){
  //    String[] def = split(input[i], ' ');
  //    if(!defines.hasKey(def[1])){
  //      while(!input[i].contains("#endifndef")){
  //        i++;
  //        output.append(input[i]); // append lines for assembly
  //      }
  //    }else{
  //      while(!input[i].contains("#endifndef")){
  //        i++; // eat input
  //      }
  //    }
  //    continue;
  //  }
    
  //  output.append(input[i]);
  //}
  ////printArray(breakLine("defcode", input[694]));
  
  //saveStrings("../jonesforthProcessed.asm", output.toArray());
  
  if(args != null){ // allows input from command line
    println(args.length);
    for (int i = 0; i < args.length; i++) {
      println(args[i]);
    }
  }
  exit();
}

void draw(){
  
}

String[] breakLine(int lineNum, String macro, int pos, String line){
  //println(lineNum);
  StringList out = new StringList();
  String tmp = "";
  boolean str = false;
  //boolean comment = false;
  int start = line.indexOf(macro) + macro.length();
  //println(start);
  if(start != pos){ println(lineNum); return null; }
  
  for(int i = start; i < line.length(); i++){
    char c = line.charAt(i);
    if(c == '"'){ if(line.contains("\"\"\"")){ out.append("\"\"\""); tmp = ""; i+=1; continue; } str = !str; }
    if(c == ';' && !(line.charAt(i-1) == '"' && line.charAt(i+1) == '"')){ break; }
    if(c == ' '){ continue; }
    //if(c == ',' && !(line.charAt(i-1) == '"' && line.charAt(i+1) == '"')){
    if(c == ','){
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
