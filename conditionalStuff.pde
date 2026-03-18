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

void parseIf(String line_, int index_, int depth_){ // current depth of if statements for debuging
  int state = checkIf(line_, index_) ? 1 : 2; // state machines FTW!
  _tmpFileHolder.indexArray++; // skip the .if line
  int curDepth = depth_;
  
  for(; _tmpFileHolder.indexArray < _tmpFileHolder.contents.length; _tmpFileHolder.indexArray++){
    String line = _tmpFileHolder.contents[_tmpFileHolder.indexArray];
    TokenReturn token = getNextToken(line,0);
    boolean skip = true;
    //println("parseIf [" + curDepth + "|" + depth_ + "|" + _tmpFileHolder.indexArray + "] " + line);
    
    switch(state){
      case 0:
        switch(token.string){
          case ".include": // .include macro|file "path/name.ext"
            checkIncludeFile(line, token.nextIndex);
            break;
          case ".if":
            parseIf(line, token.nextIndex, depth_+1);
            break;
          case ".endif":
            return;
          case ".let":
            parseLet(line, token.nextIndex);
            break;
          case ".macro":
            parseMacro(line, token.nextIndex);
            break;
          default:
            skip = checkMacros(token.string, line);
            break;
        }
        break;
      
      case 1: // if statement true
        switch(token.string){
          case ".if":
            parseIf(line, token.nextIndex, depth_+1);
            break;
          case ".else":
          case ".elseif":
            state = 5;
            break;
          case ".endif":
            return;
          case ".include": // .include macro|file "path/name.ext"
            checkIncludeFile(line, token.nextIndex);
            break;
          case ".let":
            parseLet(line, token.nextIndex);
            break;
          case ".macro":
            parseMacro(line, token.nextIndex);
            break;
          default:
            skip = checkMacros(token.string, line);
            break;
        }
        break;
      
      case 2: // if statement false
        switch(token.string){
          case ".if":
            curDepth++;
            break;
          case ".else":
            if(curDepth == depth_){ state = 3; }
            break;
          case ".elseif":
            if(curDepth == depth_){
              boolean ifTrue = checkIf(line, token.nextIndex);
              state = ifTrue ? 1 : 2;
            }
            break;
          case ".endif":
            curDepth--;
            if(curDepth < depth_){ return; }
            break;
          default:
            break;
        }
        break;
      
      case 3: // append all until .endif
        switch(token.string){
          case ".if":
            parseIf(line, token.nextIndex, depth_+1);
            break;
          case ".endif":
            return;
          case ".include": // .include macro|file "path/name.ext"
            checkIncludeFile(line, token.nextIndex);
            break;
          case ".let":
            parseLet(line, token.nextIndex);
            break;
          case ".macro":
            parseMacro(line, token.nextIndex);
            break;
          default:
            skip = checkMacros(token.string, line);
            break;
        }
        break;
      
      case 5: // eat all until .endif
        switch(token.string){
          case ".if":
            curDepth++;
            break;
          case ".endif":
            curDepth--;
            if(curDepth < depth_){ return; }
            break;
          default:
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
