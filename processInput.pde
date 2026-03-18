enum ParseState{
  Entry,
  If_True,
  If_False,
  If_Skip,
  Switch_Look,
  Switch_Taken,
  Switch_Skip,
  Repeat_Loop,
}

void processInput(int depth_, ParseState state_){ // current depth of if statements for debuging
  ParseState state = state_; // state machines FTW!
  int curDepth = depth_;
  
  for(; getIndex() < getFileLength(); incIndex()){
    String line = getLine();
    TokenReturn token = getNextToken(line,0);
    boolean skip = true;
    //println("[" + getIndex() + "]{" + state.name() + "} " + line);
    
    switch(state){
      case Entry:
        switch(token.string){
          case ".include": // .include "path/name.ext"
            checkIncludeFile(line, token.nextIndex);
            break;
          case ".if":
            incIndex(); // skip the .if line
            processInput(depth_+1, checkIf(line, token.nextIndex) ? ParseState.If_True : ParseState.If_False);
            break;
          case ".endif":
            return;
          case ".let":
            parseLet(line, token.nextIndex);
            break;
          case ".macro":
            buildMacro(line, token.nextIndex);
            break;
          case ".switch":
            pushSwitchArg(getNextToken(line, token.nextIndex).string);
            incIndex();
            processInput(depth_+1, ParseState.Switch_Look);
            break;
          case ".repeat":
            _repeat_Args.add(new RepeatInfo(getIndex(), line, token.nextIndex));
            incIndex();
            processInput(depth_+1, ParseState.Repeat_Loop);
            break;
          default:
            skip = checkMacros(token.string, line, token.nextIndex);//
            break;
        }
        break;
      
      case If_True: // if statement true
        switch(token.string){
          case ".if":
            incIndex(); // skip the .if line
            processInput(depth_+1, checkIf(line, token.nextIndex) ? ParseState.If_True : ParseState.If_False);
            break;
          case ".else":
          case ".elseif":
            state = ParseState.If_Skip;
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
          case ".switch":
            pushSwitchArg(getNextToken(line, token.nextIndex).string);
            processInput(depth_+1, ParseState.Switch_Look);
            break;
          case ".repeat":
            _repeat_Args.add(new RepeatInfo(getIndex(), line, token.nextIndex));
            incIndex();
            processInput(depth_+1, ParseState.Repeat_Loop);
            break;
          default:
            skip = checkMacros(token.string, line, token.nextIndex);//
            break;
        }
        break;
      
      case If_False: // if statement false
        switch(token.string){
          case ".if":
            curDepth++;
            break;
          case ".else":
            if(curDepth == depth_){ state = ParseState.If_True; }
            break;
          case ".elseif":
            if(curDepth == depth_){
              state = checkIf(line, token.nextIndex) ? ParseState.If_True : ParseState.If_False;
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
      
      case If_Skip: // skip all until .endif
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
      
      case Switch_Look: // scan through lines looking for .case or .default
        switch(token.string){
          case ".case":
            token = getNextToken(line, token.nextIndex);
            if(checkIf(new TokenReturn(peekSwitchArg(), 0), token.string, getNextToken(line, token.nextIndex))){
              state = ParseState.Switch_Taken;
            }
            break;
          case ".default": // always take .default in this state
            state = ParseState.Switch_Taken;
            break;
          case ".endsw":
            popSwitchArg();
            return;
          default:
            break;
        }
        break;
        
      case Switch_Taken: // case was found, output contents until .case, .default, or .endsw
        switch(token.string){
          case ".if":
            incIndex(); // skip the .if line
            processInput(depth_+1, checkIf(line, token.nextIndex) ? ParseState.If_True : ParseState.If_False);
            break;
          case ".case":
          case ".default":
            break;
          case ".break":
            state = ParseState.Switch_Skip;
            break;
          case ".endsw":
            popSwitchArg();
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
          case ".switch":
            pushSwitchArg(getNextToken(line, token.nextIndex).string);
            processInput(depth_+1, ParseState.Switch_Look);
            break;
          case ".repeat":
            _repeat_Args.add(new RepeatInfo(getIndex(), line, token.nextIndex));
            incIndex();
            processInput(depth_+1, ParseState.Repeat_Loop);
            break;
          default:
            skip = checkMacros(token.string, line, token.nextIndex);//
            break;
        }
        break;
        
      case Switch_Skip: // skip all lines until .endsw is found
        switch(token.string){
          case ".switch":
            curDepth++;
            break;
          case ".endsw":
            curDepth--;
            if(curDepth < depth_){
              popSwitchArg();
              return;
            }
            break;
          default:
            break;
        }
        break;
      
      case Repeat_Loop:
        switch(token.string){
          case ".include": // .include "path/name.ext"
            checkIncludeFile(line, token.nextIndex);
            break;
          case ".if":
            incIndex(); // skip the .if line
            processInput(depth_+1, checkIf(line, token.nextIndex) ? ParseState.If_True : ParseState.If_False);
            break;
          case ".endif":
            return;
          case ".let":
            parseLet(line, token.nextIndex);
            break;
          case ".macro":
            buildMacro(line, token.nextIndex);
            break;
          case ".switch":
            pushSwitchArg(getNextToken(line, token.nextIndex).string);
            processInput(depth_+1, ParseState.Switch_Look);
            break;
          case ".repeat":
            _repeat_Args.add(new RepeatInfo(getIndex(), line, token.nextIndex));
            incIndex();
            processInput(depth_+1, ParseState.Repeat_Loop);
            break;
          case ".endrp":
            RepeatInfo tmp = _repeat_Args.get(_repeat_Args.size() - 1);
            if(tmp.checkInfo()){
              _repeat_Args.remove(_repeat_Args.size() - 1);
              return;
            }else{
              setIndex(tmp.Start);
            }
            break;
          default:
            skip = checkMacros(token.string, line, token.nextIndex);//
            break;
        }
        break;
    }
    
    outputLine(line, skip);
    popFileIfLastLine();
  }
}
