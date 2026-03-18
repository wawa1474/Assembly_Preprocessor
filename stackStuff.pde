void pushMacroArgs(String[] args){
  _macro_Args2.add(args);
}

String[] popMacroArgs(){
  return _macro_Args2.remove(_macro_Args2.size() - 1);
}

String[] peekMacroArgs(){
  if(_macro_Args2.size() > 0){
    return _macro_Args2.get(_macro_Args2.size() - 1);
  }
  return new String[0];
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
