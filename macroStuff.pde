void buildMacro(String line_, int index){
  println("Start Macro!");
  TokenReturn token = getNextToken(line_, index);
  _macro_Name = token.string;
  _macro_Args = getMacroArgs(line_, token.nextIndex);
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

String[] getMacroArgs(String line, int index){
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
          
          case ' ': // each of these are tokens
            if(!inString){
              if(token.length() != 0){ Args.append(token); } // don't, split, on,[ ]after, comma
              token = "";
            }else{
              token += c;
            }
            break;
            
          
          case '\\':
            state = 2;
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
      
      case 2: // build value
        if(c == 'u'){
          state = 3;
        }else{
          switch(c){
            case '0': // NULL
              token += "\\u{00}";
              break;
            case 'a': // BELL
              token += "\\u{07}";
              break;
            case 'b': // BACKSPACE
              token += "\\u{08}";
              break;
            case 'e': // ESCAPE SEQUENCE
              token += "\\u{1B}";
              break;
            case 'f': // FORM FEED
              token += "\\u{0C}";
              break;
            case 'n': // NEWLINE
              token += "\\u{0A}";
              break;
            case 'r': // CARRIAGE RETURN
              token += "\\u{0D}";
              break;
            case 't': // TAB
              token += "\\u{09}";
              break;
            case 'v': // VERTICAL TAB
              token += "\\u{0B}";
              break;
            default:
              token += "\\u{" + hex(c) + "}";
              break;
          }
          state = 0;
        }
        break;
      
      case 3: // start unicode
        if(c == '{'){
          token += "\\u{";
          state = 4;
        }
        break;
      
      case 4: // build unicode
        token += c;
        if(c == '}'){
          state = 0;
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
      pushMacroArgs(getMacroArgs(line, index));
      return true;
    }
  }
  return false;
}
