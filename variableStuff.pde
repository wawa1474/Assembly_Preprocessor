class VariableReturn{
  String variable;
  TokenType type;
  
  VariableReturn(TokenType t, String v){
    variable = v;
    type = t;
  }
}

Token parseVariable(String line, TokenType variable){
  String prefix = "";
  String value = "";
  String suffix = "";
  int state = 0;
  
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    
    switch(state){
      case 0: // build prefix
        if(c != '%'){
          prefix += c;
        }else{
          state = 1;
        }
        break;
      
      case 1: // eat extra '%'
        if(c != '%'){
          value += c;
          state = 2;
        }
        break;
      
      case 2: // build value
        if(isAlpha(c) || isNumber(c) || c == '_'){
          value += c;
        }else{
          suffix += c;
          state = 3;
        }
        break;
      
      case 3: // build suffix
        suffix += c;
        break;
    }
  }
  
  //println(line + " =>= " + prefix + "%" + suffix + " : " + value);
  return new Token(variable, prefix + "%" + suffix, value);
}

Variable[] varListToArray(ArrayList<Variable> list){
  Variable[] out = new Variable[list.size()];
  
  for(int i = 0; i < out.length; i++){ // Token t : list
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
  TokenType type = TokenType.External;
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
          
          case '%': // how do we handle multiple vars/args in a token?
            vType = VarType.Macro_Arg;
            value += token;
            token = "";
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
            vType = VarType.Global_Var;
            break;
          
          default:
            token += c;
            state = 2;
        }
        break;
      
      case 2: // build value
        if(isAlpha(c) || isNumber(c) || c == '_'){
          token += c;
        }else{
          vars.add(new Variable(vType, token));
          value += "%" + vars.size();
          token = "" + c;
          state = 0;
        }
        break;
      
      case 20: // build value
        if(c == 'u'){
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
            //case 'x': // HEX INPUT
            //  break;
            default:
              token += "\\u{" + hex(c) + "}";
              break;
          }
          state = 0;
        }
        break;
      
      case 30: // start unicode
        if(c == '{'){
          token += "\\u{";
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
  
  return new Token2(type, value + token, varListToArray(vars), index);
}

VariableReturn parseVariable(String line){
  String value = "";
  boolean global = false;
  int state = 0;
  
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    
    switch(state){
      case 0: // build prefix
        if(c == '%'){
          state = 1;
        }
        break;
      
      case 1: // eat extra '%'
        if(c == '%'){
          global = true;
        }else{
          i--;
        }
        state = 2;
        break;
      
      case 2: // build value
        if(isAlpha(c) || isNumber(c) || c == '_'){
          value += c;
        }else{
          state = -1;
        }
        break;
    }
  }
  
  if(value.equals("")){
    return new VariableReturn(TokenType.External, line);
  }else{
    return new VariableReturn(global ? TokenType.Variable : TokenType.Argument, value);
  }
}

String getVariable(VariableReturn variable_, Macro macro_, String[] macroArgs_){
  switch(variable_.type){
    case External:
      return variable_.variable;
    case Variable:
      return _Vars.get(variable_.variable);
    case Argument:
      if(macro_ != null){
        for(int a = 0; a < macro_.Arguments.length; a++){
          if(macro_.Arguments[a].name.equals(variable_.variable)){
            if(a >= macroArgs_.length){
              return macro_.Arguments[a].defualt;
            }else{
              return variable_.variable.replace("%", macroArgs_[a]);
            }
          }
        }
      }
      return "";
    default:
      return "";
  }
}
