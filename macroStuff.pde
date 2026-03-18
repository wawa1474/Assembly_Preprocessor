ArrayList<Macro> MacroStack = new ArrayList<Macro>(); // stack of macros for (nested) macros
ArrayList<MacroArg[]> MacroArgsStack = new ArrayList<MacroArg[]>(); // stack of macro args for (nested) macros
MacroArg[] CurrentMacroArgs;
HashMap<String, Macro> Macros = new HashMap<String, Macro>(); // hashmap of defined macros

ArrayList<Worker> Workers = new ArrayList<Worker>(); // how do we handle which file/macro we're currently working on!?
Worker CurrentWorker;

enum WorkerType{
  Macro,
  File,
}

class Worker{
  WorkerType Type; // which kind of thing are we currently processing
  int LineIndex; // which line are we working on
  int CharacterIndex; // which character are we working on
  Macro Macro; // storage for current macro...
  FileHolder File; // or current file.
  
  Worker(){}
  
  Worker(Worker w_){
    if(w_ != null){
      Type = w_.Type;
      LineIndex = w_.LineIndex;
      CharacterIndex = w_.CharacterIndex;
      switch(Type){
        case Macro:
          Macro = new Macro(w_.Macro);
          break;
        
        case File:
          File = new FileHolder(w_.File);
          break;
      }
    }
  }
  
  Worker(Macro m_){
    Type = WorkerType.Macro;
    Macro = m_;
  }
  
  Worker(FileHolder f_){
    Type = WorkerType.File;
    File = f_;
  }
  
  String getLine(int index_){
    switch(Type){
      case Macro: return Macro.Content[index_];
      case File: return File.contents[index_];
      default: return null;
    }
  }
  
  int getLength(){
    switch(Type){
      case Macro: return Macro.Content.length;
      case File: return File.contents.length;
      default: return 0;
    }
  }
  
  String getFileName(){
    switch(Type){
      case Macro: return Macro.Name;
      case File: return File.file.Name;
      default: return null;
    }
  }
  
  void loadFile(PathReturn directory, PathReturn file_){
    Type = WorkerType.File;
    if(File == null){ File = new FileHolder(); }
    if(File.file == null){ File.file = new PathReturn(); }
    File.file.setPath(directory, file_);
    File.load();
  }
  
  String toString(){
    return Type == WorkerType.File ? "File" : "Macro";
  }
  
  String getOrigin(){
    return Type == WorkerType.Macro ? Macro.OriginFile + " @ " + Macro.OriginLine + " : " : "";
  }
  
  MacroArg[] getArgs(){
    if(Macro != null){ return Macro.Args; }
    return null;
  }
}

class MacroArg{
  String Name; // name of argument
  String Value; // (default) value of argument
  
  MacroArg(){}
  
  MacroArg(MacroArg m_){
    Name = m_.Name;
    Value = m_.Value;
  }
  
  MacroArg strip(){ // strip leading/trailing spaces
    if(Name != null){ Name = Name.strip(); }
    if(Value != null){ Value = Value.strip(); }
    return this;
  }
  
  String toString(){
    return "<" + Name + ":" + Value + ">";
  }
}

class Macro{ // MacroFile combined class? plus a pun...
  String OriginFile; // which file was this macro defined in...
  int OriginLine; // and on which line.
  String Name; // (redundant, but still useful) name of macro
  MacroArg[] Args; // array of defined macro arguments
  String[] Content; // content / code of macro...
  int[] ContentLine; // and which lines of Origin file each was on.
  
  Macro(Macro m_){
    Name = m_.Name;
    Args = m_.Args;
    Content = m_.Content;
    OriginFile = m_.OriginFile;
    OriginLine = m_.OriginLine;
    ContentLine = m_.ContentLine;
  }
  
  Macro(String n_, MacroArg[] a_, String[] c_, int[] k_, String f_, int l_){
    Name = n_;
    Args = a_;
    Content = c_;
    OriginFile = f_;
    OriginLine = l_;
    ContentLine = k_;
  }
}

void buildMacro(String line_, int index_){
  TokenReturn token = getNextToken(line_, index_);
  int originLine = getIndex();
  String name = token.string;
  MacroArg[] args = getMacroArgs(line_, token.nextIndex, 0);
  StringList content = new StringList();
  IntList lineNum = new IntList();
  int state = 0;
  incIndex(); // skip .macro line
  
  for(; getIndex() < getFileLength() && state != -1; incIndex()){
    String line = getLine();
    token = getNextToken(line,0);
    
    switch(token.string){
      case ".endm":
        Macros.put(name, new Macro(name, args, content.toArray(), lineNum.toArray(), getFileName(), originLine));
        state = -1;
        break;
      default:
        content.append(line);
        lineNum.append(getIndex());
        break;
    }
  }
  
  decIndex(); // main loops ++ at end, so we have to -- to be on correct line for next main loop
}

