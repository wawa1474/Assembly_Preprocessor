boolean checkIf(String line, int index){
  Token2 firstVar = getNextVariable(line, index);
  TokenReturn action = getNextToken(line, firstVar.nextIndex);
  Token2 secondVar = getNextVariable(line, action.nextIndex);
  
  if(firstVar.Type == TokenType.Number && secondVar.Type == TokenType.Number){
    //println("checkIf " + firstVar.Integer + " " + action.string + " " + secondVar.Integer);
    switch(action.string){
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
    //println("checkIf " + getVariable(firstVar, null, null) + " " + action.string + " " + getVariable(secondVar, null, null));
    switch(action.string){
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

void parseIf(String line_, int index_, int depth){ // current depth of if statements for debuging
  //println("init line: " + _tmpFileHolder.indexArray + " : " + line_);
  int state = checkIf(line_, index_) ? 1 : 2; // state machines FTW!
  //println("init state: " + state + " @ " + depth);
  _tmpFileHolder.indexArray++; // skip the .if line
  boolean skip = false;
  
  for(; _tmpFileHolder.indexArray < _tmpFileHolder.contents.length; _tmpFileHolder.indexArray++){
    String line = _tmpFileHolder.contents[_tmpFileHolder.indexArray];
    //println(_tmpFileHolder.indexArray + " : " + line);
    TokenReturn token = getNextToken(line,0);
    
    //println("state: " + state);
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
            parseIf(line, token.nextIndex, depth+1);
            skip = true;
            break;
          default:
            skip = checkMacros(token.string, line);
            //println("skip0: " + skip);
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
            //println((_tmpFileHolder.indexArray) + " : " + line);
            skip = true;
            return;
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
            //println("skip1: " + skip);
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
            //println((_tmpFileHolder.indexArray) + " : " + line);
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
            //println((_tmpFileHolder.indexArray) + " : " + line);
            skip = true;
            return;
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
            //println("skip3: " + skip);
            break;
        }
        break;
      
      case 5: // eat all until .endif
        switch(token.string){
          case ".endif":
            //println((_tmpFileHolder.indexArray) + " : " + line);
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
    
    if(_tmpFileHolder.indexArray >= _tmpFileHolder.contents.length - 1 && _FileStack.size > 0){
      print("pop file: " + _tmpFileHolder.filename);
      _tmpFileHolder = _FileStack.pop();
      println(" for: " + _tmpFileHolder.filename);
    }
  }
}
