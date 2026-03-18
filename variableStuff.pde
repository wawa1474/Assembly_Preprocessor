void parseLet(String line, int index){
  TokenReturn variable = getNextToken(line, index);
  TokenReturn value = getNextToken(line, variable.nextIndex);
  //println("parseLet: " + variable.string + " -> " + value.string);
  
  _Vars.set(variable.string, parseVariables(value.string));
}

Variable[] varListToArray(ArrayList<Variable> list){
  Variable[] out = new Variable[list.size()];
  
  for(int i = 0; i < out.length; i++){
    out[i] = list.get(i);
  }
  
  return out;
}

Token2 getNextVariable(String line, int index){
  String value = "";
  String token = "";
  int state = 0;
  boolean inString = false;
  boolean gotString = false;
  ArrayList<Variable> vars = new ArrayList<Variable>();
  VarType vType = VarType.Null;
  
  for(; index < line.length() && state != -1; index++){
    char c = line.charAt(index);
    
    switch(state){
      case 0: // build prefix
        switch(c){
          case '"':
            token += c;
            inString = !inString;
            gotString = true;
            break;
          
          case '%':
            vType = VarType.Macro_Arg;
            value += token;
            token = "";
            gotString = true;
            state = 1;
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
          
          case '\\':
            gotString = true;
            state = 20;
            break;
          
          default:
            token += c;
            gotString = true;
            break;
        }
        break;
      
      case 1: // eat extra '%'
        switch(c){
          case '%':
            vType = VarType.Global_Var;
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
          vars.add(new Variable(vType, token));
          value += "\\%{" + (vars.size()-1) + "}";
          index--;
          token = "";
          state = 0;
        }
        break;
      
      case 20: // build value
        if(c == 'u' || c == '%'){
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
    vars.add(new Variable(vType, token));
    value += "\\%{" + (vars.size()-1) + "}";
    token = "";
  }
  
  value += token;
  
  TokenType type = TokenType.External;
  int integer = 0;
  switch(value){
    case ".include":
      type = TokenType.Include;
      break;
    case "#include":
      type = TokenType.Include;
      break;
    case ".if":
      type = TokenType.If;
      break;
    case ".elseif":
      type = TokenType.ElseIf;
      break;
    case ".else":
      type = TokenType.Else;
      break;
    case ".endif":
      type = TokenType.EndIf;
      break;
    case ".macro":
      type = TokenType.Macro;
      break;
    case ".endm":
      type = TokenType.EndMacro;
      break;
    case ".let":
      type = TokenType.Let;
      break;
    case ";":
      type = TokenType.Comment;
      break;
    default:
      if(value.length() > 0){
        IntReturn tmp = tryInt(value);
        if(tmp.valid){
          type = TokenType.Number;
          value = "" + tmp.value;
          integer = tmp.value;
        }
      }
      break;
  }
  
  return new Token2(type, value, integer, varListToArray(vars), index);
}

String getVariable(Token2 variable_){
  String output = variable_.Identifier;
  if(variable_.Variables == null || variable_.Variables.length == 0){ return output; }
  
  for(int i = 0; i < variable_.Variables.length; i++){
    Variable v = variable_.Variables[i];
    switch(v.type){
      case Macro_Arg:
        String[] lineMacroArgs = peekMacroArgs();
        FileHolder curMacro = getFile();
        for(int a = 0; a < curMacro.file.PathArray.length; a++){
          if(curMacro.file.PathArray[a].equals(v.value)){
            if(a >= lineMacroArgs.length){
              output = output.replace("\\%{" + i + "}", curMacro.file.PathArray[a].split("=")[1]);
            }else{
              output = output.replace("\\%{" + i + "}", curMacro.file.PathArray[a]);
            }
          }
        }
        break;
      
      case Global_Var:
        output = output.replace("\\%{" + i + "}", _Vars.get(v.value));
        break;
      
      default:
        break;
    }
  }
  
  return output;
}

String getVariable(String name, boolean global){
  if(global){
    return _Vars.get(name);
  }else{
    String[] lineMacroArgs = peekMacroArgs();
    FileHolder curMacro = getFile();
    //println("getVariable: " + name);
    //printArray(curMacro.file.PathArray);
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

Token2 parseVariables(String line, int index){
  String value = "";
  String token = "";
  int state = 0;
  boolean inString = false;
  boolean gotString = false;
  boolean globalVar = false;
  
  for(; index < line.length() && state != -1; index++){
    char c = line.charAt(index);
    
    switch(state){
      case 0: // build prefix
        switch(c){
          case '"':
            token += c;
            inString = !inString;
            gotString = true;
            break;
          
          case '%':
            globalVar = false;
            value += token;
            token = "";
            gotString = true;
            state = 1;
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
          
          case '\\':
            gotString = true;
            state = 20;
            break;
          
          default:
            token += c;
            gotString = true;
            break;
        }
        break;
      
      case 1: // eat extra '%'
        switch(c){
          case '%':
            globalVar = true;
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
          value += getVariable(token, globalVar);
          index--;
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
    value += getVariable(token, globalVar);
    token = "";
  }
  
  value += token;
  
  TokenType type = TokenType.External;
  
  int integer = 0;
  if(value.length() > 0){
    IntReturn tmp = tryInt(value);
    if(tmp.valid){
      type = TokenType.Number;
      value = "" + tmp.value;
      integer = tmp.value;
    }
  }
  
  return new Token2(type, value, integer, null, index);
}

String parseVariables(String line){
  String value = "";
  String token = "";
  int state = 0;
  boolean globalVar = false;
  
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    
    switch(state){
      case 0: // build prefix
        switch(c){
          case '"':
            token += c;
            break;
          
          case '%':
            globalVar = false;
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
            globalVar = true;
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
          String tmp = getVariable(token, globalVar);
          //println("found {" + token + "} = {" + tmp + "}");
          value += tmp;
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
    value += getVariable(token, globalVar);
    token = "";
  }
  
  value += token;
  
  //if(line.contains(",")){ println("[" + getIndex() + "] " + "parseVariables: " + line); }
  
  if(value.length() > 0){
    IntReturn tmp = tryInt(value);
    if(tmp.valid){
      value = "" + tmp.value;
    }
  }
  
  return value;
}
