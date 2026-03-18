class PathReturn{ // "../../path/to/file/code.asm"
  String[] PathArray; // {"path", "to", "file"}
  String Name; // "code"
  String Extension; // "asm"
  int Reverse; // "2"
  
  String getPath(){
    String output = "";
    for(int i = 0; i < PathArray.length; i++){
      output += PathArray[i] + "\\";
    }
    return output;
  }
  
  String getPathPartial(){
    String output = "";
    for(int i = Reverse; i < PathArray.length; i++){
      output += PathArray[i] + "\\";
    }
    return output;
  }
  
  String getFile(){
    return Name + "." + Extension;
  }
  
  String getAll(){
    String output = "";
    for(int i = 0; i < Reverse; i++){
      output += "..\\";
    }
    return output + toString();
  }
  
  String toString(){
    return getPath() + getFile();
  }
}

class FileHolder{
  PathReturn file;
  String filename;
  String baseDirectory;
  String[] contents;
  int indexArray;
  int indexChar;
  
  String getLine(int l){
    if(l < contents.length){
      return contents[l];
    }
    return null;
  }
  
  String getLine(){
    if(indexArray < contents.length){
      return contents[indexArray];
    }
    return null;
  }
  
  String getNextLine(){
    indexArray++;
    if(indexArray < contents.length){
      return contents[indexArray];
    }
    return null;
  }
  
  void nextLine(){
    indexArray++;
  }
  
  int linesLeft(){
    return contents.length - indexArray;
  }
}

class FileStack{
  ArrayList<FileHolder> files;
  int size;
  
  FileStack(){
    files = new ArrayList<FileHolder>();
    size = 0;
  }
  
  void push(FileHolder f){
    FileHolder tmp = new FileHolder();
    tmp.baseDirectory = f.baseDirectory;
    tmp.contents = f.contents;
    tmp.filename = f.filename;
    tmp.indexArray = f.indexArray;
    tmp.indexChar = f.indexChar;
    files.add(tmp);
    size++;
  }
  
  FileHolder pop(){
    size--;
    return files.remove(size);
  }
  
  String getLine(int l){
    return files.get(size - 1).getLine(l);
  }
  
  String getLine(){
    return files.get(size - 1).getLine();
  }
  
  String getNextLine(){
    return files.get(size - 1).getNextLine();
  }
  
  void nextLine(){
    files.get(size - 1).indexArray++;
  }
  
  int linesLeft(){
    return files.get(size - 1).linesLeft();
  }
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
  output.PathArray = path.toArray();
  output.Extension = tmp;
  
  return output;
}

void getNewFile(String base, PathReturn file){
  println("getNewFile: " + base + file);
  _tmpFileHolder.file = file;
  _tmpFileHolder.filename = file.getAll();
  _tmpFileHolder.baseDirectory = file.getPath();
  _tmpFileHolder.contents = loadStrings(base + file);
  _tmpFileHolder.indexArray = 0;
  _tmpFileHolder.indexChar = 0;
}
