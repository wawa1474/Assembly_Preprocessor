void buildMacro(String line_, int index){
  println("Start Macro!");
  TokenReturn token = getNextToken(line_, index);
  _macro_Name = token.string;
  _macro_Args = getMacroArgs(line_, token.nextIndex);
  int state = 0;
  incIndex(); // skip .macro line
  
  for(; getIndex() < getLineLength() && state != -1; incIndex()){
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

String[] getMacroArgs(String line, int index){
  StringList Args = new StringList();
  TokenReturn token = new TokenReturn(index);
  int state = 0;
  
  for(; token.nextIndex < line.length() && state != -1;){
    token = getNextToken(line, token.nextIndex);
    if(token.string.equals(";")){
      state = -1;
    }else{
      Args.append(
        token.string.lastIndexOf(',') == token.string.length() - 1 // "arg," -> "arg"
          ? token.string.replace(",", "")
          : token.string
      );
    }
  }
  
  return Args.toArray();
}

void pushMacroArgs(String[] args){
  _macro_Args2.add(args);
}

String[] popMacroArgs(){
  return _macro_Args2.remove(_macro_Args2.size()-1);
}

String[] peekMacroArgs(){
  return _macro_Args2.get(_macro_Args2.size()-1);
}

void finalizeNewMacro(){
  println("Finalize Macro! " + _macro_Name);
  _Files[_Files_Macros].add(
    new FileHolder(
      new PathReturn(_macro_Name, _macro_Args),
      _macro_Content.toArray()
    )
  );
  _macro_Content.clear();
}

boolean checkMacros(String macro, String line, int index){
  for(int i = 0; i < _Files[_Files_Macros].size(); i++){
    if(_Files[_Files_Macros].get(i).file.Name.equals(macro)){ // this is some hairy indirection...
      _Files_Type = _Files_Macros;
      //_output.append("; " + line);
      //println("push file for macro: " + line + " on line: " + getIndex());
      if(_tmpFileHolder.contents != null && checkFileName()){
        _Files[_Files_Inputs].add(new FileHolder(_tmpFileHolder));
      }
      _tmpFileHolder = new FileHolder(_Files[_Files_Macros].get(i));
      setIndex(-1); // needs to be -1 due to a ++ at end of main loop
      pushMacroArgs(getMacroArgs(line, index));
      return true;
    }
  }
  return false;
}
