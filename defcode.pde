enum TokenType{
  Null,
  External, // assembly things that the preprocessor doesn't deal with
  Argument, // macro argument used within macro definition
  Label, // label used within macro definition
  Variable, // variable used within macro definition
  Include, // include used within macro definition
  Let, // let variable be value used within macro definition
}

Token[] listToArray(ArrayList<Token> list){
  Token[] out = new Token[list.size()];
  
  for(int i = 0; i < out.length; i++){ // Token t : list
    out[i] = list.get(i);
  }
  
  return out;
}

void buildMacro(String[] file){
  int state = 0;
  Macro tmpM = null;
  StringList tmpSL = new StringList();
  String tmpS = "";
  ArrayList<Token> tmpTL = new ArrayList<Token>();
  for(int i = 0; i < file.length; i++){
    TokenReturn tokRet = getNextToken(file[i],0,true);
    boolean stop = false;
    while(!stop){
      if(tokRet.string != null){
        //print("{" + token.Token + "} @ " + token.nextIndex);
        switch(state){
          case 0:
            switch(tokRet.string){
              case ".macro":
                tmpM = new Macro();
                state = 1;
                break;
              case ".let":
                state = 10;
                break;
              case ";":
                stop = true;
                break;
            }
            break;
          
          case 1:
            if(tmpM != null){ tmpM.name = tokRet.string; }
            state = 2;
            break;
          
          case 2:
            if(tokRet.string.equals(";")){
              stop = true;
            }else{
              tokRet.string = tokRet.string.replace(",","");
              //println("{[{[" + tokRet.string + "}]}]");
              tmpSL.append(tokRet.string);
            }
            break;
          
          case 3:
            if(tokRet.string.equals(";")){
              stop = true;
            }else if(tokRet.string.equals(".endm")){
              if(tmpM != null){ tmpM.Tokens = listToArray(tmpTL); }
              _Macros.add(cleanMacro(tmpM)); // 
              tmpM = null;
              tmpTL.clear();
              state = 0;
            }else{
              //println("buildMacro{" + tokRet.string + "}");
              tmpTL.add(new Token(tokRet.string));
              state = 3;
            }
            break;
          
          case 10:
            tmpS = tokRet.string;
            state = 11;
            break;
          
          case 11:
            _Vars.set(tmpS, tokRet.string);
            state = 0;
            break;
        }
        //print("{" + tokRet.string + "} ");
      }
      
      tokRet = getNextToken(file[i],tokRet.nextIndex);
      if(tokRet.nextIndex >= file[i].length() && tokRet.string.equals("")){
        stop = true; break;
      }
    }
    if(state == 2 && tmpM != null){
      tmpM.args = tmpSL.toArray();
      tmpSL.clear();
      state = 3;
    }else if(state == 3){
      tmpTL.add(new Token("\\n"));
    }
    //print("{" + token.Token + "} ");
    //println();
    //println("{" + token.Token + "} " + file[i]);
  }
}

