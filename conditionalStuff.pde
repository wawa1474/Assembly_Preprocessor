boolean checkIf(String line, int index){
  TokenReturn firstVar = getNextToken(line, index);
  TokenReturn action = getNextToken(line, firstVar.nextIndex);
  TokenReturn secondVar = getNextToken(line, action.nextIndex);
  
  VariableReturn var1 = parseVariable(firstVar.string);
  VariableReturn var2 = parseVariable(secondVar.string);
  
  String v1 = getVariable(var1, null, null);
  String v2 = getVariable(var2, null, null);
  
  IntReturn i1 = tryInt(v1);
  IntReturn i2 = tryInt(v2);
  
  switch(action.string){
    case "==":
      if(i1.valid && i2.valid){ return i1.value == i2.value; } // check if integers are equal
      else{ return v1.equals(v2); } // check if strings are equal
    
    case "!=":
      if(i1.valid && i2.valid){ return i1.value != i2.value; }
      else{ return !v1.equals(v2); }
    
    case ">":
      if(i1.valid && i2.valid){ return i1.value > i2.value; }
      break;
    
    case "<":
      if(i1.valid && i2.valid){ return i1.value < i2.value; }
      break;
    
    case ">=":
      if(i1.valid && i2.valid){ return i1.value >= i2.value; }
      break;
    
    case "<=":
      if(i1.valid && i2.valid){ return i1.value <= i2.value; }
      break;
    
    default:
      return false;
  }
  
  return false;
}

void parseIf(int curDepth){
  int state = 0; // state machines FTW!
  //int curDepth = 0; // current depth of if statements
  int depth = 0; // added depth of if statements to ignore (when condition is false)
  
  for(; _tmpFileHolder.indexArray < _tmpFileHolder.contents.length; _tmpFileHolder.indexArray++){
    String line = _tmpFileHolder.contents[_tmpFileHolder.indexArray];
    TokenReturn token = getNextToken(line,0);
    
    switch(state){
      case 0:
        
    }
  }
}
