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
