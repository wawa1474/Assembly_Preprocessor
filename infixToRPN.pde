// Pulled from a previous project that I left in a ROUGH state...
//takes infix (normal) notation and converts it to reverse polish notation using a stack
//3.4225845989571354105568947375256‬
String input = "\"this is a test\".charAt((123 * (2 + 45) * (2.3 / 5) ^ 0.2 - 1) % 5 * rand(1, 5) ^ token.prec)"; // infix notation to be converted
StringList midway = new StringList();
int midIndex = 0;
int index = 0; // index into input string
final int charNone = 0;
final int charNumber = 1; // was the previous char a number?
final int charAlpha = 2; // was the previous char an alpha?
int prevCharType = charNone;
String output = ""; // converted output
ArrayList<Token> a = new ArrayList<Token>();
Stack stack = new Stack();

void setup2(){
  stringToTokens();
  //tokensToRPN();
  
  printArray(midway);
  index = 0;
  
  stringToRPN();
  
  println("input:" + input);
  println("output:" + output);
}

char getChar(){
  return peekChar(index++);
}

char peekChar(){
  return peekChar(index);
}

char peekChar(int i){
  if(endOfInput(i)){ return 0; }
  return input.charAt(i);
}

boolean endOfInput(){
  return endOfInput(index);
}

boolean endOfInput(int i){
  return i >= input.length();
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

class Stack{
  protected ArrayList<Token> data;
  protected int count;
  
  public Stack(){
    data = new ArrayList<Token>();
  }
  
  public int size(){
    return count;
  }
  
  public void push(Token value){
    data.add(value);
  }
  
  public Token get(int index) {
    if (index >= this.count) {
      throw new ArrayIndexOutOfBoundsException(index);
    }
    return data.get(index);
  }

  public Token pop(){
    if(count == 0){
      throw new RuntimeException("Can't call pop() on an empty list");
    }
    count--;
    return get(count);
  }
}

class Token{
  String name;
  int precedence;
}

IntList intStack = new IntList();

void stringToRPN(){  
  for(int i = 0; i < input.length(); i++){
    char currentChar = getChar();
    switch(currentChar){
      case ' ':
        break;
      
      case '(': // '(' basically temporarily resets the top of stack precedence
        intStack.push(currentChar);
        break;
      
      case ')':
        char stackValue = popStack();
        while(stackValue != '('){
          output += ' '; // a space between operaters
          output += stackValue;
          stackValue = popStack();
        }
        break;
      
      default:
        if(isNumber(currentChar)){
          if(prevCharType == charNumber){
            output += currentChar;
          }else{
            output += ' '; // need a space between different numbers
            output += currentChar;
          }
          prevCharType = charNumber;
        }else if(isAlpha(currentChar)){
          
          prevCharType = charAlpha;
        }else{
          if(getPrecedence(currentChar) > getPrecedence(stackTop())){
            intStack.push(currentChar);
          }else{
            while(getPrecedence(currentChar) < getPrecedence(stackTop())){
              output += ' '; // a space between operaters
              output += popStack();
            }
            intStack.push(currentChar);
          }
          prevCharType = charAlpha;
        }
        break;
    }
  }
  while(intStack.size() != 0){
    output += ' '; // a space between operaters
    output += popStack();
  }
}

char popStack(){
  return (char)intStack.pop();
}

char stackTop(){
  if(intStack.size() > 0){
    return (char)intStack.get(intStack.size() - 1);
  }
  return 0;
}

void stringToTokens(){
  while(!endOfInput()){
    char currentChar = getChar();
    char nextChar = peekChar();
    
    if(currentChar == '.'){ // have to split number.alpha, alpha.number, and alpha.alpha
      if(prevCharType == charAlpha){ // alpha.number and alpha.alpha
        newString('.');
        newString();
      }else{
        if(isAlpha(nextChar)){
          newString('.');
          newString();
        }
      }
    }else if(isNumber(currentChar) || isAlpha(currentChar)){ // have to split number.alpha, alpha.number, and alpha.alpha
      if(prevCharType != charNumber){ newString(); }
      addChar(currentChar);
      prevCharType = charNumber;
    }else if(currentChar == '"' || currentChar == '\''){
      addString(currentChar);
    }else{
      if(currentChar != ' '){
        newString(currentChar);
        prevCharType = charAlpha;
      }
    }
  }
}

void addString(char c){
  char prevChar = 0;
  char currentChar = getChar();
  while(currentChar != c){// && prevChar != '\\'){
    addChar(currentChar);
    currentChar = getChar();
    prevChar = currentChar;
  }
}

void addChar(char c){
  midway.set(midIndex, currentString() + c);
}

void newString(char c){
  if(currentString().length() == 0){
    addChar(c);
    newString();
  }else{
    newString();
    addChar(c);
  }
}

void newString(){
  if(currentString().length() != 0){
    midway.append("");
    midIndex++;
  }
}

String currentString(){
  if(midway.size() == 0){ midway.append(""); }
  return midway.get(midIndex);
}
