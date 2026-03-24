String stripStr(String input){
  input = input.startsWith("\"") ? input.substring(1) : input; // strip leading and trailing "
  return input.endsWith("\"") ? input.substring(0, input.length()-1) : input;
}

String[] splitVersion(String input){
  input = input.toLowerCase();
  input = input.startsWith("v") ? input.substring(1) : input; // strip leading 'V'
  
  String[] tmp = split(input, "."); // 2.2.0-pr.1 -> [2, 2, 0-pr, 1]
  
  if(tmp.length > 3){
    tmp[2] = split(tmp[2], "-")[0]; // 0-pr -> 0
  }
  
  return tmp;
}

String compareVersions(String version, String action, String first, String second){
  if(hyperVerboseOutput){ println("compareVersions: " + version + " " + action + " " + first + " " + second); }println("compareVersions: " + version + " " + action + " " + first + " " + second);
  action = stripStr(action);
  first = stripStr(first);
  boolean cond = false;
  boolean funcSet = false;
  String[] v1 = splitVersion(first);
  
  String[] verArr = splitVersion(version);
  int checkLength = verArr.length;
  for(int i = 0; i < verArr.length; i++){
    if(verArr[i] == null){
      checkLength = i;
      break;
    }
  }
  checkLength = min(checkLength, v1.length);
  
  boolean equ = true;
  for(int i = 0; i < checkLength; i++){
    equ &= v1[i].equals(verArr[i]); // _version == v1
  }
  
  switch(action){
    case "!=": // not same
      cond = !equ;
      break;
    
    case "==": // same
      cond = equ;
      break;
    
    case ">=": // greater than or equal
      action = ">";
      funcSet = true;
    case "<=": // less than or equal
      if(equ == true){ cond = true; break; }
      if(funcSet == false){ action = "<"; }
    case ">": // greater than
    case "<": // less than
      //println("checkVer: " + _VERSION + " " + args[1].Name + " " + args[2].Name);
      for(int i = 0; i < checkLength; i++){
        if(checkCondition(parseVariables(verArr[i]), action, parseVariables(v1[i]), null, false)){
          cond = true;
          break; // break out of loop
        }
        //println(_version[i] + " " + args[1].Name + " " + v1[i] + " = " + cond + " / " + equ);
      }
      break;
    
    case "<!=>": // not between or equal
    case "<=>": // between or equal
    case "<!>": // not between
    case "<>": // between
      if(second == null){ return "\\!{check/compareVer: not enough args " + (args.length-1) + " is < 3/4}"; }
      second = stripStr(second);
      String[] v2 = splitVersion(stripStr(second));
      checkLength = min(checkLength, v2.length);
      
      boolean[] equEach = new boolean[checkLength];
      boolean eq2 = true;
      for(int i = 0; i < checkLength; i++){
        equEach[i] = v1[i].equals(verArr[i]) | v2[i].equals(verArr[i]);
        eq2 &= equEach[i];
      }
      
      switch(action){ // ugly hack, but it works...
        case "<!=>": // not between or equal
          if(equ == true || eq2 == true){ cond = false; break; }
          action = "<!>";
          funcSet = true;
        case "<=>": // between or equal
          if(funcSet == false){
            if(equ == true || eq2 == true){ cond = true; break; }
            action = "<>";
          }
        case "<!>": // not between
        case "<>": // between
          //println("checkVer: " + _VERSION + " " + args[1].Name + " " + args[2].Name + ", " + args[3].Name);
          for(int i = 0; i < checkLength; i++){
            if(equEach[i] == false && checkCondition(parseVariables(verArr[i]), action, parseVariables(v1[i]), parseVariables(v2[i]), false)){
              cond = true;
              break; // break out of loop
            }
          }
          break;
      }
      break;
  }
  
  return str(cond);
}

String getLabelUUID(){
  return UUID.randomUUID().toString().replace('-', '_');
}

