void processInput(int depth_, int state_){ // current depth of if statements for debuging
  int state = state_; // state machines FTW!
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
            incIndex(); // skip the .if line
            processInput(depth_+1, checkIf(line, token.nextIndex) ? 1 : 2);
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
            incIndex(); // skip the .if line
            processInput(depth_+1, checkIf(line, token.nextIndex) ? 1 : 2);
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
            incIndex(); // skip the .if line
            processInput(depth_+1, checkIf(line, token.nextIndex) ? 1 : 2);
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
