class TokenReturn{
  String string;
  int nextIndex;
  
  TokenReturn(int n){
    nextIndex = n;
  }
  
  TokenReturn(String t, int n){
    string = t;
    nextIndex = n;
  }
  
  String toString(){
    return "[" + nextIndex + "]{" + string + "}";
  }
}

TokenReturn getNextToken(boolean allowEscape){
  if(hyperVerboseOutput){ println("getNextToken: \"" + CurrentLineInput + "\" @ [" + CurrentInputIndex + "]"); }
  String token = "";
  int state = 0;
  boolean inString = false;
  boolean gotString = false;
  int parenDepth = 0;
  
  for(; CurrentInputIndex < CurrentLineInput.length() && state != -1; CurrentInputIndex++){
    char c = CurrentLineInput.charAt(CurrentInputIndex);
    switch(state){
      case 0:
        switch(c){
          case ';': // hit comment, so end of line
            if(!inString){
              if(gotString == false){ // ';' was first char, so return it to caller
                token += c;
              }
              state = -1;
            }
            break;
          
          case '"':
            token += c;
            inString = !inString;
            gotString = true;
            break;
          
          case '\\':
            if(allowEscape == true){
              if(hyperVerboseOutput){ println("getNextToken:0:cleanEscape"); }
              gotString = true;
              TokenReturn output = cleanEscape(CurrentLineInput, CurrentInputIndex, false);
              CurrentInputIndex = output.nextIndex;
              token += output.string;
            }else{
              token += c;
            }
            break;
          
          case ' ':
          case '\t':
            if(inString){
              token += c;
              gotString = true;
            }else{
              state = gotString ? -1 : 0;
            }
            break;
          
          case '(': // do we handle things within paren's as a 'discreet' unit? escaped open-paren are handled by cleanEscape() obviously...
            if(inString){
              token += c;
            }else{
              // we would still need to check for escaped objects and handle them, but no other processing would occur on stuff within paren's...
              parenDepth++; // we would need to correctly handle nested paren's too...
              //token += c;
              gotString = true;
              //state = 1;
            }
            break;
          
          case ')': // perhaps we should also be handling unbalanced paren's too?
            if(inString){
              token += c;
            }else{
              parenDepth--;
              if(parenDepth == 0){
                //state = 0; // what else do we have to handle here?
              }
            }
            break;
          
          default:
            token += c;
            gotString = true;
            break;
        }
        break;
      
      case 1:
        switch(c){
          case '(': // do we handle things within paren's as a 'discreet' unit?
            // we would still need to check for escaped objects and handle them, but no other processing would occur on stuff within paren's...
            parenDepth++; // we would need to correctly handle nested paren's too...
            break;
          
          case '\\': // escaped open-paren are still handled by cleanEscape() obviously...
            if(allowEscape == true){
              if(hyperVerboseOutput){ println("getNextToken:1:cleanEscape"); }
              gotString = true;
              TokenReturn output = cleanEscape(CurrentLineInput, CurrentInputIndex, false);
              CurrentInputIndex = output.nextIndex;
              token += output.string;
            }else{
              token += c;
            }
            break;
          
          case ')':
            parenDepth--;
            if(parenDepth == 0){
              state = 0; // what else do we have to handle here?
            }
            break;
        }
        break;
    }
  }
  
  if(CurrentLineInput.length() == 1 && token.equals("")){
    token = CurrentLineInput;
    CurrentInputIndex++;
  }
  
  if(hyperVerboseOutput){ println("getNextToken:output = \"" + token + "\" @ [" + CurrentInputIndex + "]"); }
  return new TokenReturn(token, CurrentInputIndex);
}