MacroArg[] getMacroArgs(String line, int index, int depth){
  //println("getMacroArgs: " + line);
  ArrayList<MacroArg> args = new ArrayList<MacroArg>();
  MacroArg tmp = new MacroArg();
  boolean isDefault = false;
  String token = "";
  boolean inString = false;
  int state = 0;
  boolean prevNeedSpace = false;
  int parenDepth = 0;
  
  for(; index < line.length() && state != -1; index++){
    char c = line.charAt(index);
    //print(c);
    
    switch(state){
      case 0:
        switch(c){
          case ';':
            if(inString){
              token += c;
            }else{
              if(isDefault == true){ tmp.Value = token; }
              else{ tmp.Name = token; }
              args.add(new MacroArg(tmp.strip()));
              isDefault = false;
              token = "";
              state = -1;
            }
            break;
          
          case ',': // each, , of, these, are, tokens = ["each", "", "of", "these", "are", "tokens"]
            if(!inString){
              if(isDefault == true){ tmp.Value = token; }
              else{ tmp.Name = token; }
              args.add(new MacroArg(tmp.strip()));
              isDefault = false;
              token = "";
            }else{
              token += c;
            }
            break;
          
          case '=':
            if(!inString){
              isDefault = true;
              tmp.Name = token;
              token = "";
            }else{
              token += c;
            }
            break;
          
          //case ' ':
          //  if(prevNeedSpace){
          //    token += c;
          //    prevNeedSpace = false;
          //  }
          //  break;
          
          //case ' ': // each of these are tokens
          //  if(!inString){
          //    if(token.length() != 0){ Args.append(token); } // don't, split, on,[ ]after, comma
          //    token = "";
          //  }else{
          //    token += c;
          //  }
          //  break;
          
          //case ' ':
          //  if(!inString){
          //    int prev = index - 1;
          //    int next = index + 1;
          //    if((prev >= 0 && line.charAt(prev) == ',') || (next < line.length() && line.charAt(next) == ',')){
          //      // don't append prefix/suffix spaces -- ,[ ]arg=default[ ],
          //    }else{
          //      token += c; // maintain spaces WITHIN args
          //    }
          //  }else{
          //    token += c;
          //  }
          //  break;
          
          case '\\':
            TokenReturn output = cleanEscape(line, index, depth);
            index = output.nextIndex;
            token += output.string;
            break;
          
          case '(':
            token += c;
            if(!inString){ parenDepth++; }
            break;
          
          case ')':
            token += c;
            if(!inString){ parenDepth--; }
            break;
          
          case '"':
            inString = !inString;
          default:
            token += c;
            if(isNumber(c) || isAlpha(c)){ prevNeedSpace = true; }
            else{ prevNeedSpace = false; }
            break;
        }
        break;
      
      case 1:
        switch(c){
          case '(':
            token += c;
            if(!inString){ parenDepth++; }
            break;
          
          case ')':
            token += c;
            if(!inString){ parenDepth--; }
            if(parenDepth == 0){ state = 0; }
            break;
        }
        break;
    }
  }
  if(token.length() != 0){
    if(isDefault == true){ tmp.Value = token; }
    else{ tmp.Name = token; }
    args.add(new MacroArg(tmp.strip()));
  }
  
  MacroArg[] output = new MacroArg[args.size()];
  for(int i = 0; i < output.length; i++){
    output[i] = args.get(i);
  }
  
  return output;
}

boolean checkMacros(String macro, String line, int index){
  Macro tmp = Macros.get(macro);
  if(tmp != null){
    //println("checkMacro: " + macro);
    //_Files_Type = _Files_Macros; // now handled by worker.type
    MacroArgsStack.add(CurrentMacroArgs);
    CurrentMacroArgs = getMacroArgs(line, index, 0); // MacroArgsStack.add(getMacroArgsHash(line, index, 0)); // pushMacroArgs(getMacroArgs(line, index, 0));
    Workers.add(new Worker(CurrentWorker)); // _Files[_Files_Inputs].add(new FileHolder(_tmpFileHolder));
    CurrentWorker = new Worker(tmp); // _tmpFileHolder = new FileHolder(tmp);
    setIndex(-1); // needs to be -1 due to a ++ at end of main loop
    //printArray(CurrentMacroArgs);
    return true;
  }
  return false;
}
