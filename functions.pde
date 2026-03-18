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
    case "strlen":
      output += args[1].Name.length();
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
  }
  
  return output;
}
