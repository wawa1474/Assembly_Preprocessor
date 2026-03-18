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
    if(token.string.length() > 0 && token.string.charAt(0) == ';'){ // skip comment-only lines
      if(maintainComments){ _output.append(line); }
      popFileIfLastLine();
      continue;
    }
    boolean skip = true;
    if(hyperVerboseOutput){ println("[" + getIndex() + "]{" + state.name() + "}<" + token.string + "> " + line); }
    
    switch(state){
      case Entry:
        switch(token.string){
          case ".include": checkIncludeFile(line, token.nextIndex); break;
          case ".if": doIf(line, token, depth_); break;
          case ".let": parseLet(line, token.nextIndex); break; // let/set? - set a variable that can be modified
          case ".equ": break; // equate - set a variable that can't be modified
          case ".macro": buildMacro(line, token.nextIndex); break;
          case ".switch": doSwitch(line, token, depth_); break;
          case ".repeat": doRepeat(depth_); break;
          case "/*": cleanMultilineComments(); break;
          case ".org":
            storageOrigin = "dfsOrgLabel_" + getLabelUUID();
            line = storageOrigin + " = " + getNextToken(line, token.nextIndex).string;
            storageOffset = 0;
            skip = false;
            break;
          case ".dfs":
            token = getNextToken(line, token.nextIndex);
            String name = token.string;
            token = getNextToken(line, token.nextIndex);
            String len = token.string;
            
            line = name + " = " + // variable =
              storageOrigin + " + " + // origin +
              storageOffset; // length
            storageOffset += tryInt(len).Integer;
            skip = false;
            break;
          case ".db": line = handleDefineValue(line, token.nextIndex, VariableType.Byte); skip = false; break;
          case ".dw": line = handleDefineValue(line, token.nextIndex, VariableType.Word); skip = false; break;
          case ".drw": line = handleDefineValue(line, token.nextIndex, VariableType.RWord); skip = false; break;
          default: skip = checkMacros(token.string, line, token.nextIndex); break;
        }
        break;
      
      case If_True: // if statement true
        switch(token.string){
          case ".include": checkIncludeFile(line, token.nextIndex); break;
          case ".if": doIf(line, token, depth_); break;
          case ".else": case ".elseif": state = ParseState.If_Skip; break;
          case ".endif": return;
          case ".let": parseLet(line, token.nextIndex); break;
          case ".macro": buildMacro(line, token.nextIndex); break;
          case ".switch": doSwitch(line, token, depth_); break;
          case ".repeat": doRepeat(depth_); break;
          case "/*": cleanMultilineComments(); break;
          case ".db": line = handleDefineValue(line, token.nextIndex, VariableType.Byte); skip = false; break;
          case ".dw": line = handleDefineValue(line, token.nextIndex, VariableType.Word); skip = false; break;
          case ".drw": line = handleDefineValue(line, token.nextIndex, VariableType.RWord); skip = false; break;
          default: skip = checkMacros(token.string, line, token.nextIndex); break;
        }
        break;
      
      case If_False: // if statement false
        switch(token.string){
          case ".if": curDepth++; break;
          case ".elseif": if(curDepth == depth_){ state = checkElseIf(line, token); } break;
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
          case ".case": state = checkCase(line, token, state); break;
          case ".default": state = ParseState.Switch_Taken; break;
          case ".endsw": popSwitchArg(); return;
          case "/*": cleanMultilineComments(); break;
          default: break;
        }
        break;
        
      case Switch_Taken: // case was found, output contents until .case, .default, or .endsw
        switch(token.string){
          case ".include": checkIncludeFile(line, token.nextIndex); break;
          case ".if": doIf(line, token, depth_); break;
          case ".let": parseLet(line, token.nextIndex); break;
          case ".macro": buildMacro(line, token.nextIndex); break;
          case ".switch": doSwitch(line, token, depth_); break;
          case ".case": case ".default": break;
          case ".break": state = ParseState.Switch_Skip; break;
          case ".endsw": popSwitchArg(); return;
          case ".repeat": doRepeat(depth_); break;
          case "/*": cleanMultilineComments(); break;
          case ".db": line = handleDefineValue(line, token.nextIndex, VariableType.Byte); skip = false; break;
          case ".dw": line = handleDefineValue(line, token.nextIndex, VariableType.Word); skip = false; break;
          case ".drw": line = handleDefineValue(line, token.nextIndex, VariableType.RWord); skip = false; break;
          default: skip = checkMacros(token.string, line, token.nextIndex); break;
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
      
      case Repeat_Loop:
        switch(token.string){
          case ".include": checkIncludeFile(line, token.nextIndex); break;
          case ".if": doIf(line, token, depth_); break;
          case ".let": parseLet(line, token.nextIndex); break;
          case ".macro": buildMacro(line, token.nextIndex); break;
          case ".switch": doSwitch(line, token, depth_); break;
          case ".repeat": doRepeat(depth_); break;
          case ".until": if(checkIf(line, token.nextIndex, true)){ popRepeat(); return; } else{ setIndex(peekRepeat()); } break;
          case "/*": cleanMultilineComments(); break;
          case ".db": line = handleDefineValue(line, token.nextIndex, VariableType.Byte); skip = false; break;
          case ".dw": line = handleDefineValue(line, token.nextIndex, VariableType.Word); skip = false; break;
          case ".drw": line = handleDefineValue(line, token.nextIndex, VariableType.RWord); skip = false; break;
          default: skip = checkMacros(token.string, line, token.nextIndex); break;
        }
        break;
    }
    
    outputLine(line, skip);
    popFileIfLastLine();
  }
}
