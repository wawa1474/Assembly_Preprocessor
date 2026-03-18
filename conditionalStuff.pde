boolean checkIf(String line, int index){
  TokenReturn firstToken = getNextToken(line, index);
  TokenReturn action = getNextToken(line, firstToken.nextIndex);
  TokenReturn secondToken = getNextToken(line, action.nextIndex);
  
  VariableReturn firstVar = parseVariables(firstToken.string);
  VariableReturn secondVar = parseVariables(secondToken.string);
  
  if(firstVar.Number && secondVar.Number){
    return checkCondition(firstVar.Integer, action, secondVar.Integer);
  }else{
    switch(action.string){
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
  incIndex(); // skip the .if line
  int curDepth = depth_;
  
  for(; getIndex() < getFileLength(); incIndex()){
    String line = getLine();
    TokenReturn token = getNextToken(line,0);
    boolean skip = true;
    
    switch(state){
      case 0:
        switch(token.string){
          case ".include": // .include "path/name.ext"
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
            buildMacro(line, token.nextIndex);
            break;
          default:
            skip = checkMacros(token.string, line, token.nextIndex);//
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
          case ".include": // .include "path/name.ext"
            checkIncludeFile(line, token.nextIndex);
            break;
          case ".let":
            parseLet(line, token.nextIndex);
            break;
          case ".macro":
            buildMacro(line, token.nextIndex);
            break;
          default:
            skip = checkMacros(token.string, line, token.nextIndex);//
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
          case ".include": // .include "path/name.ext"
            checkIncludeFile(line, token.nextIndex);
            break;
          case ".let":
            parseLet(line, token.nextIndex);
            break;
          case ".macro":
            buildMacro(line, token.nextIndex);
            break;
          default:
            skip = checkMacros(token.string, line, token.nextIndex);//
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
    
    outputLine(line, skip);
    popFileIfLastLine();
  }
}
