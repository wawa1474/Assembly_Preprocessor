class RepeatInfo{
  int Start;
  TokenReturn firstToken;
  TokenReturn Action;
  TokenReturn secondToken;
  
  RepeatInfo(int s, String line, int index){
    Start = s;
    firstToken = getNextToken(line, index);
    Action = getNextToken(line, firstToken.nextIndex);
    secondToken = getNextToken(line, Action.nextIndex);
    //println("[RepeatInfo] @ " + s + " == " + line + ": " + firstToken + ", "  + Action + ", "  + secondToken);
  }
  
  boolean checkInfo(){
    //println("[checkInfo] == " + checkIf(firstToken, Action.string, secondToken));
    return checkIf(firstToken, Action.string, secondToken);
  }
}

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
            return checkIf(new TokenReturn(peekMacroArgs()[0], 0), "==", token);
        }
    }
  }
  
  return false;
}
