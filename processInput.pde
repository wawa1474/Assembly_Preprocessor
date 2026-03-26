enum ParseState{
  Entry,
  If_True,
  If_False,
  If_Skip,
  Switch_Look,
  Switch_Taken,
  Switch_Skip,
  Begin_Search,
  Begin_Loop,
}

void processInput(int depth_, ParseState state_){ // current depth of if statements for debuging
  ParseState state = state_; // state machines FTW!
  int curDepth = depth_;
  
  for(; getIndex() < getFileLength(); incIndex()){
    CurrentLineInput = getLine();
    CurrentLineOutput = CurrentLineInput;
    CurrentInputIndex = 0;
    TokenReturn token = getNextToken();
    if(token.string.length() > 0 && token.string.charAt(0) == ';'){ // skip comment-only lines
      if(maintainComments){ _output.append(CurrentLineInput); }
      popFileIfLastLine();
      continue;
    }
    boolean skip = true;
    if(hyperVerboseOutput || true){ println("[" + getIndex() + "]{" + state.name() + "}<" + token.string + "> " + CurrentLineInput); }
    
    switch(state){
      case Entry:
        switch(token.string){
          case ".include": checkIncludeFile(); break;
          case ".if": doIf(depth_); break;
          case ".let": parseLet(); break; // let/set? - set a variable that can be modified
          case ".equ": break; // equate - create a constant that can't be modified, outputs error if .let/.set/.equ afterwards
          case ".set": break; // set a global variable, .let would become temporary variable setting
          case ".macro": buildMacro(); break;
          case ".switch": doSwitch(depth_); break;
          case ".begin": doBegin(depth_); break;
          case "/*": cleanMultilineComments(); break;
          case ".org":
            storageOrigin = "dfsOrgLabel_" + getLabelUUID();
            CurrentLineOutput = storageOrigin + " = " + getNextToken().string;
            storageOffset = 0;
            skip = false;
            break;
          case ".dfs":
            token = getNextToken();
            String name = token.string;
            token = getNextToken();
            String len = token.string;
            
            CurrentLineOutput = name + " = " + // variable =
              storageOrigin + " + " + // origin +
              storageOffset; // length
            storageOffset += tryInt(len).Integer;
            skip = false;
            break;
          case ".db": handleDefineValue(VariableType.Byte); break;
          case ".dw": handleDefineValue(VariableType.Word); break;
          case ".drw": handleDefineValue(VariableType.RWord); break;
          default: skip = checkMacros(token.string); break;
        }
        break;
      
      case If_True: // if statement true
        switch(token.string){
          case ".include": checkIncludeFile(); break;
          case ".if": doIf(depth_); break;
          case ".else": case ".elseif": state = ParseState.If_Skip; break;
          case ".endif": return;
          case ".let": parseLet(); break;
          case ".macro": buildMacro(); break;
          case ".switch": doSwitch(depth_); break;
          case ".begin": doBegin(depth_); break;
          case "/*": cleanMultilineComments(); break;
          case ".db": handleDefineValue(VariableType.Byte); break;
          case ".dw": handleDefineValue(VariableType.Word); break;
          case ".drw": handleDefineValue(VariableType.RWord); break;
          default: skip = checkMacros(token.string); break;
        }
        break;
      
      case If_False: // if statement false
        switch(token.string){
          case ".if": curDepth++; break;
          case ".elseif": if(curDepth == depth_){ state = checkElseIf(); } break;
          case ".else": if(curDepth == depth_){ state = ParseState.If_True; } break;
          case ".endif": curDepth--; if(curDepth < depth_){ return; } break;
          case "/*": cleanMultilineComments(); break;
          default: break;
        }
        break;
      
      case If_Skip: // skip all until .endif
        switch(token.string){
          case ".if": curDepth++; break;
          case ".endif": curDepth--; if(curDepth < depth_){ return; } break;
          case "/*": cleanMultilineComments(); break;
          default: break;
        }
        break;
      
      case Switch_Look: // scan through lines looking for .case or .default
        switch(token.string){
          case ".case": state = checkCase(state); break;
          case ".default": state = ParseState.Switch_Taken; break;
          case ".endsw": popSwitchArg(); return;
          case "/*": cleanMultilineComments(); break;
          default: break;
        }
        break;
        
      case Switch_Taken: // case was found, output contents until .case, .default, or .endsw
        switch(token.string){
          case ".include": checkIncludeFile(); break;
          case ".if": doIf(depth_); break;
          case ".let": parseLet(); break;
          case ".macro": buildMacro(); break;
          case ".switch": doSwitch(depth_); break;
          case ".case": case ".default": break;
          case ".break": state = ParseState.Switch_Skip; break;
          case ".endsw": popSwitchArg(); return;
          case ".begin": doBegin(depth_); break;
          case "/*": cleanMultilineComments(); break;
          case ".db": handleDefineValue(VariableType.Byte); break;
          case ".dw": handleDefineValue(VariableType.Word); break;
          case ".drw": handleDefineValue(VariableType.RWord); break;
          default: skip = checkMacros(token.string); break;
        }
        break;
        
      case Switch_Skip: // skip all lines until .endsw is found
        switch(token.string){
          case ".switch": curDepth++; break;
          case ".endsw": curDepth--; if(curDepth < depth_){ popSwitchArg(); return; } break;
          case "/*": cleanMultilineComments(); break;
          default: break;
        }
        break;
      
      case Begin_Search:
        switch(token.string){
          case ".begin": curDepth++; break;
          case ".until":
          case ".repeat": curDepth--; if(curDepth < depth_){ doBeginEnd(); state = ParseState.Begin_Loop; } break;
          case "/*": cleanMultilineComments(); break;
          default: break;
        }
        break;
      
      case Begin_Loop:
        switch(token.string){
          case ".include": checkIncludeFile(); break;
          case ".if": doIf(depth_); break;
          case ".let": parseLet(); break;
          case ".macro": buildMacro(); break;
          case ".switch": doSwitch(depth_); break;
          case ".begin": doBegin(depth_); break;
          case ".while": if(!checkIf(true)){ popBegin(); return; } break;
          case ".until": if(checkIf(true)){ popBegin(); return; } else{ setIndex(peekBegin()); } break;
          case ".repeat": setIndex(peekBegin()); break;
          case "/*": cleanMultilineComments(); break;
          case ".db": handleDefineValue(VariableType.Byte); break;
          case ".dw": handleDefineValue(VariableType.Word); break;
          case ".drw": handleDefineValue(VariableType.RWord); break;
          default: skip = checkMacros(token.string); break;
        }
        break;
    }
    
    outputLine(skip);
    popFileIfLastLine();
  }
}
