boolean checkIf(String line, int index){
  Token2 firstVar = getNextVariable(line, index);
  TokenReturn action = getNextToken(line, firstVar.nextIndex);
  Token2 secondVar = getNextVariable(line, action.nextIndex);
  
  if(firstVar.Type == TokenType.Number && secondVar.Type == TokenType.Number){
    return checkCondition(firstVar.Integer, action, secondVar.Integer);
  }else{
    firstVar = getNextVariable(getVariable(firstVar, null, null), 0);
    secondVar = getNextVariable(getVariable(secondVar, null, null), 0);
    
    if(firstVar.Type == TokenType.Number && secondVar.Type == TokenType.Number){
      return checkCondition(firstVar.Integer, action, secondVar.Integer);
    }else{
      switch(action.string){
        case "==":
          return getVariable(firstVar, null, null).equals(getVariable(secondVar, null, null)); // check if strings are equal
        
        case "!=":
          return !getVariable(firstVar, null, null).equals(getVariable(secondVar, null, null));
        
        default:
          return false;
      }
    }
  }
}

boolean checkCondition(int firstVar, TokenReturn action, int secondVar){
  switch(action.string){
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

void parseIf(String line_, int index_, int depth){ // current depth of if statements for debuging
  int state = checkIf(line_, index_) ? 1 : 2; // state machines FTW!
  _tmpFileHolder.indexArray++; // skip the .if line
  boolean skip = false;
  
  for(; _tmpFileHolder.indexArray < _tmpFileHolder.contents.length; _tmpFileHolder.indexArray++){
    String line = _tmpFileHolder.contents[_tmpFileHolder.indexArray];
    TokenReturn token = getNextToken(line,0);
    
    switch(state){
      case 0:
        switch(token.string){
          case ".include":
            println((_tmpFileHolder.indexArray) + " : " + line);
            buildMacro(loadStrings(_tmpFileHolder.file.getPath() + split(line, " ")[1]));
            skip = true;
            break;
          case "#include":
            println("push file: " + (_tmpFileHolder.indexArray) + " : " + line);
            getNewFile(_tmpFileHolder.file, getNextToken(line, token.nextIndex).string);
            skip = true;
            break;
          case ".if":
            parseIf(line, token.nextIndex, depth+1);
            skip = true;
            break;
          case ".let":
            parseLet(line, token.nextIndex);
            skip = true;
            break;
          default:
            skip = checkMacros(token.string, line);
            break;
        }
        break;
      
      case 1: // if statement true
        switch(token.string){
          case ".if":
            parseIf(line, token.nextIndex, depth+1);
            skip = true;
            break;
          case ".else":
          case ".elseif":
            skip = true;
            state = 5;
            break;
          case ".endif":
            skip = true;
            return;
          case ".include":
            println((_tmpFileHolder.indexArray) + " : " + line);
            buildMacro(loadStrings(_tmpFileHolder.file.getPath() + getNextToken(line,token.nextIndex).string));
            skip = true;
            break;
          case "#include":
            println("push file: " + (_tmpFileHolder.indexArray) + " : " + line);
            getNewFile(_tmpFileHolder.file, getNextToken(line, token.nextIndex).string);
            skip = true;
            break;
          case ".let":
            parseLet(line, token.nextIndex);
            skip = true;
            break;
          default:
            skip = checkMacros(token.string, line);
            break;
        }
        break;
      
      case 2: // if statement false
        switch(token.string){
          case ".if":
            parseIf(line, token.nextIndex, depth+1);
            skip = true;
            break;
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
            skip = true;
            return;
          default:
            skip = true;
            break;
        }
        break;
      
      case 3: // append all until .endif
        switch(token.string){
          case ".if":
            parseIf(line, token.nextIndex, depth+1);
            skip = true;
            break;
          case ".endif":
            skip = true;
            return;
          case ".include":
            println((_tmpFileHolder.indexArray) + " : " + line);
            buildMacro(loadStrings(_tmpFileHolder.file.getPath() + getNextToken(line,token.nextIndex).string));
            skip = true;
            break;
          case "#include":
            println("push file: " + (_tmpFileHolder.indexArray) + " : " + line);
            getNewFile(_tmpFileHolder.file, getNextToken(line, token.nextIndex).string);
            skip = true;
            break;
          case ".let":
            parseLet(line, token.nextIndex);
            skip = true;
            break;
          default:
            skip = checkMacros(token.string, line);
            break;
        }
        break;
      
      case 5: // eat all until .endif
        switch(token.string){
          case ".endif":
            skip = true;
            return;
          default:
            skip = true;
            break;
        }
        break;
    }
    
    if(!skip){
      _output.append(line);
    }
    
    popFileIfLastLine();
  }
}
