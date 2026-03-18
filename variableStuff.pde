enum VariableType{
  Integer,
  Float, // might need to be converted to hex format for some assemblers
  String,
  Char, // to be used for character arithmetic (sbc 'A' - '0')
  Argument, // macro argument
  Variable, // global variable
  Function, // built-in function
  Error, // error output
}

class VariableReturn{
  VariableType Type;
  String String;
  int Integer;
  float Float;
  char Char;
  boolean Number;
  int nextIndex;
  
  VariableReturn(String s){
    String = s;
    Type = VariableType.String;
  }
  
  VariableReturn(String s, int i){
    String = s;
    Integer = i;
    Number = true;
    Type = VariableType.Integer;
  }
  
  VariableReturn(String s, float f){
    String = s;
    Float = f;
    Number = true;
    Type = VariableType.Float;
  }
  
  VariableReturn(String s, VariableType t){
    String = s;
    Type = t;
  }
  
  VariableReturn(String s, int n, VariableType t){
    String = s;
    nextIndex = n;
    Type = t;
  }
  
  String getNumber(){
    switch(Type){
      case Integer: return "" + Integer;
      case Float: return "" + Float;
      default: return "0";
    }
  }
  
  String type(){
    switch(Type){
      case Integer: return "Integer";
      case Float: return "Float";
      case Argument: return "Argument";
      case Variable: return "Variable";
      case Function: return "Function";
      case Error: return "Error";
      case String:  return "String";
      case Char:  return "Char";
      default: return "Unkown";
    }
  }
  
  String toString(){
    switch(Type){
      case Integer: return "" + Integer;
      case Float: return "" + Float;
      case Argument:
      case Variable:
      case Function:
      case Error:
      case String: return String;
      default: return "";
    }
  }
}

void parseLet(String line, int index){
  TokenReturn variable = getNextToken(line, index);
  TokenReturn action = getNextToken(line, variable.nextIndex);
  TokenReturn value = getNextToken(line, action.nextIndex);
  
  parseLet(variable.string, action.string, value);
}

void parseLet(String variable, String action, TokenReturn secondToken){
  VariableReturn firstVar = parseVariables(_Vars.hasKey(variable) ? _Vars.get(variable) : "0", 0);
  VariableReturn secondVar = parseVariables(secondToken.string, 0);
  //println("parseLet: [" + variable + "](" + firstVar + ") " + action + " [" + secondToken.string + "](" + secondVar + ")");
  
  if(firstVar.Number && secondVar.Number){
    switch(firstVar.Type){
      case Integer:
        switch(secondVar.Type){
          case Integer: _Vars.set(variable, "" + parseLet(firstVar.Integer, action, secondVar.Integer)); break;
          case Float: _Vars.set(variable, "" + parseLet(firstVar.Integer, action, secondVar.Float)); break;
          default: break;
        }
        break;
      case Float:
        switch(secondVar.Type){
          case Integer: _Vars.set(variable, "" + parseLet(firstVar.Float, action, secondVar.Integer)); break;
          case Float: _Vars.set(variable, "" + parseLet(firstVar.Float, action, secondVar.Float)); break;
          default: break;
        }
        break;
      default: break;
    }
  }else{
    switch(action){
      case "+":
        if(_Vars.hasKey(variable)){ _Vars.set(variable, _Vars.get(variable) + secondVar.String); }
        break;
      
      case "-":
        if(_Vars.hasKey(variable)){ _Vars.set(variable, _Vars.get(variable).replace(secondVar.String, "")); }
        break;
      
      case "=":
        _Vars.set(variable, secondVar.String);
        break;
    }
  }
}

