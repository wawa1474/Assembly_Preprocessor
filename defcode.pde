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
