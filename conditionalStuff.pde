boolean checkIf(boolean default_){
  return checkIf(getNextToken().string, getNextToken().string, getNextToken().string, getNextToken().string, default_);
}

boolean checkIf(String firstToken, String action, String secondToken, String thirdToken, boolean default_){
  VariableReturn firstVar = parseVariables(firstToken);
  VariableReturn secondVar = parseVariables(secondToken);
  if(hyperVerboseOutput){ println("checkIf: [" + firstToken + "](" + firstVar + ") " + action + " [" + secondToken + "](" + secondVar + ")"); }
  println("checkIf: [" + firstToken + "](" + firstVar + ") " + action + " [" + secondToken + "](" + secondVar + ")");
  if(firstToken.equals("")){ return default_; } // || action.equals("") || secondToken.string.equals("")
  
  if(firstVar.Number && secondVar.Number){
    VariableReturn thirdVar = thirdToken == null ? null : parseVariables(thirdToken);
    return checkCondition(firstVar, action, secondVar, thirdVar, default_);
  }else{
    switch(action){
      case "==":
        return firstVar.String.equals(secondVar.String); // check if strings are equal
      
      case "!=":
        return !firstVar.String.equals(secondVar.String);
      
      case "": // check if firstVar.String is true/false, or if firstToken.string is a defined variable
        switch(firstVar.String){
          case "true": return true;
          case "false": return false;
          default: return _Vars.hasKey(firstToken);
        }
      
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

boolean checkCase(){
  //VariableReturn switchValue = parseVariables(peekMacroArgs()[0]);
  int state = 0;
  StringList output = new StringList();
  
  TokenReturn token = getNextToken();
  for(; CurrentInputIndex < CurrentLineInput.length() && state != -1; CurrentInputIndex++){
    switch(state){
      case 0:
        switch(token.string){
          case "[": // start of value list
            state = 1;
            break;
          default: // must be a single value
            if(CurrentMacroArgs != null){ return checkIf(CurrentMacroArgs[0].Name, "==", token.string, null, false); }
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
