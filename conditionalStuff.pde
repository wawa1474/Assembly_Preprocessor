boolean checkIf(String line, int index, boolean default_){
  TokenReturn firstToken = getNextToken(line, index);
  TokenReturn action = getNextToken(line, firstToken.nextIndex);
  TokenReturn secondToken = getNextToken(line, action.nextIndex);
  TokenReturn thirdToken = getNextToken(line, secondToken.nextIndex);
  return checkIf(firstToken, action.string, secondToken, thirdToken, default_);
}

boolean checkIf(TokenReturn firstToken, String action, TokenReturn secondToken, TokenReturn thirdToken, boolean default_){
  VariableReturn firstVar = parseVariables(firstToken.string);
  VariableReturn secondVar = parseVariables(secondToken.string);
  //println("checkIf: [" + firstToken.string + "](" + firstVar + ") " + action + " [" + secondToken.string + "](" + secondVar + ")");
  if(firstToken.string.equals("") || action.equals("") || secondToken.string.equals("")){ return default_; }
  
  if(firstVar.Number && secondVar.Number){
    VariableReturn thirdVar = thirdToken == null ? null : parseVariables(thirdToken.string);
    return checkCondition(firstVar, action, secondVar, thirdVar, default_);
  }else{
    switch(action){
      case "==":
        return firstVar.String.equals(secondVar.String); // check if strings are equal
      
      case "!=":
        return !firstVar.String.equals(secondVar.String);
      
      case "": // check if var is defined
        return _Vars.hasKey(firstToken.string);
      
      default:
        return default_;
    }
  }
}

boolean checkCondition(VariableReturn firstVar, String action, VariableReturn secondVar, VariableReturn thirdVar, boolean default_){
  int comp = compare(firstVar, secondVar);
  boolean invert = false;
  switch(action){
    case "==": // same
      return comp == 0;
    
    case "!=": // not same
      return comp != 0;
    
    case ">": // greater than
      return comp > 0;
    
    case "<": // less than
      return comp < 0;
    
    case ">=": // greater than or equal
      return comp >= 0;
    
    case "<=": // less than or equal
      return comp <= 0;
    
    case "<!>": // not between
      invert = true;
    case "<>": // between
      if(thirdVar.Number != true){
        return default_; // NAN
      }else{
        int comp2 = compare(firstVar, thirdVar);
        //println(secondVar + " < " + firstVar + " = " + comp + ", " + firstVar + " < " + thirdVar + " = " + comp2 + ": = " + ((comp > 0 && comp2 < 0) ^ invert));
        return (comp > 0 && comp2 < 0) ^ invert; // v2 < v1 < v3
      }
    
    case "<!=>": // not between or equal
      invert = true;
    case "<=>": // between or equal
      if(thirdVar.Number != true){
        return default_; // NAN
      }else{
        int comp2 = compare(firstVar, thirdVar);
        return ((comp > 0 && comp2 < 0) || comp == 0 || comp2 == 0) ^ invert; // v2 <= v1 <= v3
      }
    
    default:
      return default_;
  }
}

// TODO: this might have issues due to float rounding...
int compare(VariableReturn one, VariableReturn two){ // -(one < two), 0(one == two), +(one > two)
  switch(one.Type){
    case Integer:
      switch(two.Type){
        case Integer: return Integer.compare(one.Integer, two.Integer); // Integer.compare should be more... reliable?
        case Float: return Float.compare(one.Integer, two.Float); // Float.compare should be more... reliable?
        default: println("compare:v2 was NAN"); return 0;
      }
    
    case Float:
      switch(two.Type){
        case Integer: return Float.compare(one.Float, two.Float);
        case Float: return Float.compare(one.Float, two.Float);
        default: println("compare:v2 was NAN"); return 0;
      }
    
    default: println("compare:v1 was NAN");return 0;
  }
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
            if(CurrentMacroArgs != null){ return checkIf(new TokenReturn(CurrentMacroArgs[0].Name, 0), "==", token, null, false); }
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
