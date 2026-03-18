enum TokenType{
  Null,
  External, // assembly things that the preprocessor doesn't deal with
  Argument, // macro argument used within macro definition
  Label, // label used within macro definition
  Variable, // variable used within macro definition
  Include, // include used within macro definition
  Let, // let variable be value used within macro definition
  Newline, // end of line
  Macro,
  EndMacro,
  If,
  ElseIf,
  Else,
  EndIf,
  Comment,
  Number,
}

class TokenReturn{
  String string;
  int nextIndex;
  
  TokenReturn(String t, int n){
    string = t;
    nextIndex = n;
  }
}

enum VarType{
  Null,
  Macro_Arg, // value pulled from macro argument
  Global_Var // value pulled from global variable
}

class Variable{
  VarType type;
  String value;
  
  Variable(){}
  
  Variable(VarType t, String v){
    type = t;
    value = v;
  }
}

class Token2{
  TokenType Type = TokenType.Null;
  String Value;
  int Integer;
  Variable[] Variables;
  int nextIndex;
  
  Token2(){}
  
  Token2(TokenType t, String n){
    Type = t;
    Value = n;
  }
  
  Token2(TokenType t, String n, Variable[] v, int r){
    Type = t;
    Value = n;
    Variables = v;
    nextIndex = r;
  }
  
  Token2(TokenType t, String n, int i, Variable[] v, int r){
    Type = t;
    Value = n;
    Integer = i;
    Variables = v;
    nextIndex = r;
  }
  
  String toString(){
    if(Type == TokenType.Argument || Type == TokenType.Variable){
      //return "{" + Type.name() + "} " + Str.replace("%", Name);
    //if(Type == TokenType.Macro){
    //  return "{Macro} " + macro.argString();
    }else if(Type == TokenType.Let){
      //return "{Let} " + Str + " = " + Name.replace("%", Variable);
    }else{
      //return "{" + Type.name() + "} " + Str;
    }
    return "";
  }
}

class Token{
  TokenType Type = TokenType.Null;
  String Str;
  String Value;
  String Variable;
  Macro macro;
  int nextIndex;
  
  Token(){}
  
  Token(String s){
    Str = s;
  }
  
  Token(TokenType t, String s){
    Type = t;
    Str = s;
  }
  
  Token(TokenType t, String s, String v){
    Type = t;
    Str = s;
    Value = v;
  }
  
  Token(TokenType t, String s, String v, int r){
    Type = t;
    Str = s;
    Value = v;
    nextIndex = r;
  }
  
  String toString(){
    if(Type == TokenType.Argument || Type == TokenType.Variable){
      return "{" + Type.name() + "} " + Str.replace("%", Value);
    //if(Type == TokenType.Macro){
    //  return "{Macro} " + macro.argString();
    }else if(Type == TokenType.Let){
      return "{Let} " + Str + " = " + Value.replace("%", Variable);
    }else{
      return "{" + Type.name() + "} " + Str;
    }
  }
}

Token[] tokenListToArray(ArrayList<Token> list){
  Token[] out = new Token[list.size()];
  
  for(int i = 0; i < out.length; i++){ // Token t : list
    out[i] = list.get(i);
  }
  
  return out;
}

Token2[] token2ListToArray(ArrayList<Token2> list){
  Token2[] out = new Token2[list.size()];
  
  for(int i = 0; i < out.length; i++){ // Token t : list
    out[i] = list.get(i);
  }
  
  return out;
}

TokenReturn getWhitespaceToken(String line, int index){
  String token = "";
  
  for(; index < line.length(); index++){
    char c = line.charAt(index);
    if(isWhitespace(c)){ token += c == ' ' ? ' ' : "\\t"; }
    else{ break; }
  }
  
  return new TokenReturn(token.equals("") ? null : token, index);
}

TokenReturn getNextToken(String line, int index){
  //print("getNextToken from " + line + " @ " + index);
  String token = "";
  int state = 0;
  boolean inString = false;
  boolean gotString = false;
  
  for(; index < line.length() && state != -1; index++){
    char c = line.charAt(index);
    switch(state){
      case 0:
        switch(c){
          case '"':
            token += c;
            inString = !inString;
            gotString = true;
            break;
          
          case '\\':
            gotString = true;
            state = 2;
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
          
          default:
            token += c;
            gotString = true;
            break;
        }
        break;
      
      case 2: // build value
        if(c == 'u'){
          state = 3;
        }else{
          switch(c){
            case '0': // NULL
              token += "\\u{00}";
              break;
            case 'a': // BELL
              token += "\\u{07}";
              break;
            case 'b': // BACKSPACE
              token += "\\u{08}";
              break;
            case 'e': // ESCAPE SEQUENCE
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
            case 'v': // VERTICAL TAB
              token += "\\u{0B}";
              break;
            //case 'x': // HEX INPUT
            //  break;
            default:
              token += "\\u{" + hex(c) + "}";
              break;
          }
          state = 0;
        }
        break;
      
      case 3: // start unicode
        if(c == '{'){
          token += "\\u{";
          state = 4;
        }
        break;
      
      case 4: // build unicode
        token += c;
        if(c == '}'){
          state = 0;
        }
        break;
    }
  }
  
  if(line.length() == 1 && token.equals("")){
    token = line;
    index++;
  }
  
  //println(" got " + token);
  return new TokenReturn(token, index);
}
