boolean checkIf(String line, int index){
  Token2 firstVar = getNextVariable(line, index);
  Token2 action = getNextVariable(line, firstVar.nextIndex);
  Token2 secondVar = getNextVariable(line, action.nextIndex);
  
  if(firstVar.Type == TokenType.Number && secondVar.Type == TokenType.Number){
    switch(action.Identifier){
      case "==":
        return firstVar.Integer == secondVar.Integer; // check if integers are equal
      
      case "!=":
        return firstVar.Integer != secondVar.Integer;
      
      case ">":
        return firstVar.Integer > secondVar.Integer;
      
      case "<":
        return firstVar.Integer < secondVar.Integer;
      
      case ">=":
        return firstVar.Integer >= secondVar.Integer;
      
      case "<=":
        return firstVar.Integer <= secondVar.Integer;
      
      default:
        return false;
    }
  }else{
    switch(action.Identifier){
      case "==":
        return getVariable(firstVar, null, null).equals(getVariable(secondVar, null, null)); // check if strings are equal
      
      case "!=":
        return !getVariable(firstVar, null, null).equals(getVariable(secondVar, null, null));
      
      default:
        return false;
    }
  }
  
  //return false;
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
            getNewFile(_tmpFileHolder.baseDirectory, getNextToken(line, token.nextIndex).string);
            skip = true;
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
            println((_tmpFileHolder.indexArray) + " : " + line);
            getNewFile(_tmpFileHolder.baseDirectory, getNextToken(line, token.nextIndex).string);
            skip = true;
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
            println((_tmpFileHolder.indexArray) + " : " + line);
            getNewFile(_tmpFileHolder.baseDirectory, getNextToken(line, token.nextIndex).string);
            skip = true;
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
