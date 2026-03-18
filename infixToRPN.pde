// TODO: infixToRPN would allow the preprocessor to do some otherwise difficult/impossible things...
// Pulled from an ancient project that I left in a ROUGH state...
//takes infix (normal) notation and converts it to reverse polish notation using a stack
String input = "((123 * (2 + 45) * (2.3 / 5) ^ 0.2 - 1) % 5 * (1 - 5) ^ %%token_prec)"; // infix notation to be converted
// 123 2 45 + 2.3 5 / 0.2 ^ * * 1 - 5 1 5 - %%token_prec ^ * %
String output = ""; // converted output

void setup2(){
  //if(_Vars == null){ _Vars = new StringDict(); }
  //println("input:" + input);
  //_Vars.set("token_prec", "" + 1337);
  //lineToRPN(input, 0);
  //println("output:" + output);
  //printArray(_Vars);
}

int getPrecedence(char c){
  switch(c){
    case '+':
      return 10;
    
    case '-':
      return 10;
    
    case '*':
      return 20;
    
    case '/':
      return 20;
    
    case '%':
      return 20;
    
    case '^':
      return 30;
    
  }
  return 0;
}

class Token{
  char indentifier;
  int precedence;
  
  Token(char n, int p){
    indentifier = n;
    precedence = p;
  }
  
  String toString(){
    return "<" + indentifier + ":" + precedence + ">";
  }
}

class Stack{
  ArrayList<Token> data;
  
  Stack(){
    data = new ArrayList<Token>();
  }
  
  int size(){
    return data.size();
  }
  
  void push(Token value){
    data.add(value);
  }
  
  Token get(int index) {
    if(index >= data.size() || index < 0) {
      return new Token(index < 0 ? '~' : '!', -1); //throw new ArrayIndexOutOfBoundsException(index);
    }
    return data.get(index);
  }

  Token pop(){
    if(data.size() == 0){
      return new Token('#', -1); //throw new RuntimeException("Can't call pop() on an empty list");
    }
    return data.remove(data.size() - 1);
  }
  
  Token peek(){
    return get(data.size() - 1);
  }
  
  String toString(){
    String output_ = "";
    for(int i = 0; i < data.size(); i++){
      output_ += "\n[" + i + "] " + data.get(i);
    }
    return output_;
  }
}

IntList intStack = new IntList();
Stack stack = new Stack();

String lineToRPN(String line, int index){
  int state = 0;
  String token = "";
  boolean isGlobalVar = false;
  int parenDepth = 1; // we start with a depth of 1 due to entering on an escaped open-paren
  
  for(int i = index; i < line.length() && state != -1; i++){
    char c = line.charAt(i);
    //print("{" + c + "}");
    switch(state){
      case 0:
        switch(c){
          case ' ':
            if(output.charAt(output.length() - 1) != ' '){ output += " "; }
            break;
          
          case '(': // '(' temporarily resets the top of stack precedence
            parenDepth++;
            stack.push(new Token(c, -1));
            break;
          
          case ')':
            parenDepth--;
            if(parenDepth == 0){ state = -1; }
            else{
              while(stack.peek().indentifier != '('){
                if(output.charAt(output.length() - 1) != ' '){ output += " "; }
                output += stack.pop().indentifier;
              }
              stack.pop();
            }
            break;
          
          case '%': // mod or var
            isGlobalVar = false;
            state = 1;
            break;
          
          default:
            if(isNumber(c) || c == '.'){
              output += c;
            }else{
              if(getPrecedence(c) > getPrecedence(stack.peek().indentifier)){
                stack.push(new Token(c, -1));
              }else{
                while(getPrecedence(c) < getPrecedence(stack.peek().indentifier)){
                  if(output.charAt(output.length() - 1) != ' '){ output += " "; }
                  output += stack.pop().indentifier;
                }
                stack.push(new Token(c, -1));
              }
            }
            break;
        }
        break;
      
      case 1:
        switch(c){
          case '%': // global variable
            isGlobalVar = true;
            state = 2;
            break;
          
          case ' ': // mod
            stack.push(new Token('%', -1));
            state = 0;
            break;
          
          default: // macro argument
            i--;
            state = 2;
            break;
        }
        break;
      
      case 2:
        if(isAlpha(c) || isNumber(c) || c == '_'){
          token += c;
        }else{
          output += tryInt(getVariable(token, isGlobalVar, 0));
          token = "";
          i--;
          state = 0;
        }
        break;
    }
    //println("[" + i + "] " + output + " : stack == " + stack);
  }
  //println("stack == " + stack);
  while(stack.size() > 0){
    output += " " + stack.pop().indentifier;
  }
  
  return output;
}
