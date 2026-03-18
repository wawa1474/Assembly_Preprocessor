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

TokenReturn getNextToken(String line, int index){
  if(hyperVerboseOutput){ println("getNextToken: \"" + line + "\" @ [" + index + "]"); }
  String token = "";
  int state = 0;
  boolean inString = false;
  boolean gotString = false;
  int parenDepth = 0;
  
  for(; index < line.length() && state != -1; index++){
    char c = line.charAt(index);
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
            if(hyperVerboseOutput){ println("getNextToken:0:cleanEscape"); }
            gotString = true;
            TokenReturn output = cleanEscape(line, index, false);
            index = output.nextIndex;
            token += output.string;
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
            // we would still need to check for escaped objects and handle them, but no other processing would occur on stuff within paren's...
            parenDepth++; // we would need to correctly handle nested paren's too...
            //token += c;
            gotString = true;
            //state = 1;
            //break;
          
          case ')': // perhaps we should also be handling unbalanced paren's too?
            parenDepth--;
            if(parenDepth == 0){
              //state = 0; // what else do we have to handle here?
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
            if(hyperVerboseOutput){ println("getNextToken:1:cleanEscape"); }
            gotString = true;
            TokenReturn output = cleanEscape(line, index, false);
            index = output.nextIndex;
            token += output.string;
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
  
  if(line.length() == 1 && token.equals("")){
    token = line;
    index++;
  }
  
  if(hyperVerboseOutput){ println("getNextToken:output = \"" + token + "\" @ [" + index + "]"); }
  return new TokenReturn(token, index);
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
            //would cut down on amount of stuff in parseFunction()...
            break;
          case '(': // escaped open-paren means we need to do infixToRPN stuff
            // doing infix to RPN conversion and then emitting the result is useful for asm-time forth stuff
            //token += lineToRPN(line, index);
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
            TokenReturn output = cleanEscape(line, index, false);
            index = output.nextIndex;
            token += output.string;
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
