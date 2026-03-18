enum ParseState{
  Entry,
  If_True,
  If_False,
  If_Skip,
  Switch_Look,
  Switch_Taken,
  Switch_Skip,
  Repeat_Loop,
  Multiline_Comment_Entry,
  Multiline_Comment,
}

void processInput(int depth_, ParseState state_){ // current depth of if statements for debuging
  ParseState state = state_; // state machines FTW!
  int curDepth = depth_;
  
  for(; getIndex() < getFileLength(); incIndex()){
    String line = getLine();
    if(line.length() > 0 && line.charAt(0) == ';'){ continue; } // skip comment-only lines
    TokenReturn token = getNextToken(line,0);
    boolean skip = true;
    //println("[" + getIndex() + "]{" + state.name() + "} " + line);
    
    switch(state){
      case Entry:
        switch(token.string){
          case ".include": checkIncludeFile(line, token.nextIndex); break;
          case ".if": doIf(line, token, depth_); break;
          case ".let": parseLet(line, token.nextIndex); break;
          case ".macro": buildMacro(line, token.nextIndex); break;
          case ".switch": doSwitch(line, token, depth_); break;
          case ".repeat": doRepeat(depth_); break;
          case "/*": processInput(depth_+1, ParseState.Multiline_Comment_Entry); break;
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
          case "/*": processInput(depth_+1, ParseState.Multiline_Comment_Entry); break;
          default: skip = checkMacros(token.string, line, token.nextIndex); break;
        }
        break;
      
      case If_False: // if statement false
        switch(token.string){
          case ".if": curDepth++; break;
          case ".elseif": if(curDepth == depth_){ state = checkElseIf(line, token); } break;
          case ".else": if(curDepth == depth_){ state = ParseState.If_True; } break;
          case ".endif": curDepth--; if(curDepth < depth_){ return; } break;
          case "/*": processInput(depth_+1, ParseState.Multiline_Comment_Entry); break;
          default: break;
        }
        break;
      
      case If_Skip: // skip all until .endif
        switch(token.string){
          case ".if": curDepth++; break;
          case ".endif": curDepth--; if(curDepth < depth_){ return; } break;
          case "/*": processInput(depth_+1, ParseState.Multiline_Comment_Entry); break;
          default: break;
        }
        break;
      
      case Switch_Look: // scan through lines looking for .case or .default
        switch(token.string){
          case ".case": state = checkCase(line, token, state); break;
          case ".default": state = ParseState.Switch_Taken; break;
          case ".endsw": popSwitchArg(); return;
          case "/*": processInput(depth_+1, ParseState.Multiline_Comment_Entry); break;
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
          //case ".case": case ".default": break;
          case ".break": state = ParseState.Switch_Skip; break;
          case ".endsw": popSwitchArg(); return;
          case ".repeat": doRepeat(depth_); break;
          case "/*": processInput(depth_+1, ParseState.Multiline_Comment_Entry); break;
          default: skip = checkMacros(token.string, line, token.nextIndex); break;
        }
        break;
        
      case Switch_Skip: // skip all lines until .endsw is found
        switch(token.string){
          case ".switch": curDepth++; break;
          case ".endsw": curDepth--; if(curDepth < depth_){ popSwitchArg(); return; } break;
          case "/*": processInput(depth_+1, ParseState.Multiline_Comment_Entry); break;
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
          case "/*": processInput(depth_+1, ParseState.Multiline_Comment_Entry); break;
          default: skip = checkMacros(token.string, line, token.nextIndex); break;
        }
        break;
      
      case Multiline_Comment_Entry:
        while(token.nextIndex < line.length()){ // handle a multiline comment that exists on a single line
          token = getNextToken(line,token.nextIndex); // get NEXT token FIRST, since on entry we'll still be looking at the "/*"
          switch(token.string){
            case "/*": processInput(depth_+1, ParseState.Multiline_Comment_Entry); break; // nested multiline comments
            case "*/": return; // end of current multiline comment
          }
        }
        state = ParseState.Multiline_Comment; // end of multiline comment was not in same line, so look at following lines
        break;
      
      case Multiline_Comment:
        switch(token.string){
          case "/*": processInput(depth_+1, ParseState.Multiline_Comment_Entry); break; // nested multiline comments
          case "*/": return; // end of current multiline comment
          default: break;
        }
        break;
    }
    
    outputLine(line, skip);
    popFileIfLastLine();
  }
}
