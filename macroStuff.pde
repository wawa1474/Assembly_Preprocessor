ArrayList<Macro> MacroStack = new ArrayList<Macro>(); // stack of macros for (nested) macros
ArrayList<MacroArg[]> MacroArgsStack = new ArrayList<MacroArg[]>(); // stack of macro args for (nested) macros
HashMap<String, Macro> Macros = new HashMap<String, Macro>(); // hashmap of defined macros

ArrayList<Worker> Workers = new ArrayList<Worker>(); // how do we handle which file/macro we're currently working on!?

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
    Name = Name.strip();
    Value = Value.strip();
    return this;
  }
}

class Macro{ // MacroFile combined class? plus a pun...
  String OriginFile; // which file was this macro defined in...
  int OriginLine; // and on which line.
  String Name; // (redundant, but still useful) name of macro
  MacroArg[] Args; // array of defined macro arguments
  String[] Content; // content / code of macro...
  int[] ContentLine; // and which lines of Origin file each was on.
  
  Macro(String n_, MacroArg[] a_, String[] c_, int[] k_, String f_, int l_){
    Name = n_;
    Args = a_;
    Content = c_;
    OriginFile = f_;
    OriginLine = l_;
    ContentLine = k_;
  }
}

void buildMacroHash(String line_, int index_){
  TokenReturn token = getNextToken(line_, index_);
  int originLine = getIndex();
  String name = token.string;
  MacroArg[] args = getMacroArgsHash(line_, token.nextIndex, 0);
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

MacroArg[] getMacroArgsHash(String line, int index, int depth){
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
            if(!inString && isDefault == true){
              // error!
            }else{
              isDefault = true;
              tmp.Name = token;
              token = "";
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
  
  return (MacroArg[])args.toArray();
}

void buildMacro(String line_, int index){
  println("Start Macro!");
  TokenReturn token = getNextToken(line_, index);
  _macro_Name = token.string;
  _macro_Args = getMacroArgs(line_, token.nextIndex, 0);
  int state = 0;
  incIndex(); // skip .macro line
  
  for(; getIndex() < getFileLength() && state != -1; incIndex()){
    String line = getLine();
    token = getNextToken(line,0);
    
    switch(token.string){
      case ".endm":
        finalizeNewMacro();
        state = -1;
        break;
      default:
        _macro_Content.append(line);
        break;
    }
  }
  
  decIndex(); // main loops ++ at end, so we have to -- to be on correct line for next main loop
}

String[] getMacroArgs(String line, int index, int depth){
  //println("getMacroArgs: " + line);
  StringList Args = new StringList();
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
              Args.append(token);
              token = "";
              state = -1;
            }
            break;
          
          case ',': // each, , of, these, are, tokens = ["each", "", "of", "these", "are", "tokens"]
            if(!inString){
              Args.append(token);
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
    }
  }
  //println();
  if(token.length() != 0){ Args.append(token); }
  
  String[] output = new String[Args.size()];
  for(int i = 0; i < output.length; i++){
    output[i] = Args.get(i).strip();
  }
  
  //printArray(output);
  return output;//Args.toArray();
}

void finalizeNewMacro(){
  println("Finalize Macro! " + _macro_Name);
  _Files[_Files_Macros].add(
    new FileHolder(
      new PathReturn(_macro_Name, _macro_Args, _PathReturn_Reverse_Macro),
      _macro_Content.toArray()
    )
  );
  _macro_Content.clear();
}

boolean checkMacros(String macro, String line, int index){
  //hm.get("");
  for(int i = 0; i < _Files[_Files_Macros].size(); i++){
    if(_Files[_Files_Macros].get(i).file.Name.equals(macro)){ // this is some hairy indirection...
      _Files_Type = _Files_Macros;
      //if(_tmpFileHolder.contents != null && checkFileName()){ // this might be causing issues...
        _Files[_Files_Inputs].add(new FileHolder(_tmpFileHolder));
      //}
      _tmpFileHolder = new FileHolder(_Files[_Files_Macros].get(i));
      setIndex(-1); // needs to be -1 due to a ++ at end of main loop
      pushMacroArgs(getMacroArgs(line, index, 0));
      return true;
    }
  }
  return false;
}

HashMap<String, FileHolder> macroMap = new HashMap<String, FileHolder>(); // do we instead use a hashmap for macros?
boolean checkMacrosHash(String macro, String line, int index){
  FileHolder tmp = macroMap.get(macro);
  if(tmp != null){
    _Files_Type = _Files_Macros;
    _Files[_Files_Inputs].add(new FileHolder(_tmpFileHolder));
    _tmpFileHolder = new FileHolder(tmp);
    setIndex(-1); // needs to be -1 due to a ++ at end of main loop
    pushMacroArgs(getMacroArgs(line, index, 0));
    return true;
  }
  return false;
}
