class TokenReturn{
  String string;
  int nextIndex;
  
  TokenReturn(int n){
    nextIndex = n;
  }
  
  TokenReturn(String t, int n){
    string = t;
    nextIndex = n;
  }
}

TokenReturn getNextToken(String line, int index){
  String token = "";
  int state = 0;
  boolean inString = false;
  boolean gotString = false;
  
  for(; index < line.length() && state != -1; index++){
    char c = line.charAt(index);
    switch(state){
      case 0:
        switch(c){
          case '"':
            token += c;
            inString = !inString;
            gotString = true;
            break;
          
          case '\\':
            gotString = true;
            state = 2;
            break;
          
          case ' ':
          case '\t':
            if(inString){
              token += c;
              gotString = true;
            }else{
              state = gotString ? -1 : 0;
            }
            break;
          
          default:
            token += c;
            gotString = true;
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
  
  if(line.length() == 1 && token.equals("")){
    token = line;
    index++;
  }
  
  return new TokenReturn(token, index);
}
