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
  
  String toString(){
    return "[" + nextIndex + "]{" + string + "}";
  }
}

TokenReturn getNextToken(String line, int index){
  String token = "";
  int state = 0;
  boolean inString = false;
  boolean gotString = false;
  int parenDepth = 0;
  
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
            TokenReturn output = cleanEscape(line, index);
            index = output.nextIndex;
            token += output.string;
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
          
          case '(': // do we handle things within paren's as a 'discreet' unit? escaped open-paren are handled by cleanEscape() obviously...
            // we would still need to check for escaped objects and handle them, but no other processing would occur on stuff within paren's...
            parenDepth++; // we would need to correctly handle nested paren's too...
            //token += c;
            gotString = true;
            //state = 1;
            //break;
          
          case ')': // perhaps we should also be handling unbalanced paren's too?
            parenDepth--;
            if(parenDepth == 0){
              //state = 0; // what else do we have to handle here?
            }
            break;
          
          default:
            token += c;
            gotString = true;
            break;
        }
        break;
      
      case 1:
        switch(c){
          case '(': // do we handle things within paren's as a 'discreet' unit?
            // we would still need to check for escaped objects and handle them, but no other processing would occur on stuff within paren's...
            parenDepth++; // we would need to correctly handle nested paren's too...
            break;
          
          case '\\': // escaped open-paren are still handled by cleanEscape() obviously...
            gotString = true;
            TokenReturn output = cleanEscape(line, index);
            index = output.nextIndex;
            token += output.string;
            break;
          
          case ')':
            parenDepth--;
            if(parenDepth == 0){
              state = 0; // what else do we have to handle here?
            }
            break;
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

TokenReturn cleanEscape(String line, int index){
  //println("[" + line + "]{" + index + "}");
  if(line.length() > 0 && index < line.length() && line.charAt(index) == '\\'){ index++; } // eat the incoming '\\'
  
  String token = "";
  int state = 0;
  VariableType type = VariableType.String;
  boolean outputEscape = true;
  
  for(; index < line.length() && state != -1; index++){
    char c = line.charAt(index);
    //print(c);
    switch(state){
      case 0:
        state = -1; // default is to finish after one character
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
          case 'u': // unicode
            token += "\\u";
            state = 1;
            break;
          case 'v': // VERTICAL TAB
            token += "\\u{0B}";
            break;
          case '!': // error output
            token += "\\!";
            type = VariableType.Error;
            state = 1;
            break;
          case '#': // built-in function
            outputEscape = false;
            type = VariableType.Function;
            state = 1;
            break;
          case '%': // macro arg
            outputEscape = false;
            type = VariableType.Argument;
            state = 1;
            break;
          case '&': // global var
            outputEscape = false;
            type = VariableType.Variable;
            state = 1;
            break;
          case '$': // built-in var
            outputEscape = false;
            type = VariableType.Builtin;
            state = 1;
            break;
          case '(': // escaped open-paren means we need to do infixToRPN stuff
            //token += lineToRPN(line, index);
            break;
          default:
            token += "\\u{" + hex(c) + "}";
            break;
        }
        break;
      
      case 1: // start unicode
        if(c == '{'){
          if(outputEscape){ token += c; }
          state = 2;
        }
        break;
      
      case 2: // build unicode
        switch(c){
          case '}':
            if(outputEscape){ token += c; }
            state = -1;
            break;
          
          case '\\':
            TokenReturn output = cleanEscape(line, index);
            index = output.nextIndex;
            token += output.string;
            break;
          
          default:
            token += c;
            break;
        }
        break;
    }
  }
  
  switch(type){
    case Argument: // macro argument
      //println("cleanEscape:Argument " + token);
      token = getVariable(token, false);
      break;
    case Variable: // global variable
      token = getVariable(token, true);
      break;
    case Function: // built-in function
      token = parseFunction(token);
      break;
    case Builtin: // built-in variable
      token = getBuiltin(token);
      break;
    default:
      // token = token;
      break;
  }
  
  //VariableReturn out = new VariableReturn(token, index-1, type);
  //println(out.type() + ":" + out + ";" + token);
  return new TokenReturn(token, index-1); // token-1 due to increment after use!
}
