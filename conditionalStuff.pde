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
    return checkCondition(firstVar, action, secondVar, default_);
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

boolean checkCondition(VariableReturn firstVar, String action, VariableReturn secondVar, boolean default_){
  float comp = compare(firstVar, secondVar);
  switch(action){
    case "==":
      return comp == 0;
    
    case "!=":
      return comp != 0;
    
    case ">":
      return comp > 0;
    
    case "<":
      return comp < 0;
    
    case ">=":
      return comp >= 0;
    
    case "<=":
      return comp <= 0;
    
    default:
      return default_;
  }
}

// TODO: this might have issues due to float rounding...
float compare(VariableReturn one, VariableReturn two){ // -(one < two), 0(one == two), +(one > two)
  return (one.Type == VariableType.Integer ? one.Integer : one.Float) - (two.Type == VariableType.Integer ? two.Integer : two.Float);
}

boolean checkCase(String line, int index){
  //VariableReturn switchValue = parseVariables(peekMacroArgs()[0]);
  int state = 0;
  StringList output = new StringList();
  
  TokenReturn token = getNextToken(line, index);
  for(; index < line.length() && state != -1; index++){
    switch(state){
      case 0:
        switch(token.string){
          case "[": // start of value list
            state = 1;
            break;
          default: // must be a single value
            if(CurrentMacroArgs != null){ return checkIf(new TokenReturn(CurrentMacroArgs[0].Name, 0), "==", token, false); }
            else{ return false; }
        }
        break;
      
      case 1:
        switch(token.string){
          case "]": state = -1; break; // end of value list
          case "..": state = 2; break; // denotes value range
          case ",": break; // eat value seperator
          default: output.append(token.string); break; // must be a value
        }
        break;
      
      case 2: // denotes value range {Ruby range syntax} ([1..4] == [1,2,3,4])([1,2,10..13] == [1,2,10,11,12,13])([1..4,10..8] == [1,2,3,4,10,9,8])
        if(output.size() > 0){
          for(int i = int(output.get(output.size()-1)) + 1; i <= int(token.string); i++){ output.append(str(i)); }
        }else{
          for(int i = 0; i <= int(token.string); i++){ output.append(str(i)); }
        }
        state = 1;
        break;
    }
  }
  
  return false;
}
