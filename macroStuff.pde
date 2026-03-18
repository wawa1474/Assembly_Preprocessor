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
  for(int i = 0; i < _Files[_Files_Macros].size(); i++){
    if(_Files[_Files_Macros].get(i).file.Name.equals(macro)){ // this is some hairy indirection...
      _Files_Type = _Files_Macros;
      if(_tmpFileHolder.contents != null && checkFileName()){
        _Files[_Files_Inputs].add(new FileHolder(_tmpFileHolder));
      }
      _tmpFileHolder = new FileHolder(_Files[_Files_Macros].get(i));
      setIndex(-1); // needs to be -1 due to a ++ at end of main loop
      pushMacroArgs(getMacroArgs(line, index, 0));
      return true;
    }
  }
  return false;
}
