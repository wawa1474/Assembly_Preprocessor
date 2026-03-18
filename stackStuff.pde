void doIf(String line, TokenReturn token, int depth_){
  incIndex(); // skip the .if line
  processInput(depth_+1, checkIf(line, token.nextIndex, false) ? ParseState.If_True : ParseState.If_False);
}

ParseState checkElseIf(String line, TokenReturn token){
  return checkIf(line, token.nextIndex, false) ? ParseState.If_True : ParseState.If_False;
}

ParseState checkCase(String line, TokenReturn token, ParseState state){
  token = getNextToken(line, token.nextIndex);
  if(checkIf(new TokenReturn(peekSwitchArg(), 0), token.string, getNextToken(line, token.nextIndex), false)){
    return ParseState.Switch_Taken;
  }
  return state;
}

void pushMacroArgs(MacroArg[] args){
  MacroArgsStack.add(args);
}

MacroArg[] popMacroArgs(){
  if(MacroArgsStack == null || MacroArgsStack.size() == 0){ return null; }
  return MacroArgsStack.remove(MacroArgsStack.size() - 1);
}

Worker popWorker(){
  return Workers.remove(Workers.size() - 1);
}

void doSwitch(String line, TokenReturn token, int depth_){
  pushSwitchArg(getNextToken(line, token.nextIndex).string);
  incIndex();
  processInput(depth_+1, ParseState.Switch_Look);
}

void pushSwitchArg(String arg){
  _switch_Args.append(arg);
}

String popSwitchArg(){
  return _switch_Args.remove(_switch_Args.size() - 1);
}

String peekSwitchArg(){
  if(_switch_Args.size() > 0){
    return _switch_Args.get(_switch_Args.size() - 1);
  }
  return "";
}

void doRepeat(int depth_){
  _repeat_Args.push(getIndex());
  incIndex();
  processInput(depth_+1, ParseState.Repeat_Loop);
}

void popRepeat(){
  _repeat_Args.pop();
}

int peekRepeat(){
  return _repeat_Args.get(_repeat_Args.size() - 1);
}