// TODO: would it make more sense for parseLet to handle int/float stuff and return a VariableReturn?
int parseLet(int firstVar, String action, int secondVar){
  switch(action){
    case "+=":
      return firstVar + secondVar; // check if integers are equal
    
    case "-=":
      return firstVar - secondVar;
    
    case "*=":
      return firstVar * secondVar;
    
    case "/=":
      return firstVar / secondVar;
    
    case "%=":
      return firstVar % secondVar;
    
    case "&=":
      return firstVar & secondVar;
    
    case "|=":
      return firstVar | secondVar;
    
    case "^=":
      return firstVar ^ secondVar;
    
    default:
      return secondVar;
  }
}

float parseLet(float firstVar, String action, float secondVar){
  switch(action){
    case "+=":
      return firstVar + secondVar; // check if integers are equal
    
    case "-=":
      return firstVar - secondVar;
    
    case "*=":
      return firstVar * secondVar;
    
    case "/=":
      return firstVar / secondVar;
    
    case "%=":
      return firstVar % secondVar;
    
    default:
      return secondVar;
  }
}

// TODO: add a depth input + make peekMacroArgs honor that to make macro args resursive...
String getVariable(String name, boolean global, int depth){
  //println("getVariable: " + name + ", " + global);
  if(global && _Vars != null && _Vars.hasKey(name)){
    return _Vars.get(name);
  }else if(!global){
    String[] lineMacroArgs = peekMacroArgs(depth);
    if(lineMacroArgs != null){
      FileHolder curMacro = getFile();
      //printArray(curMacro.file.PathArray);
      for(int a = 0; a < curMacro.file.PathArray.length; a++){
        String[] def = curMacro.file.PathArray[a].split("=");
        if(def[0].equals(name)){
          if(a >= lineMacroArgs.length || lineMacroArgs[a].length() == 0){ // ["this","is","a"], ["this","","","token"]
            if(def.length > 1){ return def[1]; }
            else{ return "\\!{macro arg '" + name + "' does not have a default value!}"; }
          }else{
            if(lineMacroArgs[a].contains("%")){ return parseVariables(lineMacroArgs[a], depth+1).toString(); }
            else{ return parseVariables(lineMacroArgs[a], depth).toString(); }
          }
        }
      }
    }
  }
  
  switch(name){ // last chance to find var in predefined
    case "@": // get current file index
      return "" + getIndex();
  }
  
  return "\\!{unknown arg/var '" + name + "'}";
}

/*
  %identifier = macro argument
  %%id = global variable
  %?id = drop '?' and pass un-parsed "%id" onwards (allows deferring var parsing through several macros or assignments)
  %??id = drop one '?' and pass "%?id"
  %#id = drop leading "%#" and padd "id" (allows building macros with macros)
  %?#id = drop '?' and pass "%#id"
  
  change syntax? to \%{identifier} or? \%identifier%
    allows picking out stuff from anywhere in the code (strings, labels, args, etc.)
    and allows adding extra stuff \%{passCount, identifier}
    maybe seperate symbol per type? (\% = macro arg, \& = global var, \# = built-in function)
      macro arg would be \%{identifier} or? \%identifier%
      global var would be \&{identifier} or? \&identifier&
      built-in functions syntax could be \#{func, (arg, arg2)} or? \#func{arg1, arg2} or? \#func{arg1, arg2}#
      using {} grabs attention better...
*/

//VariableReturn parseVariables(String line, int depth){ // just checking if input is int
//  if(line.length() > 0){
//    VariableReturn tmp = tryInt(line);
//    if(tmp.Number){ return tmp; }
//  }
  
//  return new VariableReturn(line);
//}

// only? needed by outputLine(String line, boolean skip)
VariableReturn parseVariables(String line, int depth){ // going through entire line to convert remaining bits into final output
  //println("parseVariables: " + line);
  String value = "";
  
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    
    switch(c){
      case '\\':
        TokenReturn output = cleanEscape(line, i, depth);
        i = output.nextIndex;
        value += output.string;
        break;
      
      default:
        value += c;
        break;
    }
  }
  
  if(value.length() > 0){
    VariableReturn tmp = tryInt(value);
    if(tmp.Number){ return tmp; }
  }
  
  return new VariableReturn(value);
}
