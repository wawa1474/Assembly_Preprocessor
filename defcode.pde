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
        print("{" + tokRet.string + "} ");
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
    println();
    //println("{" + token.Token + "} " + file[i]);
  }
}

String[] parseMacro(Macro macro, String line){
  StringList output = new StringList();
  String cur = "";
  
  for(int i = 0; i < macro.Tokens.length; i++){
    println(macro.Tokens[i]);
    
    if(macro.Tokens[i].Str.equals("\\n")){
      output.append(cur);
      cur = "";
    }else if(macro.Tokens[i].Str.equals("\\t")){
      cur += "\t";
    }else{
      cur += macro.Tokens[i].Str + " ";
    }
  }
  output.append(cur);
  
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
          newline = false;
          state = 1;
        }else if(s.equals("")){
          newline = false;
          state = 0;
        }else if(s.contains("%%")){
          tmpT = parseVariable(s, true);
          newline = false;
          push = true;
        }else if(s.contains("%")){
          tmpT = parseVariable(s, false);
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
        tmpT.Str = s;
        state = 2;
        break;
      
      case 2:
        tmpT.Value = s;
        newline = false;
        push = true;
        break;
        
    }
    
    if(push){
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

Token parseVariable(String line, boolean variable){
  String prefix = "";
  String suffix = "";
  String value = "";
  int index = 0;
  
  char c = line.charAt(index);
  while(c != '%' && index < line.length() - 1){ // get all characters preceding the value
    prefix += c;
    c = line.charAt(++index);
  }
  
  while(c == '%' && index < line.length() - 1){ // eat all '%'
    c = line.charAt(++index);
  }
  
  while((isAlpha(c) || isNumber(c) || c == '_') && index < line.length() - 1){ // get all characters in the value
    value += c;
    c = line.charAt(++index);
  }
  
  while(index < line.length() - 1){ // get all characters after the value
    suffix += c;
    c = line.charAt(++index);
  }
  suffix += c;
  
  return new Token(variable ? TokenType.Variable : TokenType.Argument, prefix + "%" + suffix, value);
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
  //print("[" + firstToken + "]");
  return new TokenReturn(firstToken.equals("") ? null : firstToken, index);
}

TokenReturn getNextToken(String line, int index){
  String firstToken = "";
  int len = line.length();
  if(len > 0 && index < len){
    char c = line.charAt(index);
    while(index < len && isWhitespace(c)){ // eat leading whitespace
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
  //print("[" + firstToken + "]");
  return new TokenReturn(firstToken, index);
}

class TokenReturn{
  String string;
  int nextIndex;
  
  TokenReturn(String t, int n){
    string = t;
    nextIndex = n;
  }
}
