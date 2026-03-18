boolean isAlpha(char c){
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

boolean isHex(char c){
  return (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

boolean isBinary(char c){
  return (c == '0' || c == '1' || c == '|');
}

boolean isOctal(char c){
  return c >= '0' && c <= '7';
}

boolean isNumber(char c){
  return c >= '0' && c <= '9';
}

boolean isWhitespace(char c){
  return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

String cleanComments(String line){
  String output = "";
  int state = 0;
  boolean inString = false;
  
  for(int i = 0; i < line.length() && state != -1; i++){
    char c = line.charAt(i);
    
    switch(c){
      case '"':
        output += c;
        inString = !inString;
        break;
      
      case ';':
        if(inString){
          output += c;
        }else{
          state = -1;
        }
        break;
      
      default:
        output += c;
        break;
    }
  }
  
  return output;
}

VariableReturn tryInt(String in){
  String output = "";
  int state = 0;
  boolean valid = true;
  
  char c = ' ';
  for(int i = 0; i < in.length(); i++){
    c = in.charAt(i);
    switch(state){
      case 0:
        switch(c){
          case '0':
            state = 1;
            break;
          
          default:
            output += c;
            state = 5;
            break;
        }
        break;
      
      case 1:
        switch(c){
          case 'x': // hexadecimal
            state = 2;
            break;
          
          case 'b': // binary
            state = 3;
            break;
          
          case 'o': // octal
            state = 4;
            break;
          
          default: // decimal
            state = 5;
            break;
        }
        break;
      
      case 2: // hexadecimal
        if(isHex(c)){
          output += c;
        }else{
          valid = false;
          state = -1;
        }
        break;
      
      case 3: // binary
        if(isBinary(c)){
          output += c;
        }else{
          valid = false;
          state = -1;
        }
        break;
      
      case 4: // octal
        if(isOctal(c)){
          output += c;
        }else{
          valid = false;
          state = -1;
        }
        break;
      
      case 5: // decimal
        if(isNumber(c)){
          output += c;
        }else{
          valid = false;
          state = -1;
        }
        break;
    }
  }
  
  switch(state){
    case 5:
      if(!isNumber(c)){
        valid = false;
      }
      break;
  }
  
  int value = 0;
  if(valid){
    switch(state){
      case 2: // hexadecimal
        value = parseInt(output, 16);
        break;
      
      case 3: // binary
        value = parseInt(output, 2);
        break;
      
      case 4: // octal
        value = parseInt(output, 8);
        break;
      
      case 5: // decimal
        value = parseInt(output, 10);
        break;
    }
  }
  
  return new VariableReturn("" + value, value, valid);
}
