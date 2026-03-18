enum TokenType{
  Null,
  External, // assembly things that the preprocessor doesn't deal with
  Argument, // macro argument used within macro definition
  Label, // label used within macro definition
  Variable, // variable used within macro definition
  Include, // include used within macro definition
  Let, // let variable be value used within macro definition
}

class TokenReturn{
  String string;
  int nextIndex;
  
  TokenReturn(String t, int n){
    string = t;
    nextIndex = n;
  }
}

class Token{
  TokenType Type = TokenType.Null;
  String Str;
  String Value;
  String Variable;
  Macro macro;
  
  Token(){}
  
  Token(String s){
    Str = s;
  }
  
  Token(TokenType t){
    Type = t;
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

Token[] listToArray(ArrayList<Token> list){
  Token[] out = new Token[list.size()];
  
  for(int i = 0; i < out.length; i++){ // Token t : list
    out[i] = list.get(i);
  }
  
  return out;
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
