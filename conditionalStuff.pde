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
          case ".include":
            println((_tmpFileHolder.indexArray) + " : " + line);
            buildMacro(loadStrings(_tmpFileHolder.baseDirectory + split(line, " ")[1]));
            skip = true;
            break;
          case "#include":
            println((_tmpFileHolder.indexArray) + " : " + line);
            /*
              preprocessor will work through a file until it hits a #include
              at which point, it will load and push the included file
              and begin working through the new file until reaching another include or it reaches the end of the file
              if it reaches the end of the current file, pop it from the stack
              and continue working on existing files
              if no more files exist, then we are done!
            */
            //_FileStack.push(_tmpFileHolder);
            //getNewFile(_tmpFileHolder.baseDirectory, getNextToken(line, firstToken.nextIndex).string.replace("\"", ""));
            break;
          case ".if":
            boolean ifTrue = checkIf(line, token.nextIndex);
            if(ifTrue){ curDepth++; }
            skip = true;
            state = ifTrue ? 1 : 2;
            break;
          default:
            skip = checkMacros(token.string, line);
            break;
        }
        break;
      
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
            break;
          case ".include":
            println((_tmpFileHolder.indexArray) + " : " + line);
            buildMacro(loadStrings(_tmpFileHolder.baseDirectory + getNextToken(line,token.nextIndex).string));
            skip = true;
            break;
          case "#include":
            break;
          default:
            // append line
            skip = checkMacros(token.string, line);
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
            break;
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
            break;
          case ".include":
            println((_tmpFileHolder.indexArray) + " : " + line);
            buildMacro(loadStrings(_tmpFileHolder.baseDirectory + getNextToken(line,token.nextIndex).string));
            skip = true;
            break;
          case "#include":
            break;
          default:
            // append line
            skip = checkMacros(token.string, line);
            break;
        }
        break;
      
      case 5: // eat all until .endif
        switch(token.string){
          case ".endif":
            curDepth--;
            skip = true;
            state = 0;
            break;
          default:
            skip = true;
            break;
        }
        break;
    }
  }
}