String[] parseMacro(Macro macro, String line){
  StringList output = new StringList();
  String cur = "";
  
  //output.append(";" + line);
  
  String[] args = getMacroArgs(line);
  
  for(int i = 0; i < macro.Tokens.length; i++){
    //println(macro.Tokens[i]);
    //cur += macro.Tokens[i];
    Token t = macro.Tokens[i];
    switch(t.Type){
      case External:
        switch(t.Str){
          case "\\n":
            output.append(cur);
            cur = "";
            break;
          case "\\t":
            cur += "\t";
            break;
          default:
            if(t.Str.contains("\\")){
              cur += cleanEscape(t.Str);
            }else{
              cur += t.Str + " ";
            }
            break;
        }
        break;
      case Argument:
        //printArray(macro.Arguments);
        //printArray(args);
        for(int a = 0; a < macro.Arguments.length; a++){
          if(macro.Arguments[a].name.equals(t.Value)){
            //println("{[{[" + t.Str + "}]}]");
            if(a >= args.length){
              cur += macro.Arguments[a].defualt;
            }else{
              if(args[a].contains("\\")){
                cur += t.Str.replace("%", cleanEscape(args[a]));
              }else{
                cur += t.Str.replace("%", args[a]);
              }
              //cur += t.Str.replace("%", args[a]);
            }
            break;
          }
        }
        //println("failed to find arg: " + t.Value);
        break;
      case Label:
        break;
      case Variable:
        cur += t.Str.replace("%", _Vars.get(t.Value));
        break;
      case Include:
        break;
      case Let: // TODO: .let needs to handle variables and arguments!
        //println("var {" + t.Variable + "} and {" + t.Str.replace("%", t.Value) + "}");
        //cur += ";.let " + t.Variable + " " + t.Str.replace("%", t.Value);
        String v = _Vars.get(t.Value);
        if(v != null){
          //println("set var {" + t.Variable + "} to {" + t.Value + "}");
          _Vars.set(t.Variable, t.Str.replace("%", t.Value));
        }else{
          for(int a = 0; a < macro.Arguments.length; a++){
            if(macro.Arguments[a].name.equals(t.Value)){
              //println("set var {" + t.Str + "} to {" + args[a] + "}");
              _Vars.set(t.Variable, t.Str.replace("%", args[a]));
              break;
            }
          }
        }
        break;
      default:
        break;
    }
  }
  if(cur.length() > 0){ output.append(cur); }
  
  return output.toArray();
}

Macro cleanMacro(Macro macro){
  Macro output = new Macro(macro.name);
  
  output.Arguments = new Argument[macro.args.length];
  for(int i = 0; i < macro.args.length; i++){
    if(macro.args[i].contains("=")){
      String[] tmp = split(macro.args[i], '=');
      output.Arguments[i] = new Argument(tmp[0], tmp[1]);
    }else{
      output.Arguments[i] = new Argument(macro.args[i], null);
    }
  }
  
  int state = 0;
  ArrayList<Token> tmpTL = new ArrayList<Token>();
  Token tmpT = new Token();
  boolean newline = false;
  for(int i = 0; i < macro.Tokens.length; i++){
    String s = macro.Tokens[i].Str;
    //println("{{{" + s + "}}}");
    boolean push = false;
    switch(state){
      case 0:
        if(s.equals(".let")){
          tmpT.Type = TokenType.Let;
          newline = true;
          state = 1;
        }else if(s.equals("")){
          newline = false;
          state = 0;
        }else if(s.contains("%%")){
          tmpT = parseVariable(s, TokenType.Variable);
          //println("{[{[" + tmpT.Value + "}]}]");
          newline = false;
          push = true;
        }else if(s.contains("%")){
          tmpT = parseVariable(s, TokenType.Argument);
          //println("{[{[" + tmpT.Value + "}]}]");
          newline = false;
          push = true;
        }else{
          tmpT.Type = TokenType.External;
          tmpT.Str = s;
          if(s.equals("\\n")){
            if(!newline){ push = true; }
            newline = true;
          }else{
            newline = false;
            push = true;
          }
          state = 0;
        }
        break;
      
      case 1:
        tmpT.Variable = s;
        state = 2;
        break;
      
      case 2:
        Token tmp = parseVariable(s, TokenType.Let); // TODO: rework parseVariable to work for .let
        tmpT.Str = tmp.Str;
        tmpT.Value = tmp.Value;
        newline = true;
        push = true;
        break;
        
    }
    
    if(push){
      //println("cleanMacro{" + tmpT + "}");
      tmpTL.add(tmpT);
      tmpT = new Token();
      state = 0;
    }
  }
  output.Tokens = listToArray(tmpTL);
  
  return output;
}

