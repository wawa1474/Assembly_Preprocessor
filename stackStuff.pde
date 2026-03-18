void doIf(String line, TokenReturn token, int depth_){
  incIndex(); // skip the .if line
  processInput(depth_+1, checkIf(line, token.nextIndex, false) ? ParseState.If_True : ParseState.If_False);
}

ParseState checkElseIf(String line, TokenReturn token){
  return checkIf(line, token.nextIndex, false) ? ParseState.If_True : ParseState.If_False;
}

ParseState checkCase(String line, TokenReturn token, ParseState state){
  token = getNextToken(line, token.nextIndex);
  if(checkIf(new TokenReturn(peekSwitchArg(), 0), token.string, getNextToken(line, token.nextIndex), null, false)){
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

String g_TOS(String name){
  int len = Stacks.get(name).size();
  return Stacks.get(name).get(len - 1);
}

int g_DEPTH(String name){
  return Stacks.get(name).size();
}

void g_CLEAR(String name){
  Stacks.get(name).clear();
}

void g_PUSHNEW(String name, String value){
  Stacks.put(name, new StringList(value));
}

void g_CREATESTACK(String name){
  Stacks.put(name, new StringList());
}

void g_PUSH(String name, String value){
  Stacks.get(name).append(value);
}

String g_PEEK(String name){
  return Stacks.get(name).get(Stacks.get(name).size() - 1);
}

String g_PEEK(String name, int index){
  return Stacks.get(name).get(Stacks.get(name).size() - 1 - index);
}

void g_POKE(String name, String value, int index){
  Stacks.get(name).set(Stacks.get(name).size() - 1 - index, value);
}

String g_POP(String name){
  int len = Stacks.get(name).size();
  String tmp = Stacks.get(name).get(len - 1);
  Stacks.get(name).remove(len - 1);
  return tmp;
}

String g_PLUCK(String name, int value){
  int len = Stacks.get(name).size();
  String tmp = Stacks.get(name).get(len - value - 1);
  Stacks.get(name).remove(len - value - 1);
  return tmp;
}

void pushTmpVars(){
  _TmpMacroVarsArr.add(_TmpMacroVars.copy());
  _TmpGlobalVarsArr.add((HashMap<String, String>)_TmpGlobalVars.clone());
}

void popTmpVars(){ // java is such a pain at times...
  int len = _TmpMacroVarsArr.size();
  _TmpMacroVars = _TmpMacroVarsArr.get(len - 1).copy();
  _TmpMacroVarsArr.remove(len - 1);
  
  for(Map.Entry<String, String> me : _TmpGlobalVars.entrySet()){
    updateVariable(me.getKey(), me.getValue());
  }
  
  len = _TmpGlobalVarsArr.size();
  _TmpGlobalVars = (HashMap<String, String>)_TmpGlobalVarsArr.get(len - 1).clone();
  _TmpGlobalVarsArr.remove(len - 1);
}
