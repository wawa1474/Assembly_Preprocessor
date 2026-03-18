class VariableReturn{
  String String;
  int Integer;
  boolean Number;
  
  VariableReturn(String s, int i, boolean b){
    String = s;
    Integer = i;
    Number = b;
  }
}

void parseLet(String line, int index){
  TokenReturn variable = getNextToken(line, index);
  TokenReturn value = getNextToken(line, variable.nextIndex);
  
  _Vars.set(variable.string, parseVariables(value.string).String);
}

String getVariable(String name, boolean global){
  if(global){
    return _Vars.get(name);
  }else{
    String[] lineMacroArgs = peekMacroArgs();
    FileHolder curMacro = getFile();
    for(int a = 0; a < curMacro.file.PathArray.length; a++){
      String[] def = curMacro.file.PathArray[a].split("=");
      if(def[0].equals(name)){
        if(a >= lineMacroArgs.length){
          return def[1];
        }else{
          return lineMacroArgs[a];
        }
      }
    }
  }
  
  return "%{" + name + "}?";
}

VariableReturn parseVariables(String line){
  String value = "";
  String token = "";
  int state = 0;
  boolean isGlobalVar = false;
  
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    
    switch(state){
      case 0: // build prefix
        switch(c){
          case '"':
            token += c;
            break;
          
          case '%':
            isGlobalVar = false;
            value += token;
            token = "";
            state = 1;
            break;
          
          case '\\':
            state = 20;
            break;
          
          default:
            token += c;
            break;
        }
        break;
      
      case 1: // eat extra '%'
        switch(c){
          case '%':
            isGlobalVar = true;
            break;
          
          default:
            token += c;
            state = 2;
            break;
        }
        break;
      
      case 2: // build value
        if(isAlpha(c) || isNumber(c) || c == '_'){
          token += c;
        }else{
          value += getVariable(token, isGlobalVar);
          i--;
          token = "";
          state = 0;
        }
        break;
      
      case 20: // build value
        if(c == 'u'){
          token += "\\" + c;
          state = 30;
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
      
      case 30: // start unicode
        if(c == '{'){
          token += c;
          state = 40;
        }
        break;
      
      case 40: // build unicode
        token += c;
        if(c == '}'){
          state = 0;
        }
        break;
    }
  }
  
  if(state == 2){
    value += getVariable(token, isGlobalVar);
    token = "";
  }
  
  value += token;
  
  if(value.length() > 0){
    VariableReturn tmp = tryInt(value);
    if(tmp.Number){ return tmp; }
  }
  
  return new VariableReturn(value, 0, false);
}
