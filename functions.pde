// built-in functions

String parseFunction(String input){
  println("parseFunction: " + input);
  String[] args = getMacroArgs(input, 0);
  printArray(args);
  String output = "";
  
  switch(args[0]){
    case "strlen":
      output += args[1].length();
      break;
    
    case "random":
      output += (int)random(tryInt(args[1]).Integer, tryInt(args[2]).Integer);
      break;
  }
  
  return output;
}
