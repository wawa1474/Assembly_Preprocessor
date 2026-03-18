// built-in functions

String parseFunction(String input){
  //println("parseFunction: " + input);
  String[] args = getMacroArgs(input, 0);
//VariableReturn[] argsInt = new VariableReturn[args.length];
  //printArray(args);
  String output = "";
  
  //for(int i = 0; i < args.length; i++){
  //  argsInt[i] = tryInt(args[i]);
  //}
  
  switch(args[0]){
    case "strlen":
      output += args[1].length();
      break;
    
    case "random":
      VariableReturn min = tryInt(args[1]);
      VariableReturn max = tryInt(args[2]);
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
    
    case "goto":
      setIndex(tryInt(args[1]).Integer);
      break;
    
    case "toInt":
      min = tryInt(args[1]);
      switch(min.Type){
        case Integer: output += min.Integer; break;
        case Float: output += min.Float; break;
        default: output += "\\!{toInt, input has NAN type}"; break;
      }
      break;
  }
  
  return output;
}
