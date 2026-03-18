// TODO: infixToRPN would allow the preprocessor to do some otherwise difficult/impossible things...
// Pulled from an ancient project that I left in a ROUGH state...
//takes infix (normal) notation and converts it to reverse polish notation using a stack
//String testRPN_input = "((123 * (2 + 45) * (2.3 / 5) ^ 0.2 - 1) % 5 * (1 - 5) ^ \\&{token_prec} + \\#{random,10,50})";
String testRPN_input = "((\\#{pow, 123 * (2 + 45) * (2.3 / 5), 0.2} - 1) % 5 * \\#{pow, 1 - 5, \\&{token_prec}} + \\#{random,10,\\&{token_prec}})"; // infix notation to be converted
// 123 2 45 + 2.3 5 / 0.2 ^ * * 1 - 5 1 5 - \\&{token_prec} ^ * % \\#{random,10,50} +

void testRPN(){
  if(_Vars == null){ _Vars = new StringDict(); }
  println("input:" + testRPN_input);
  _Vars.set("token_prec", "" + 1337);
  String testRPN_output = lineToRPN(testRPN_input, 0); // converted output
  println("output:" + testRPN_output);
  printArray(_Vars);
}

int getPrecedenceRPN(char c){
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

class RPNToken{
  char indentifier;
  int precedence;
  
  RPNToken(char n, int p){
    indentifier = n;
    precedence = p;
  }
  
  String toString(){
    return "<" + indentifier + ":" + precedence + ">";
  }
}

class Stack{
  ArrayList<RPNToken> data;
  
  Stack(){
    data = new ArrayList<RPNToken>();
  }
  
  int size(){
    return data.size();
  }
  
  void push(RPNToken value){
    data.add(value);
  }
  
  RPNToken get(int index) {
    if(index >= data.size() || index < 0) {
      return new RPNToken(index < 0 ? '~' : '!', -1); //throw new ArrayIndexOutOfBoundsException(index);
    }
    return data.get(index);
  }

  RPNToken pop(){
    if(data.size() == 0){
      return new RPNToken('#', -1); //throw new RuntimeException("Can't call pop() on an empty list");
    }
    return data.remove(data.size() - 1);
  }
  
  RPNToken peek(){
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

String lineToRPN(String line, int index){
  Stack stack = new Stack();
  int state = 0;
  String output = "";
  int parenDepth = 1; // we start with a depth of 1 due to entering on an escaped open-paren
  boolean isFloat = false; // do we calculate the result as an int or a float?
  
  for(int i = index; i < line.length() && state != -1; i++){
    char c = line.charAt(i);
    //println(i + ":" + c);
    switch(state){
      case 0:
        switch(c){
          case ' ':
            if(output.charAt(output.length() - 1) != ' '){ output += " "; }
            break;
          
          case '(': // '(' temporarily resets the top of stack precedence
            parenDepth++;
            stack.push(new RPNToken(c, -1));
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
          
          case '%': // modulo
            stack.push(new RPNToken('%', -1));
            break;
          
          case '\\': // escaped values, like macro args, global variables, built-in functions, etc.
            TokenReturn tmp = cleanEscape(line, i, 0);
            output += tmp.string;
            i = tmp.nextIndex;
            break; // may want to defer calculating anything within escaped values, unless they do their own infixToRPN work...
          
          default:
            if(isNumber(c)){
              output += c;
            }else if(c == '.'){
              output += c;
              isFloat = true;
            }else{
              if(getPrecedenceRPN(c) > getPrecedenceRPN(stack.peek().indentifier)){
                stack.push(new RPNToken(c, -1));
              }else{
                while(getPrecedenceRPN(c) < getPrecedenceRPN(stack.peek().indentifier)){
                  if(output.charAt(output.length() - 1) != ' '){ output += " "; }
                  output += stack.pop().indentifier;
                }
                stack.push(new RPNToken(c, -1));
              }
            }
            break;
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
