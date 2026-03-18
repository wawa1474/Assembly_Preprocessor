// built-in functions

String parseFunction(String input){
  //println("parseFunction: " + input);
  MacroArg[] args = getMacroArgs(input, 0);
  //printArray(args);
  //VariableReturn[] argsInt = new VariableReturn[args.length];
  //printArray(args);
  String output = "";
  
  //for(int i = 0; i < args.length; i++){
  //  argsInt[i] = tryInt(args[i]);
  //}
  
  switch(args[0].Name){
    case "push": // why yes, my preprocessor is turing complete...
    case "pop":
    case "rot": // (n1 n2 n3 - n2 n3 n1)
    case "-rot": // (n1 n2 n3 - n3 n1 n2)
    case "tuck": // (v1 - v2 v1)
    case "nip": // (v1 v2 - v2)
    case "under": // (v1 v2 - v1 v1 v2)
    case "pick": // (a1 - v1)
    case "swap": // (v1 v2 - v2 v1)
    case "drop": // (v1 v2 - v1)
    case "dup": // (v1 - v1 v1)
    case "over": // (v1 v2 - v1 v2 v1)
    case "2swap": // (v1 v2 v3 v4 - v3 v4 v1 v2)
    case "2drop": // (v1 v2 -)
    case "2dup": // (v1 v2 - v1 v2 v1 v2)
    case "2over": // (v1 v2 v3 v4 - v1 v2 v3 v4 v1 v2)
      break;
    
    case "strlen":
      output += args[1].Name.length();
      break;
    
    case "str":
      output += "\"" + args[1].Name + "\"";
      break;
    
    case "random":
      VariableReturn min = tryInt(args[1].Name);
      VariableReturn max = tryInt(args[2].Name);
      switch(min.Type){
        case Integer:
          switch(max.Type){
            case Integer: output += random(min.Integer, max.Integer); break;
            case Float: output += random(min.Integer, max.Float); break;
            default: output += "\\!{random, max has NAN type}"; break;
          }
          break;
        case Float:
          switch(max.Type){
            case Integer: output += random(min.Float, max.Integer); break;
            case Float: output += random(min.Float, max.Float); break;
            default: output += "\\!{random, max has NAN type}"; break;
          }
          break;
        default: output += "\\!{random, min has NAN type}"; break;
      }
      break;
    
    case "pow":
      VariableReturn base = tryInt(args[1].Name);
      VariableReturn exponent = tryInt(args[2].Name);
      switch(base.Type){
        case Integer:
          switch(exponent.Type){
            case Integer: output += pow(base.Integer, exponent.Integer); break;
            case Float: output += pow(base.Integer, exponent.Float); break;
            default: output += "\\!{pow, exponent has NAN type}"; break;
          }
          break;
        case Float:
          switch(exponent.Type){
            case Integer: output += pow(base.Float, exponent.Integer); break;
            case Float: output += pow(base.Float, exponent.Float); break;
            default: output += "\\!{pow, exponent has NAN type}"; break;
          }
          break;
        default: output += "\\!{pow, base has NAN type}"; break;
      }
      break;
    
    case "goto":
      setIndex(tryInt(args[1].Name).Integer);
      break;
    
    case "toInt":
      min = tryInt(args[1].Name);
      switch(min.Type){
        case Integer: output += min.Integer; break;
        case Float: output += min.Float; break;
        default: output += "\\!{toInt, input has NAN type}"; break;
      }
      break;
    
    case "formatStr":
      // \#{formatStr, "this is a {0} that {1} to be {2}", string, needs, formatted}
      // \#{formatStr, "this is a {string} that {needs} to be {formatted}"}
      // may need to change how args[] is populated, so that we can know indices...
  }
  
  return output;
}
