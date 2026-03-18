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
  boolean skip = false;
  
  for(; _tmpFileHolder.indexArray < _tmpFileHolder.contents.length; _tmpFileHolder.indexArray++){
    String line = _tmpFileHolder.contents[_tmpFileHolder.indexArray];
    TokenReturn token = getNextToken(line,0);
    
    switch(state){
      case 0:
        switch(token.string){
          case ".if":
            boolean ifTrue = checkIf(line, token.nextIndex);
            if(ifTrue){ curDepth++; }
            skip = true;
            state = ifTrue ? 1 : 2;
            //boolean con = true;
            //boolean eat = false;
            //println((_tmpFileHolder.indexArray) + " : " + line + " = " + ifTrue);
            //if(ifTrue){
            //  while(con == true && _tmpFileHolder.indexArray < _tmpFileHolder.contents.length){
            //    _tmpFileHolder.indexArray++;
            //    line = _tmpFileHolder.contents[_tmpFileHolder.indexArray];
            //    token = getNextToken(line, 0);
            //    switch(token.string){
            //      case ".if": // needs to be recursive! or state-based with a depth counter!
            //      case ".else":
            //      case ".elseif":
            //        eat = true;
            //        break;
            //      case ".endif":
            //        con = false;
            //        eat = false;
            //        break;
            //      default:
            //        _output.append(line);
            //        break;
            //    }
            //  }
            //  if(eat){
            //    while(_tmpFileHolder.indexArray < _tmpFileHolder.contents.length){
            //      _tmpFileHolder.indexArray++;
            //      line = _tmpFileHolder.contents[_tmpFileHolder.indexArray];
            //      token = getNextToken(line, 0);
            //      if(token.string.equals(".endif")){
            //        break;
            //      }
            //    }
            //  }
            //}
            break;
          default:
            for(int i = 0; i < _Macros.size(); i++){
              Macro tmp = _Macros.get(i);
              if(tmp.name.equals(token.string)){
                //println(line);
                _output.append(parseMacro(tmp, line));
                skip = true;
              }
            }
            break;
        }
      
      case 1: // if statement true
        switch(token.string){
          //case ".if": // not gonna worry about nested if statements for now...
          case ".else":
          case ".elseif":
            skip = true;
            state = 5;
            break;
          case ".endif":
            curDepth--;
            skip = true;
            state = 0;
          default:
            // append line
            break;
        }
        break;
      
      case 2: // if statement false
        switch(token.string){
          //case ".if":
          case ".else":
            skip = true;
            state = 3;
            break;
          case ".elseif":
            boolean ifTrue = checkIf(line, token.nextIndex);
            skip = true;
            state = ifTrue ? 1 : 2;
            break;
          case ".endif":
            curDepth--;
            skip = true;
            state = 0;
          default:
            skip = true;
            break;
        }
        break;
      
      case 3: // append all until .endif
        switch(token.string){
          case ".endif":
            curDepth--;
            skip = true;
            state = 0;
          default:
            // append line
            break;
        }
        break;
      
      case 5: // eat all until .endif
        switch(token.string){
          case ".endif":
            curDepth--;
            skip = true;
            state = 0;
          default:
            skip = true;
            break;
        }
        break;
    }
  }
}
