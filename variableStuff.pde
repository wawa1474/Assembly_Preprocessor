enum VariableType{
  Integer,
  Float, // might need to be converted to hex format for some assemblers
  String,
  Char, // to be used for character arithmetic (sbc 'A' - '0')
  Byte, // for db (Define Byte)
  Word, // for dw (Define Word)
  RWord, // for drw (Define Reverse Word)
  Argument, // macro argument
  Variable, // global variable
  Function, // built-in function
  StackFunction, // stack function
  Builtin, // built-in variables
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
  switch(action){
    case "++":
      updateVariable(variable, str(parseVariables(_Vars.hasKey(variable) ? _Vars.get(variable) : "0").Integer + 1));
      return;
    
    case "--":
      updateVariable(variable, str(parseVariables(_Vars.hasKey(variable) ? _Vars.get(variable) : "0").Integer - 1));
      return;
  }
  
  VariableReturn firstVar = parseVariables(_Vars.hasKey(variable) ? _Vars.get(variable) : "0");
  VariableReturn secondVar = parseVariables(secondToken.string);
  if(hyperVerboseOutput){ println("parseLet: [" + variable + "](" + firstVar + ") " + action + " [" + secondToken.string + "](" + secondVar + ")"); }
  
  if(firstVar.Number && secondVar.Number){
    switch(firstVar.Type){
      case Integer:
        switch(secondVar.Type){
          case Integer: updateVariable(variable, "" + parseLet(firstVar.Integer, action, secondVar.Integer)); break;
          case Float: updateVariable(variable, "" + parseLet(firstVar.Integer, action, secondVar.Float)); break;
          default: break;
        }
        break;
      case Float:
        switch(secondVar.Type){
          case Integer: updateVariable(variable, "" + parseLet(firstVar.Float, action, secondVar.Integer)); break;
          case Float: updateVariable(variable, "" + parseLet(firstVar.Float, action, secondVar.Float)); break;
          default: break;
        }
        break;
      default: break;
    }
  }else{
    switch(action){
      case "+":
        if(_Vars.hasKey(variable)){ updateVariable(variable, _Vars.get(variable) + secondVar.String); }
        else{ updateVariable(variable, secondVar.String); }
        break;
      
      case "-":
        if(_Vars.hasKey(variable)){ updateVariable(variable, _Vars.get(variable).replace(secondVar.String, "")); }
        break;
      
      case "=":
        updateVariable(variable, secondVar.String);
        break;
    }
  }
}

void updateVariable(String var_, String value_){
  _Vars.set(var_, value_);
  
  if(var_.startsWith("__")){
    value_ = stripStr(value_); // strip leading and trailing "
    switch(var_){
      case "__ext_db": ext_db = value_; break;
      case "__ext_db_wrapStart": ext_db_wrapStart = value_; break;
      case "__ext_db_wrapEnd": ext_db_wrapEnd = value_; break;
      case "__ext_dw": ext_dw = value_; break;
      case "__ext_dw_wrapStart": ext_dw_wrapStart = value_; break;
      case "__ext_dw_wrapEnd": ext_dw_wrapEnd = value_; break;
      case "__ext_drw": ext_drw = value_; break;
      case "__ext_drw_wrapStart": ext_drw_wrapStart = value_; break;
      case "__ext_drw_wrapEnd": ext_drw_wrapEnd = value_; break;
      
      default:
        boolean valueBool = false;
    
        switch(value_.toLowerCase()){
          case "true": valueBool = true; break;
          case "false": break;
          default: return;
        }
        
        switch(var_){ // update directive variables
          case "__maintainComments": maintainComments = valueBool; break;
          case "__showLines": showLines = valueBool; break;
          case "__concatenateFiles": concatenateFiles = valueBool; break;
          case "__hyperVerboseOutput": hyperVerboseOutput = valueBool; break;
          case "__initEmptyStacks": initEmptyStacks = valueBool; break;
        }
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

//String getGlobalVariable(String name, boolean checkMacroArgs);
//String getMacroArgument(String name, boolean checkGlobalVars);

String getVariable(String name, boolean global){
  //println("getVariable: " + name + ", " + global);
  //println(getIndex());
  if(global && _Vars != null && _Vars.hasKey(name)){
    return _Vars.get(name);
  }else if(!global){
    MacroArg[] lineMacroArgs = CurrentMacroArgs;
    //print("lineMacroArgs: ");printArray(lineMacroArgs);
    if(lineMacroArgs != null && CurrentWorker.Macro != null){
      MacroArg[] curMacro = CurrentWorker.Macro.Args;
      //print("curMacro: ");print("<" + curMacro.length + ">");printArray(curMacro);
      for(int a = 0; a < curMacro.length; a++){
        // if(name is number)
        //   return curMacro[name.integer];
        //   // this would give us the ability to handle an unknown-at-asm-time amount of macro args
        //   // allowing us to pass an 'unlimited' amount of args to a macro, and then handle it in a loop
        //   // would the proper term be function overloading? even though its a macro?
        //   // might be easier to have a #function to get macro args by index rather than complicate getVariable()...
        // else if...
        if(curMacro[a].Name.equals(name)){
          if(a >= lineMacroArgs.length || lineMacroArgs[a].Name.length() == 0){ // ["this","is","a"], ["this","","","token"]
            if(curMacro[a].Value != null){ return curMacro[a].Value; }
            else{ return "\\!{macro arg '" + name + "' does not have a default value!}"; }
          }else{
            return parseVariables(lineMacroArgs[a].Name).toString();
          }
        }
      }
    }
  }
  
  return "\\!{getVariable:unknown_" + (global ? "var" : "arg") + ", " + name + "}";
}

String getBuiltin(String name){
  switch(name){
    case "@": return str(getIndex()); // get current file index
    case "*": return str(_output.size() + 1); // get total output line count
    case "filename": return CurrentWorker.File.file.Name; // get current file name
    case "argc": return str(CurrentMacroArgs.length); // how many args does this macro instance have?
    case "versionMajor": return _version_major; // allow getting the version of the program
    case "versionMinor": return _version_minor; // allow getting the version of the program
    case "versionPatch": return _version_patch; // allow getting the version of the program
    case "versionRC": return _version_preRelease; // allow getting the version of the program
    case "version": return _VERSION; // allow getting the version of the program
  }
  
  return "\\!{getBuiltin:unknown_var, " + name + "}";
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

VariableReturn parseVariables(String line){ // going through entire line to convert remaining bits into final output
  if(hyperVerboseOutput){ println("parseVariables: " + line); }
  String value = "";
  
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    
    switch(c){
      case '\\':
        if(hyperVerboseOutput){ println("parseVariables:cleanEscape"); }
        TokenReturn output = cleanEscape(line, i, true);
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
