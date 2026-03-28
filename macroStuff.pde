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
  FileHolder File; // ...or current file.
  
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
  
  String toString(){
    return ""; // for "clean" printing of macro list
  }
}

void buildMacro(){
  //println("<buildMacro>");
  //println(line_);
  TokenReturn token = getNextToken(true);
  int originLine = getIndex();
  String name = token.string;
  MacroArg[] args = getMacroArgs(CurrentLineInput, token.nextIndex);
  StringList content = new StringList();
  IntList lineNum = new IntList();
  int state = 0;
  incIndex(); // skip .macro line
  
  for(; getIndex() < getFileLength() && state != -1; incIndex()){
    CurrentLineInput = getLine();
    //println(line);
    CurrentInputIndex = 0;
    token = getNextToken(false);
    
    switch(token.string){
      case ".endm":
        //println("<endm>");
        Macros.put(name, new Macro(name, args, content.toArray(), lineNum.toArray(), getFileName(), originLine));
        state = -1;
        break;
      default:
        content.append(CurrentLineInput);
        lineNum.append(getIndex());
        break;
    }
  }
  
  decIndex(); // main loops ++ at end, so we have to -- to be on correct line for next main loop
}

MacroArg[] getMacroArgs(String line, int index){
  if(hyperVerboseOutput){ println("getMacroArgs: " + line); }
  ArrayList<MacroArg> args = new ArrayList<MacroArg>();
  MacroArg tmp = new MacroArg();
  boolean isDefault = false;
  String token = "";
  boolean inString = false;
  boolean gotString = true; // somewhere along the lines, leading/trailing space aren't being handled correctly as #strLen doesn't see them...
  int state = 0;
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
              args.add(new MacroArg(gotString ? tmp : tmp.strip()));
              isDefault = false;
              token = "";
              state = -1;
            }
            break;
          
          case ',': // each, , of, these, are, tokens = ["each", "", "of", "these", "are", "tokens"]
            if(!inString){
              if(isDefault == true){ tmp.Value = token; }
              else{ tmp.Name = token; }
              args.add(new MacroArg(gotString ? tmp : tmp.strip()));
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
          
          case '\\':
            TokenReturn output = cleanEscape(line, index, true);
            index = output.nextIndex;
            token += output.string;
            break;
          
          case '(':
            token += c;
            if(!inString){ parenDepth++; state = 1; }
            break;
          
          case ')':
            token += c;
            //if(!inString){ parenDepth--; } // mismatched parens!
            break;
          
          case ' ': // ignore whitespace unless we're in a string
          case '\t':
          case '\r':
          case '\n':
            if(inString){
              token += c;
            }
            break;
          
          case '"':
            gotString = true;
            inString = !inString;
          default:
            token += c;
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
          
          case ' ': // ignore whitespace unless we're in a string
          case '\t':
          case '\r':
          case '\n':
            if(inString){
              token += c;
            }
            break;
          
          case '"':
            gotString = true;
            inString = !inString;
          default:
            token += c;
            break;
        }
        break;
    }
  }
  if(token.length() != 0){
    if(isDefault == true){ tmp.Value = token; }
    else{ tmp.Name = token; }
    args.add(new MacroArg(gotString ? tmp : tmp.strip()));
  }
  
  MacroArg[] output = new MacroArg[args.size()];
  for(int i = 0; i < output.length; i++){
    output[i] = args.get(i);
  }
  
  return output;
}

boolean checkMacros(String macro){
  Macro tmp = Macros.get(macro);
  if(tmp != null){
    //println("checkMacro: " + macro);
    //print("pushing macro args: ");printArray(CurrentMacroArgs);
    MacroArgsStack.add(CurrentMacroArgs != null ? CurrentMacroArgs.clone() : null);
    pushTmpVars();
    //println("setting macro args @ " + CurrentWorker.getOrigin() + getFileName() + " @ " + (getIndex()+1));
    CurrentMacroArgs = getMacroArgs(CurrentLineInput, CurrentInputIndex).clone();
    //printArray(CurrentMacroArgs);
    Workers.add(new Worker(CurrentWorker));
    CurrentWorker = new Worker(tmp);
    setIndex(-1); // needs to be -1 due to a ++ at end of main loop
    return true;
  }
  return false;
}
