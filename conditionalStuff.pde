boolean checkIf(String line, int index){
  TokenReturn firstToken = getNextToken(line, index);
  TokenReturn action = getNextToken(line, firstToken.nextIndex);
  TokenReturn secondToken = getNextToken(line, action.nextIndex);
  return checkIf(firstToken, action.string, secondToken);
}

boolean checkIf(TokenReturn firstToken, String action, TokenReturn secondToken){
  VariableReturn firstVar = parseVariables(firstToken.string);
  VariableReturn secondVar = parseVariables(secondToken.string);
  //println("checkIf: [" + firstToken.string + "](" + firstVar + ") " + action + " [" + secondToken.string + "](" + secondVar + ")");
  
  if(firstVar.Number && secondVar.Number){
    return checkCondition(firstVar.Integer, action, secondVar.Integer);
  }else{
    switch(action){
      case "==":
        return firstVar.String.equals(secondVar.String); // check if strings are equal
      
      case "!=":
        return !firstVar.String.equals(secondVar.String);
      
      case "": // check if var is defined
        return _Vars.hasKey(firstToken.string.replace("%%",""));
      
      default:
        return false;
    }
  }
}

boolean checkCondition(int firstVar, String action, int secondVar){
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
      return false;
  }
}