TokenReturn cleanEscape(String line, int index, boolean runFunction){
  //println("[" + line + "]{" + index + "}");
  if(line.length() > 0 && index < line.length() && line.charAt(index) == '\\'){ index++; } // eat the incoming '\\'
  
  String token = "";
  int state = 0;
  VariableType type = VariableType.String;
  boolean outputEscape = true;
  
  for(; index < line.length() && state != -1; index++){
    char c = line.charAt(index);
    //print(c);
    switch(state){
      case 0:
        state = -1; // default is to finish after one character
        switch(c){
          case '0': // NULL or Octal Character (\033)
            state = 5;
            break;
          case 'a': // BELL
            token += "\\u{07}";
            break;
          case 'b': // BACKSPACE
            token += "\\u{08}";
            break;
          case 'e': // ESCAPE SEQUENCE (\e, \x1B, \033, 27, ^[)
            token += "\\u{1B}";
            break;
          case 'f': // FORM FEED
            token += "\\u{0C}";
            break;
          case 'n': // NEWLINE
            token += "\\u{0A}";
            break;
          case 'r': // CARRIAGE RETURN
            token += "\\u{0D}";
            break;
          case 't': // TAB
            token += "\\u{09}";
            break;
          case 'u': // unicode
            token += "\\u";
            state = 1;
            break;
          case 'v': // VERTICAL TAB
            token += "\\u{0B}";
            break;
          case 'x': // Hexadecimal Character (\x1B)
            token += "\\u{";
            state = 3;
            break;
          case '!': // error output
            token += "\\!";
            type = VariableType.Error;
            state = 1;
            break;
          case '#': // built-in function
            outputEscape = false;
            type = VariableType.Function;
            state = 1;
            break;
          case '%': // macro arg
            outputEscape = false;
            type = VariableType.Argument;
            state = 1;
            break;
          case '&': // global var
            outputEscape = false;
            type = VariableType.Variable;
            state = 1;
            break;
          case '$': // built-in var
            outputEscape = false;
            type = VariableType.Builtin;
            state = 1;
            break;
          case '~': // transitory macro variable
            //ArrayList<StringDict> _TmpMacroVars;
            //when a macro is encountered, a new StringDict is pushed to _TmpMacroVars
            //from there, any number of TMVs can be made and used
            //when the macro ends, popFileIfLastLine()? or popMacroArgs()? removes the last StringDict from _TmpMacroVars
            //this allows and endless number of temporary variables that are contained within their own macro instance
            break;
          case '^': // stack operations
            outputEscape = false;
            type = VariableType.StackFunction;
            state = 1;
            break;
          case '>': // file operations
            outputEscape = false;
            type = VariableType.FileFunction;
            state = 1;
            break;
          case '(': // escaped open-paren means we need to do infixToRPN stuff
            // doing infix to RPN conversion and then emitting the result is useful for asm-time forth stuff
            //token += lineToRPN(line, index);
            break;
          case '[': // Ruby Range Syntax (e.g. [1..4] == [1,2,3,4])([1,2,10..13] == [1,2,10,11,12,13])([1..4,10..8] == [1,2,3,4,10,9,8])
            state = 10; // look for first number or ..
            break;
          default:
            token += "\\u{" + hex(c) + "}";
            break;
        }
        break;
      
      case 1: // start unicode
        if(c == '{'){
          if(outputEscape){ token += c; }
          state = 2;
        }
        break;
      
      case 2: // build unicode
        switch(c){
          case '}':
            if(outputEscape){ token += c; }
            state = -1;
            break;
          
          case '\\':
            if((index == line.length() - 1) || (index + 1 < line.length() && (line.charAt(index + 1) == ' ' || line.charAt(index + 1) == ';'))){
              // if \ is the final character on line or the following character is a space or ;
              // then we need to continue onto next line for more stuff, as this is a multi-line thing
              //incIndex();
              //line = getLine();
              //index = 0;
              // not that simple though, as caller may still be using old line...
              // we may have to make line be global?
            }//else{
              TokenReturn output = cleanEscape(line, index, outputEscape); // if we're not stripping escape tokens, then don't do it on recurse
              index = output.nextIndex;
              token += output.string;
            //}
            break;
          
          default:
            token += c;
            break;
        }
        break;
      
      case 3:
        token += c;
        state = 4;
        break;
      
      case 4:
        token += c + "}";
        state = -1;
        break;
      
      case 5:
        if(isOctal(c)){
          token += c;
        }else{
          token = "\\u{" + octalToHex(token) + "}";
          index--;
          state = -1;
        }
        break;
      
      case 10: // look for first number or '..' --- a ']' would be an error (empty range)
      case 11: // look for next number '..' ']' --- split on ',' or ' '
      case 12: // found all sections of range, go through it and produce final output
        token += c;
        if(c == ']'){
          token = "\\!{Ruby Range Syntax is not yet implemented! - [" + token + "}";
          state = -1;
        }
        break;
    }
  }
  
  switch(type){
    case Argument: // macro argument
      //println("cleanEscape:Argument " + token);
      token = getVariable(token, false); // don't check global variables
      break;
    case Variable: // global variable
      token = getVariable(token, true); // don't check macro arguments
      break;
    case Function: // built-in function
      if(hyperVerboseOutput){ println("cleanEscape:parseFunction = " + runFunction); }
      if(runFunction){ // for some reason (bad programming probably...) parseFunction is being called twice for every function
        token = parseFunction(token); // parse function
      }else{
        token = "\\#{" + token + "}"; // re-encase function for future parsing
      }
      break;
    case StackFunction:
      if(hyperVerboseOutput){ println("cleanEscape:parseStackFunction = " + runFunction); }
      if(runFunction){ // same issue as parseFunction!
        token = parseStackFunction(token);
      }else{
        token = "\\^{" + token + "}"; // re-encase function for future parsing
      }
      break;
    case FileFunction:
      if(hyperVerboseOutput){ println("cleanEscape:parseFileFunction = " + runFunction); }
      if(runFunction){ // same issue as parseFunction!
        token = parseFileFunction(token);
      }else{
        token = "\\>{" + token + "}"; // re-encase function for future parsing
      }
    case Builtin: // built-in variable
      token = getBuiltin(token);
      break;
    default:
      // token = token;
      break;
  }
  
  //VariableReturn out = new VariableReturn(token, index-1, type);
  //println(out.type() + ":" + out + ";" + token);
  return new TokenReturn(token, index-1); // token-1 due to increment after use!
}