boolean isAlpha(char c){
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

boolean isHex(char c){
  return (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

boolean isNumber(char c){
  return c >= '0' && c <= '9';
}

boolean isWhitespace(char c){
  return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

String cleanEscape(String line){
  String output = "";
  int state = 0;
  
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    
    switch(state){
      case 0: // build prefix
        if(c != '\\'){
          output += c;
        }else{
          state = 1;
        }
        break;
      
      case 1: // build value
        if(c == 'u'){
          state = 3;
        }else{
          switch(c){
            case '0': // NULL
              output += "\\u{00}";
              break;
            case 'a': // BELL
              output += "\\u{07}";
              break;
            case 'b': // BACKSPACE
              output += "\\u{08}";
              break;
            case 'e': // ESCAPE SEQUENCE
              output += "\\u{1B}";
              break;
            case 'f': // FORM FEED
              output += "\\u{0C}";
              break;
            case 'n': // NEWLINE
              output += "\\u{0A}";
              break;
            case 'r': // CARRIAGE RETURN
              output += "\\u{0D}";
              break;
            case 't': // TAB
              output += "\\u{09}";
              break;
            case 'v': // VERTICAL TAB
              output += "\\u{0B}";
              break;
            //case 'x': // HEX INPUT
            //  break;
            default:
              output += "\\u{" + hex(c) + "}";
              break;
          }
          state = 0;
        }
        break;
      
      case 3: // start unicode
        if(c == '{'){
          output += "\\u{";
          state = 4;
        }
        break;
      
      case 4: // build unicode
        output += c;
        if(c == '}'){
          state = 0;
        }
        break;
    }
  }
  
  return output;
}

Token parseVariable(String line, TokenType variable){
  String prefix = "";
  String value = "";
  String suffix = "";
  int state = 0;
  
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    
    switch(state){
      case 0: // build prefix
        if(c != '%'){
          prefix += c;
        }else{
          state = 1;
        }
        break;
      
      case 1: // eat extra '%'
        if(c != '%'){
          value += c;
          state = 2;
        }
        break;
      
      case 2: // build value
        if(isAlpha(c) || isNumber(c) || c == '_'){
          value += c;
        }else{
          suffix += c;
          state = 3;
        }
        break;
      
      case 3: // build suffix
        suffix += c;
        break;
    }
  }
  
  //println(line + " =>= " + prefix + "%" + suffix + " : " + value);
  return new Token(variable, prefix + "%" + suffix, value);
}

TokenReturn getNextToken(String line, int index, boolean space){
  if(space == false){ return getNextToken(line, index); }
  
  String firstToken = "";
  int len = line.length();
  if(len > 0 && index < len){
    char c = line.charAt(index);
    while(index < len && isWhitespace(c)){ // eat leading whitespace
      firstToken += c == ' ' ? ' ' : "\\t";
      c = line.charAt(++index);
    }
  }
  //print("getNextToken[" + firstToken + "]");
  return new TokenReturn(firstToken.equals("") ? null : firstToken, index);
}

TokenReturn getNextToken(String line, int index){
  //println("getNextToken from " + line + " @ " + index);
  String firstToken = "";
  int len = line.length();
  if(len == 1){
    firstToken = line;
    index++;
  }else if(len > 0 && index < len){
    char c = line.charAt(index);
    while(index < len && isWhitespace(c)){ // eat leading whitespace
      //println(index + 1);
      c = line.charAt(++index);
    }
    if(index < len){
      c = line.charAt(index++); // get first non-whitespace character
      if(index == len && len == 1){ firstToken += c; } // handle single character line
      while(index < len && !isWhitespace(c)){ // keep adding characters to token until whitespace is encountered
        firstToken += c;
        c = line.charAt(index++);
      }
      if(index == len && len != 1 && !isWhitespace(c)){ firstToken += c; } // handle last character on multi-character line when not followed by whitespace
    }
  }
  //print("getNextToken[" + firstToken + "]");
  return new TokenReturn(firstToken, index);
}

String[] getMacroArgs(String line){
  StringList args = new StringList();
  
  TokenReturn tokRet = getNextToken(line, 0); // eat macro name
  
  boolean stop = false;
  while(!stop){
    tokRet = getNextToken(line,tokRet.nextIndex);
    String tok = tokRet.string;
    if((tokRet.nextIndex >= line.length() && tok.equals("")) || tok.charAt(0) == ';'){
      stop = true;
    }else{
      int lastComma = tok.lastIndexOf(',');
      if(lastComma == tok.length() - 1){
        tok = tok.substring(0,lastComma);
      }
      args.append(tok);
    }
  }
  
  return args.toArray();
}

class TokenReturn{
  String string;
  int nextIndex;
  
  TokenReturn(String t, int n){
    string = t;
    nextIndex = n;
  }
}
