enum VariableType{
  Integer,
  Float, // might need to be converted to hex format for some assemblers
  String,
  Char, // to be used for character arithmetic (sbc 'A' - '0')
  Variable,
}

class VariableReturn{
  VariableType Type;
  String String;
  int Integer;
  float Float;
  char Char;
  boolean Number;
  
  VariableReturn(String s){
    String = s;
    Type = VariableType.String;
  }
  
  VariableReturn(String s, int i){
    String = s;
    Integer = i;
    Number = true;
    Type = VariableType.Integer;
  }
  
  VariableReturn(String s, float f){
    String = s;
    Float = f;
    Number = true;
    Type = VariableType.Float;
  }
  
  String toString(){
    switch(Type){
      case Integer: return "" + Integer;
      case Float: return "" + Float;
      case String: return String;
      default: return "";
    }
  }
}

void parseLet(String line, int index){
  TokenReturn variable = getNextToken(line, index);
  TokenReturn action = getNextToken(line, variable.nextIndex);
  TokenReturn value = getNextToken(line, action.nextIndex);
  
  parseLet(variable.string, action.string, value);
}

void parseLet(String variable, String action, TokenReturn secondToken){
  VariableReturn firstVar = parseVariables(_Vars.hasKey(variable) ? _Vars.get(variable) : "0");
  VariableReturn secondVar = parseVariables(secondToken.string);
  //println("parseLet: [" + variable + "](" + firstVar + ") " + action + " [" + secondToken.string + "](" + secondVar + ")");
  
  if(firstVar.Number && secondVar.Number){
    switch(firstVar.Type){
      case Integer:
        switch(secondVar.Type){
          case Integer: _Vars.set(variable, "" + parseLet(firstVar.Integer, action, secondVar.Integer)); break;
          case Float: _Vars.set(variable, "" + parseLet(firstVar.Integer, action, secondVar.Float)); break;
          default: break;
        }
        break;
      case Float:
        switch(secondVar.Type){
          case Integer: _Vars.set(variable, "" + parseLet(firstVar.Float, action, secondVar.Integer)); break;
          case Float: _Vars.set(variable, "" + parseLet(firstVar.Float, action, secondVar.Float)); break;
          default: break;
        }
        break;
      default: break;
    }
  }else{
    switch(action){
      case "+":
        if(_Vars.hasKey(variable)){ _Vars.set(variable, _Vars.get(variable) + secondVar.String); }
        break;
      
      case "-":
        if(_Vars.hasKey(variable)){ _Vars.set(variable, _Vars.get(variable).replace(secondVar.String, "")); }
        break;
      
      case "=":
        _Vars.set(variable, secondVar.String);
        break;
    }
  }
}

// TODO: would it make more sense for parseLet to handle int/float stuff and return a VariableReturn?
int parseLet(int firstVar, String action, int secondVar){
  switch(action){
    case "+=":
      return firstVar + secondVar; // check if integers are equal
    
    case "-=":
      return firstVar - secondVar;
    
    case "*=":
      return firstVar * secondVar;
    
    case "/=":
      return firstVar / secondVar;
    
    case "%=":
      return firstVar % secondVar;
    
    case "&=":
      return firstVar & secondVar;
    
    case "|=":
      return firstVar | secondVar;
    
    case "^=":
      return firstVar ^ secondVar;
    
    default:
      return secondVar;
  }
}

float parseLet(float firstVar, String action, float secondVar){
  switch(action){
    case "+=":
      return firstVar + secondVar; // check if integers are equal
    
    case "-=":
      return firstVar - secondVar;
    
    case "*=":
      return firstVar * secondVar;
    
    case "/=":
      return firstVar / secondVar;
    
    case "%=":
      return firstVar % secondVar;
    
    default:
      return secondVar;
  }
}

String getVariable(String name, boolean global){
  //println("getVariable: " + name + ", " + global);
  if(global && _Vars != null && _Vars.hasKey(name)){
    return _Vars.get(name);
  }else if(!global){
    String[] lineMacroArgs = peekMacroArgs();
    FileHolder curMacro = getFile();
    //printArray(curMacro.file.PathArray);
    for(int a = 0; a < curMacro.file.PathArray.length; a++){
      String[] def = curMacro.file.PathArray[a].split("=");
      if(def[0].equals(name)){
        if(a >= lineMacroArgs.length || lineMacroArgs[a].length() == 0){ // ["this","is","a"], ["this","","","token"]
          return def[1];
        }else{
          return lineMacroArgs[a];
        }
      }
    }
  }
  
  return "%{" + name + "}?";
}

/*
  %identifier = macro argument
  %%id = global variable
  %?id = drop '?' and pass un-parsed "%id" onwards (allows deferring var parsing through several macros or assignments)
  %??id = drop one '?' and pass "%?id"
  %#id = drop leading "%#" and padd "id" (allows building macros with macros)
  %?#id = drop '?' and pass "%#id"
*/
VariableReturn parseVariables(String line){
  //println("parseVariables: " + line);
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
        //if(c == '%'){ } // built-in functions (strlen, eval, etc.) [%%%strlen(%name)]
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
  
  return new VariableReturn(value);
}
