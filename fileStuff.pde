class PathReturn{ // "../../path/to/file/code.asm"
  String[] PathArray; // {"path", "to", "file"}
  String Name; // "code"
  String Extension; // "asm"
  int Reverse; // "2"
  
  PathReturn(){
    PathArray = new String[0];
    Name = "";
    Extension = "";
    Reverse = 0;
  }
  
  PathReturn(PathReturn input){ // has any one ever said that Java's pass-by-reference vs. pass-by-value sucks?
    if(input != null){
      if(input.PathArray != null){
        PathArray = new String[input.PathArray.length];
        for(int i = 0; i < input.PathArray.length; i++){
          PathArray[i] = input.PathArray[i];
        }
      }
      Name = input.Name;
      Extension = input.Extension;
      Reverse = input.Reverse;
    }
  }
  
  PathReturn(String n, String[] p, int r){
    Name = n;
    PathArray = p;
    Reverse = r;
  }
  
  String getPath(){
    String output = "";
    for(int i = 0; i < PathArray.length; i++){
      output += PathArray[i] + "\\";
    }
    return output;
  }
  
  void setPath(PathReturn directory, PathReturn file){
    int dirLength = directory.PathArray.length - file.Reverse;
    String[] tmp = new String[dirLength + file.PathArray.length];
    
    for(int i = 0; i < dirLength; i++){
      tmp[i] = directory.PathArray[i];
    }
    for(int i = 0; i < file.PathArray.length; i++){
      tmp[dirLength + i] = file.PathArray[i];
    }
    
    PathArray = tmp;
    Name = file.Name;
    Extension = file.Extension;
    Reverse = file.Reverse;
  }
  
  String getFile(){
    return Name + "." + Extension;
  }
  
  String toString(){
    return getPath() + getFile();
  }
}

class FileHolder{
  PathReturn file;
  String[] contents;
  int indexArray;
  
  FileHolder(){}
  
  FileHolder(PathReturn f, String[] c){
    file = f;
    contents = c;
    indexArray = 0;
  }
  
  FileHolder(FileHolder input){
    if(input != null){
      file = new PathReturn(input.file);
      if(input.contents != null){
        contents = new String[input.contents.length];
        for(int i = 0; i < input.contents.length; i++){
          contents[i] = input.contents[i];
        }
      }
      indexArray = input.indexArray;
    }
  }
  
  void setPath(PathReturn directory, PathReturn file_){
    if(file == null){ file = new PathReturn(); }
    file.setPath(directory, file_);
  }
  
  void load(){
    contents = loadStrings(file.getPath() + file.getFile());
    indexArray = 0;
  }
}

void checkIncludeFile(String line, int index){
  getNewFile(getFile().file, getNextToken(line,index).string);
}

PathReturn splitFilepath(String file){
  PathReturn output = new PathReturn();
  String tmp = "";
  int state = 0;
  StringList path = new StringList();
  
  // ../../path/to/file.ext
  // ./../path/to/file.ext
  // ./path/to/file.ext
  // /path/to/file.ext
  // path/to/file.ext
  // path/to
  
  for(int i = 0; i < file.length(); i++){
    char c = file.charAt(i);
    switch(state){
      case 0:
        switch(c){
          case '.': // "./", "../"
            state = 1;
            break;
          case '/': // "/"
          case '\\':
            state = 3;
            break;
          default:
            tmp += c;
            state = 4;
            break;
        }
        break;
      
      case 1:
        switch(c){
          case '.': // "../"
            state = 2;
            break;
          case '/': // "./"
          case '\\':
            state = 3;
            break;
          default:
            tmp += c;
            state = 4;
            break;
        }
        break;
      
      case 2:
        switch(c){
          case '/': // "../"
          case '\\':
            output.Reverse++;
            state = 3;
            break;
          default:
            tmp += c;
            state = 4;
            break;
        }
        break;
      
      case 3:
        switch(c){
          case '.': // "/.", "./.", "../."
            state = 1;
            break;
          default:
            tmp += c;
            state = 4;
            break;
        }
        break;
      
      case 4:
        switch(c){
          case '/':
          case '\\':
            path.append(tmp);
            tmp = "";
            state = 4;
            break;
          case '.':
            output.Name = tmp;
            tmp = "";
            state = 5;
            break;
          default:
            tmp += c;
            state = 4;
            break;
        }
        break;
      
      case 5:
        switch(c){
          case '.': // "name.blah.asm
            output.Name += "." + tmp;
            tmp = "";
            state = 5;
            break;
          default:
            tmp += c;
            state = 5;
            break;
        }
    }
  }
  switch(state){
    case 4: // handle directory w/o file
      path.append(tmp);
      break;
    default:
      output.Extension = tmp;
      break;
  }
  output.PathArray = path.toArray();
  
  
  return output;
}

void getNewFile(PathReturn base, PathReturn file){
  //if(_tmpFileHolder.contents != null && checkFileName()){ // I think we need to ALWAYS push 'old' file to stack...
  if(CurrentWorker != null){
    //println("push file");
    Workers.add(new Worker(CurrentWorker));
  }else{
    CurrentWorker = new Worker();
  }
  //}
  CurrentWorker.loadFile(base, file);
}

void getNewFile(PathReturn base, String line){
  getNewFile(base, splitFilepath(line.replace("\"", "")));
  setIndex(-1); // needs to be -1 due to a ++ at end of main loop
}

//void popFileIfLastLine(){
//  while(getIndex() >= getFileLength() - 1 && _Files.size() > 0){
//    if(CurrentWorker.File.file.Reverse == _PathReturn_Reverse_Macro){ popMacroArgs(); } // also pop macro's args from arg stack
//    _Files_Type = _Files_Inputs;
//    CurrentWorker.File = new FileHolder(_Files.remove(_Files.size() - 1));
//  }
//}

void popFileIfLastLine(){
  //print("<" + Workers.size() + ">");printArray(Workers);
  while(getIndex() >= getFileLength() - 1 && Workers.size() > 0){
    //println("pop file");
    if(CurrentWorker.Type == WorkerType.Macro && MacroArgsStack.size() > 0){ popMacroArgs(); } // also pop macro's args from arg stack
    CurrentWorker = new Worker(Workers.remove(Workers.size() - 1));
  }
}
