boolean isAlpha(char c){
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

boolean isHex(char c){
  return (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

boolean isNumber(char c){
  return c >= '0' && c <= '9';
}

boolean isWhitespace(char c){
  return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

String cleanEscape(String line){
  String output = "";
  int state = 0;
  
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    
    switch(state){
      case 0: // build prefix
        if(c != '\\'){
          output += c;
        }else{
          state = 1;
        }
        break;
      
      case 1: // build value
        if(c == 'u'){
          state = 3;
        }else{
          switch(c){
            case '0': // NULL
              output += "\\u{00}";
              break;
            case 'a': // BELL
              output += "\\u{07}";
              break;
            case 'b': // BACKSPACE
              output += "\\u{08}";
              break;
            case 'e': // ESCAPE SEQUENCE
              output += "\\u{1B}";
              break;
            case 'f': // FORM FEED
              output += "\\u{0C}";
              break;
            case 'n': // NEWLINE
              output += "\\u{0A}";
              break;
            case 'r': // CARRIAGE RETURN
              output += "\\u{0D}";
              break;
            case 't': // TAB
              output += "\\u{09}";
              break;
            case 'v': // VERTICAL TAB
              output += "\\u{0B}";
              break;
            //case 'x': // HEX INPUT
            //  break;
            default:
              output += "\\u{" + hex(c) + "}";
              break;
          }
          state = 0;
        }
        break;
      
      case 3: // start unicode
        if(c == '{'){
          output += "\\u{";
          state = 4;
        }
        break;
      
      case 4: // build unicode
        output += c;
        if(c == '}'){
          state = 0;
        }
        break;
    }
  }
  
  return output;
}

boolean checkIf(String line, int index){
  TokenReturn firstVar = getNextToken(line, index);
  TokenReturn action = getNextToken(line, firstVar.nextIndex);
  TokenReturn secondVar = getNextToken(line, action.nextIndex);
  
  VariableReturn var1 = parseVariable(firstVar.string);
  VariableReturn var2 = parseVariable(secondVar.string);
  
  String v1 = getVariable(var1, null, null);
  String v2 = getVariable(var2, null, null);
  
  switch(action.string){
    case "==":
      return v1.equals(v2);
    case "!=":
      return !v1.equals(v2);
    case ">":
      return parseInt(v1) > parseInt(v2);
    case "<":
      return parseInt(v1) < parseInt(v2);
    case ">=":
      return parseInt(v1) >= parseInt(v2);
    case "<=":
      return parseInt(v1) <= parseInt(v2);
    default:
      return false;
  }
}