boolean isAlpha(char c){
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

boolean isHex(char c){
  return (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

boolean isBinary(char c){
  return (c == '0' || c == '1' || c == '|');
}

boolean isOctal(char c){
  return c >= '0' && c <= '7';
}

boolean isNumber(char c){
  return c >= '0' && c <= '9';
}

boolean isWhitespace(char c){
  return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

String octalToHex(String input_){
  if(input_ == null){ return null; }
  int value = 0;
  for(int i = 0; i < input_.length(); i++){
    value <<= 3;
    value |= input_.charAt(i) - 0x30;
  }
  return hex(value,4);
}

void outputLine(String line, boolean skip){
  if(hyperVerboseOutput){ println("outputLine: \"" + line + "\" = " + !skip); }
  boolean empty = isLineEmpty(line);
  if(empty && !isLineEmpty(getLastOutputLine())){ _output.append(""); return; } // the current line is blank, but the last output one wasn't...
  if(!skip && !empty){
    String tmp = cleanComments(parseVariables(line).String);
    if(tmp != null && tmp.length() > 0){
      if(showLines){ tmp += "\t\t\t\t; " + CurrentWorker.getOrigin() + getFileName() + " @ " + getIndex(); }
      _output.append(tmp);
    }
  }
}

boolean isLineEmpty(String line){
  if(line == null){ return true; }
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    if(!isWhitespace(c)){ return false; }
  }
  return true;
  //return line.strip().length() == 0; // cleaner, but also slower?
}

String cleanComments(String line){
  if(maintainComments){ return line; }
  String output = "";
  int state = 0;
  boolean inString = false;
  
  for(int i = 0; i < line.length() && state != -1; i++){
    char c = line.charAt(i);
    
    switch(c){
      case '"':
        output += c;
        inString = !inString;
        break;
      
      case ';':
        if(inString){
          output += c;
        }else{
          state = -1;
        }
        break;
      
      default:
        output += c;
        break;
    }
  }
  
  return output;
}

void cleanMultilineComments(){
  int depth = 0;
  for(; getIndex() < getFileLength(); incIndex()){
    String line = getLine();
    if(maintainComments){ _output.append("; " + line); }
    TokenReturn token = getNextToken(line, 0);
    switch(token.string){
      case "/*":
        depth++; // handle nested multiline comments
        continue;
      
      case "*/":
        depth--;
        if(depth <= 0){
          //if(token.nextIndex < line.length()){ // this won't work due to processInput() always starting at beginning of line...
            //decIndex(); // need to --lineIndex due to being ++ on next iteration of processInput()
          //} // as such, code can't follow the "*/" of a multiline comment...
          return; // end of (nested) multiline comments
        }
        continue; // end of current nested multiline comment
    }
    
    //println(line + ":" + depth);
    while(token.nextIndex < line.length()){ // handle multiline comments that exist on a single line
      switch(token.string){
        case "/*":
          depth++; // handle nested multiline comments
          break;
        
        case "*/":
          depth--;
          if(depth <= 0){
            //if(token.nextIndex < line.length()){ // this won't work due to processInput() always starting at beginning of line...
              //decIndex(); // need to --lineIndex due to being ++ on next iteration of processInput()
            //} // as such, code can't follow the "*/" of a multiline comment...
            return; // end of (nested) multiline comments
          }
          break; // end of current nested multiline comment
      }
      token = getNextToken(line, token.nextIndex); // get next token on same line
    }
  }
}

VariableReturn tryInt(String in){
  String output = "";
  int state = 0;
  boolean valid = true;
  boolean isFloat = false;
  
  char c = ' ';
  for(int i = 0; i < in.length(); i++){
    c = in.charAt(i);
    switch(state){
      case 0:
        switch(c){
          case '0':
            state = 1;
            break;
          
          case ' ':
          case '\t':
            break;
          
          default:
            output += c;
            state = 5;
            break;
        }
        break;
      
      case 1:
        switch(c){
          case 'x': // hexadecimal
            state = 2;
            break;
          
          case 'b': // binary
            state = 3;
            break;
          
          case 'o': // octal
            state = 4;
            break;
          
          case '.': // 0.float
            output += "0.";
            isFloat = true;
            state = 5;
            break;
          
          default: // decimal
            state = 5;
            break;
        }
        break;
      
      case 2: // hexadecimal
        if(isHex(c)){
          output += c;
        }else{
          valid = false;
          state = -1;
        }
        break;
      
      case 3: // binary
        if(isBinary(c)){
          output += c;
        }else{
          valid = false;
          state = -1;
        }
        break;
      
      case 4: // octal
        if(isOctal(c)){
          output += c;
        }else{
          valid = false;
          state = -1;
        }
        break;
      
      case 5: // decimal
        if(isNumber(c)){
          output += c;
        }else if(c == '.'){
          output += c;
          isFloat = true;
        }else{
          valid = false;
          state = -1;
        }
        break;
    }
  }
  
  switch(state){
    case 1: // just '0' as input!
      output = "0";
      state = 5;
      break;
    case 5:
      if(!isNumber(c)){
        valid = false;
      }
      break;
  }
  
  int value = 0;
  float flo = 0;
  if(valid){
    switch(state){
      case 2: // hexadecimal
        if(isFloat){ flo = parseFloat(output, 16); }
        else{ value = parseInt(output, 16); }
        break;
      
      case 3: // binary
        if(isFloat){ flo = parseFloat(output, 2); }
        else{ value = parseInt(output, 2); }
        break;
      
      case 4: // octal
        if(isFloat){ flo = parseFloat(output, 8); }
        else{ value = parseInt(output, 8); }
        break;
      
      case 5: // decimal
        if(isFloat){ flo = parseFloat(output, 10); }
        else{ value = parseInt(output, 10); }
        
        break;
      
      default: // if a line is just spaces or tabs...
        valid = false;
        break;
    }
  }
  
  if(valid){
    if(isFloat){ return new VariableReturn(in, flo); }
    else{ return new VariableReturn(in, value); }
  }
  else{ return new VariableReturn(in); }
}
