boolean checkIf(String line, int index, boolean default_){
  TokenReturn firstToken = getNextToken(line, index);
  TokenReturn action = getNextToken(line, firstToken.nextIndex);
  TokenReturn secondToken = getNextToken(line, action.nextIndex);
  return checkIf(firstToken, action.string, secondToken, default_);
}

boolean checkIf(TokenReturn firstToken, String action, TokenReturn secondToken, boolean default_){
  VariableReturn firstVar = parseVariables(firstToken.string);
  VariableReturn secondVar = parseVariables(secondToken.string);
  //println("checkIf: [" + firstToken.string + "](" + firstVar + ") " + action + " [" + secondToken.string + "](" + secondVar + ")");
  if(firstToken.string.equals("") || action.equals("") || secondToken.string.equals("")){ return default_; }
  
  if(firstVar.Number && secondVar.Number){
    switch(firstVar.Type){
      case Integer:
        switch(secondVar.Type){
          case Integer: return checkCondition(firstVar.Integer, action, secondVar.Integer, default_);
          case Float: return checkCondition(firstVar.Integer, action, secondVar.Float, default_);
          default: break;
        }
        break;
      case Float:
        switch(secondVar.Type){
          case Integer: return checkCondition(firstVar.Float, action, secondVar.Integer, default_);
          case Float: return checkCondition(firstVar.Float, action, secondVar.Float, default_);
          default: break;
        }
        break;
      default: break;
    }
    return default_;
  }else{
    switch(action){
      case "==":
        return firstVar.String.equals(secondVar.String); // check if strings are equal
      
      case "!=":
        return !firstVar.String.equals(secondVar.String);
      
      case "": // check if var is defined
        return _Vars.hasKey(firstToken.string.replace("%%",""));
      
      default:
        return default_;
    }
  }
}

boolean checkCondition(int firstVar, String action, int secondVar, boolean default_){
  switch(action){
    case "==":
      return firstVar == secondVar; // check if integers are equal
    
    case "!=":
      return firstVar != secondVar;
    
    case ">":
      return firstVar > secondVar;
    
    case "<":
      return firstVar < secondVar;
    
    case ">=":
      return firstVar >= secondVar;
    
    case "<=":
      return firstVar <= secondVar;
    
    default:
      return default_;
  }
}

boolean checkCondition(float firstVar, String action, float secondVar, boolean default_){
  switch(action){
    case "==":
      return firstVar == secondVar; // check if integers are equal
    
    case "!=":
      return firstVar != secondVar;
    
    case ">":
      return firstVar > secondVar;
    
    case "<":
      return firstVar < secondVar;
    
    case ">=":
      return firstVar >= secondVar;
    
    case "<=":
      return firstVar <= secondVar;
    
    default:
      return default_;
  }
}

boolean checkCase(String line, int index){
  //VariableReturn switchValue = parseVariables(peekMacroArgs()[0]);
  int state = 0;
  
  TokenReturn token = getNextToken(line, index);
  for(; index < line.length() && state != -1; index++){
    switch(state){
      case 0:
        switch(token.string){
          case "[": // start of value list
          case "]": // end of value list
          case "..": // denotes value range {Ruby range syntax} ([1..4] == [1,2,3,4])([1,2,10..13] == [1,2,10,11,12,13])([1..4,10..8] == [1,2,3,4,10,9,8])
          default: // must be a single value
            return checkIf(new TokenReturn(peekMacroArgs()[0], 0), "==", token, false);
        }
    }
  }
  
  return false;
}
