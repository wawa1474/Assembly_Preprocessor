// built-in functions

String parseFunction(String input){
  if(hyperVerboseOutput){ println("parseFunction: " + input); }
  MacroArg[] args = getMacroArgs(input, 0);
  if(hyperVerboseOutput){ print("parseFunction:args = ");printArray(args); }
  //VariableReturn[] argsInt = new VariableReturn[args.length];
  //printArray(args);
  String output = "";
  
  //for(int i = 0; i < args.length; i++){
  //  argsInt[i] = tryInt(args[i]);
  //}
  
  switch(args[0].Name){
    case "strLen":
      output += cleanUnicode(args[1].Name).length();
      break;
    
    case "str":
      output += "\"" + args[1].Name + "\"";
      break;
    
    case "stripStr":
      output = stripStr(args[1].Name); // strip leading and trailing "
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
    
    case "uuid":
      output = getLabelUUID();
      break;
    
    case "label":
      updateVariable(args[1].Name, args[2].Name);
      output = args[2].Name;
      break;
    
    case "arg": // get a macro arg by index
      //println("parseFunction:arg " + args[1].Name + " == " + CurrentMacroArgs[parseVariables(args[1].Name).Integer].Name);
      //print("parseFunction:arg ");
      //printArray(CurrentMacroArgs);
      if(parseVariables(args[1].Name).Integer < CurrentMacroArgs.length){
        //println("[" + parseVariables(args[1].Name).Integer + "] = " + CurrentMacroArgs[parseVariables(args[1].Name).Integer].Name);
        output = CurrentMacroArgs[parseVariables(args[1].Name).Integer].Name;
      }else{
        //println();
        output = "\\!{parseFunction.arg: Index " + parseVariables(args[1].Name).Integer + " out of bounds for length " + CurrentMacroArgs.length + "}";
      }
      break;
    
    //case "args": // get multiple macro args by index using ruby syntax? [1..4,10..8] == [1,2,3,4,10,9,8]
      //break;
    
    case "pushTmp": // save a global var to the stack and set it to a tmp value
      _TmpGlobalVars.put(args[1].Name,_Vars.get(args[1].Name));
      updateVariable(args[1].Name, args[2].Name);
      break;
    
    case "popTmp": // pop a tmp var from the stack early
      updateVariable(args[1].Name, _TmpGlobalVars.get(args[1].Name));
      _TmpGlobalVars.remove(args[1].Name);
      break;
    
    case "checkVer":
      if(args.length < 3){ return "\\!{checkVer: not enough args " + (args.length-1) + "is < 2}"; }
      output = compareVersions(_VERSION, args[1].Name, args[2].Name, args.length > 3 ? args[3].Name : "");
      break;
    
    case "compareVer":
      if(args.length < 4){ return "\\!{compareVer: not enough args " + (args.length-1) + "is < 3}"; }
      output = compareVersions(args[1].Name, args[2].Name, args[3].Name, args.length > 4 ? args[4].Name : "");
      break;
    
    case "debug":
      print("debug output: ");//printArray(args);
      for(int i = 1; i < args.length; i++){
        print(parseVariables(args[i].Name).String);
      }
      println();
      break;
    
    case "formatStr":
      // \#{formatStr, "this is a {0} that {1} to be {2}", string, needs, formatted}
      // \#{formatStr, "this is a {string} that {needs} to be {formatted}"}
      // may need to change how args[] is populated, so that we can know indices...
  }
  
  return output;
}


// built-in functions

String parseStackFunction(String input){
  if(hyperVerboseOutput){ println("parseStackFunction: " + input); }
  MacroArg[] args = getMacroArgs(input, 0);
  if(hyperVerboseOutput){ print("parseStackFunction:args = ");printArray(args); }
  //VariableReturn[] argsInt = new VariableReturn[args.length];
  //printArray(args);
  String output = "";
  
  String sName = args[1].Name;
  if(Stacks.size() <= 0){ // no stacks exist
    if(initEmptyStacks && args[0].Name.equals("push")){ // but we are pushing data
      g_PUSHNEW(args[1].Name, args[2].Name); // so create new stack and append
    }else if(args[0].Name.equals("createStack")){
      g_CREATESTACK(sName);
    }else{
      output = "\\!{parseStackFunction:noStacks, " + sName + "}"; // otherwise output error message
    }
  }else{
    if(Stacks.containsKey(sName)){ // stack exists
      int len = g_DEPTH(sName);
      String tmp1;
      String tmp2; // why yes, my preprocessor will be turing complete...
      String tmp3;
      String tmp4;
      int idx;
      if(len > 0){ // stack has AT LEAST 1 value
        switch(args[0].Name){
          case "push": // ([TOS] - TOS)
            g_PUSH(sName, args[2].Name);//println("parseStackFunction.push: " + sName + " = " + args[2].Name);
            break;
          
          case "pop": // (TOS - [TOS])
            output = g_POP(sName);
            break;
          
          case "TOS":
          case "peek": // (TOS - TOS [TOS])
            output = g_PEEK(sName);
            if(hyperVerboseOutput){ println("parseStackFunction.TOS: " + sName + " = " + output); }
            break;
          
          case "NOS": // (NOS TOS - NOS TOS [NOS])
            output = g_PEEK(sName, 1);
            if(hyperVerboseOutput){ println("parseStackFunction.NOS: " + sName + " = " + output); }
            break;
          
          case "3RD": // (3RD NOS TOS - 3RD NOS TOS [3RD])
            output = g_PEEK(sName, 2);
            break;
          
          case "clear": // (3RD NOS TOS - )
            g_CLEAR(sName);
            break;
          
          case "pushArgs": // ([Macro, Args] - Macro Args)
            for(int i = 0; i < CurrentMacroArgs.length; i++){
              g_PUSH(sName, CurrentMacroArgs[i].Name);
            }
            break;
          
          case "pushRevArgs": // ([Macro, Args] - Args Macro)
            for(int i = CurrentMacroArgs.length - 1; i >= 0; i--){
              g_PUSH(sName, CurrentMacroArgs[i].Name);
            }
            break;
          
          case "pick": // (v1 v2 v3 #2 - v1 v2 v3 v1) [TOS=0, NOS=1, ...]
            idx = parseVariables(g_POP(sName)).Integer;
            len = g_DEPTH(sName);
            if(len > idx){
              g_PUSH(sName, g_PEEK(sName, idx));
            }else{
              output = "\\!{parseStackFunction:pick.underflow, " + sName + "}";
            }
            break;
          
          case "pickF": // (v1 v2 v3 [#2] - v1 v2 v3 v1) [TOS=0, NOS=1, ...]
            idx = parseVariables(args[2].Name).Integer;
            if(len > idx){
              g_PUSH(sName, g_PEEK(sName, idx));
            }else{
              output = "\\!{parseStackFunction:pickF.underflow, " + sName + "}";
            }
            break;
          
          case "pickO": // (v1 v2 v3 #2 - v1 v2 v3 [v1]) [TOS=0, NOS=1, ...]
            idx = parseVariables(g_POP(sName)).Integer;
            len = g_DEPTH(sName);
            if(len > idx){
              output = g_PEEK(sName, idx);
            }else{
              output = "\\!{parseStackFunction:pick.underflow, " + sName + "}";
            }
            break;
          
          case "pickFO": // (v1 v2 v3 [#2] - v1 v2 v3 [v1]) [TOS=0, NOS=1, ...]
            idx = parseVariables(args[2].Name).Integer;
            if(len > idx){
              output = g_PEEK(sName, idx);
            }else{
              output = "\\!{parseStackFunction:pickF.underflow, " + sName + "}";
            }
            break;
          
          case "pluck": // (v1 v2 v3 #2 - v2 v3 v1) [TOS=0, NOS=1, ...]
            idx = parseVariables(g_POP(sName)).Integer;
            len = g_DEPTH(sName);
            if(len > idx){
              g_PUSH(sName, g_PLUCK(sName, idx));
            }else{
              output = "\\!{parseStackFunction:pluck.underflow, " + sName + "}";
            }
            break;
          
          case "pluckF": // (v1 v2 v3 [#2] - v2 v3 v1) [TOS=0, NOS=1, ...]
            idx = parseVariables(args[2].Name).Integer;
            if(len > idx){
              g_PUSH(sName, g_PLUCK(sName, idx));
            }else{
              output = "\\!{parseStackFunction:pluckF.underflow, " + sName + "}";
            }
            break;
          
          case "pluckO": // (v1 v2 v3 #2 - v2 v3 [v1]) [TOS=0, NOS=1, ...]
            idx = parseVariables(g_POP(sName)).Integer;
            len = g_DEPTH(sName);
            if(len > idx){
              output = g_PLUCK(sName, idx);
            }else{
              output = "\\!{parseStackFunction:pluck.underflow, " + sName + "}";
            }
            break;
          
          case "pluckFO": // (v1 v2 v3 [#2] - v2 v3 [v1]) [TOS=0, NOS=1, ...]
            idx = parseVariables(args[2].Name).Integer;
            if(len > idx){
              output = g_PLUCK(sName, idx);
            }else{
              output = "\\!{parseStackFunction:pluckF.underflow, " + sName + "}";
            }
            break;
          
          case "poke": // (v1 v2 v3 v4 #1 - v1 v4 v3) [TOS=0, NOS=1, ...]
            idx = parseVariables(g_POP(sName)).Integer;
            len = g_DEPTH(sName);
            if(len > 0){
              tmp1 = g_POP(sName);
              len = g_DEPTH(sName);
              if(len > idx){
                g_POKE(sName, tmp1, idx);
                break;
              }
            }
            output = "\\!{parseStackFunction:poke.underflow, " + sName + "}";
            break;
          
          case "pokeF": // (v1 v2 v3 [v4 #1] - v1 v4 v3) [TOS=0, NOS=1, ...]
            idx = parseVariables(args[2].Name).Integer;
            if(len > idx){
              g_POKE(sName, args[3].Name, idx);
            }else{
              output = "\\!{parseStackFunction:pokeF.underflow, " + sName + "}";
            }
            break;
          
          case "depth": // (v1 v2 v3 - v1 v2 v3 #3)
            output = str(len);
            break;
          
          case "rot": // (n1 n2 n3 - n2 n3 n1)
            if(len >= 3){
              tmp3 = g_POP(sName);
              tmp2 = g_POP(sName);
              tmp1 = g_POP(sName);
              g_PUSH(sName, tmp2);
              g_PUSH(sName, tmp3);
              g_PUSH(sName, tmp1);
            }else{
              output = "\\!{parseStackFunction:rot.underflow, " + sName + "}";
            }
            break;
          
          case "-rot": // (n1 n2 n3 - n3 n1 n2)
            if(len >= 3){
              tmp3 = g_POP(sName);
              tmp2 = g_POP(sName);
              tmp1 = g_POP(sName);
              g_PUSH(sName, tmp3);
              g_PUSH(sName, tmp1);
              g_PUSH(sName, tmp2);
            }else{
              output = "\\!{parseStackFunction:-rot.underflow, " + sName + "}";
            }
            break;
          
          case "spin": // (n1 n2 n3 - n3 n2 n1)
            if(len >= 3){
              tmp3 = g_POP(sName);
              tmp2 = g_POP(sName);
              tmp1 = g_POP(sName);
              g_PUSH(sName, tmp3);
              g_PUSH(sName, tmp2);
              g_PUSH(sName, tmp1);
            }else{
              output = "\\!{parseStackFunction:spin.underflow, " + sName + "}";
            }
            break;
          
          case "tuck": // (v1 v2 - v2 v1 v2)
            if(len >= 2){
              tmp2 = g_POP(sName);
              tmp1 = g_POP(sName);
              g_PUSH(sName, tmp2);
              g_PUSH(sName, tmp1);
              g_PUSH(sName, tmp2);
            }else{
              output = "\\!{parseStackFunction:tuck.underflow, " + sName + "}";
            }
            break;
          
          case "tuckF": // (v1 v2 - v2 v1 v2)
            if(len >= 2){
              tmp1 = g_POP(sName);
              g_PUSH(sName, args[2].Name);
              g_PUSH(sName, tmp1);
              g_PUSH(sName, args[2].Name);
            }else{
              output = "\\!{parseStackFunction:tuckF.underflow, " + sName + "}";
            }
            break;
          
          case "nip": // (v1 v2 - v2)
            if(len >= 2){
              tmp1 = g_POP(sName);
              g_POP(sName);
              g_PUSH(sName, tmp1);
            }else{
              output = "\\!{parseStackFunction:nip.underflow, " + sName + "}";
            }
            break;
          
          case "under": // (v1 v2 - v1 v1 v2)
            if(len >= 2){
              tmp1 = g_POP(sName);
              g_PUSH(sName, g_PEEK(sName));
              g_PUSH(sName, tmp1);
            }else{
              output = "\\!{parseStackFunction:under.underflow, " + sName + "}";
            }
            break;
          
          case "swap": // (v1 v2 - v2 v1)
            if(len >= 2){
              tmp2 = g_POP(sName);
              tmp1 = g_POP(sName);
              g_PUSH(sName, tmp2);
              g_PUSH(sName, tmp1);
            }else{
              output = "\\!{parseStackFunction:swap.underflow, " + sName + "}";
            }
            break;
          
          case "drop": // (v1 v2 - v1)
            g_POP(sName);
            break;
          
          case "dup": // (v1 - v1 v1)
            g_PUSH(sName, g_PEEK(sName));
            break;
          
          case "over": // (v1 v2 - v1 v2 v1)
            if(len >= 2){
              g_PUSH(sName, g_PEEK(sName, 1));
            }else{
              output = "\\!{parseStackFunction:over.underflow, " + sName + "}";
            }
            break;
          
          case "2swap": // (v1 v2 v3 v4 - v3 v4 v1 v2)
            if(len >= 4){
              tmp4 = g_POP(sName);
              tmp3 = g_POP(sName);
              tmp2 = g_POP(sName);
              tmp1 = g_POP(sName);
              g_PUSH(sName, tmp3);
              g_PUSH(sName, tmp4);
              g_PUSH(sName, tmp1);
              g_PUSH(sName, tmp2);
            }else{
              output = "\\!{parseStackFunction:2swap.underflow, " + sName + "}";
            }
            break;
          
          case "2drop": // (v1 v2 -)
            if(len >= 2){
              g_POP(sName);
              g_POP(sName);
            }else{
              output = "\\!{parseStackFunction:2drop.underflow, " + sName + "}";
            }
            break;
          
          case "2dup": // (v1 v2 - v1 v2 v1 v2)
            if(len >= 2){
              g_PUSH(sName, g_PEEK(sName, 1));
              g_PUSH(sName, g_PEEK(sName, 1));
            }else{
              output = "\\!{parseStackFunction:2dup.underflow, " + sName + "}";
            }
            break;
          
          case "2over": // (v1 v2 v3 v4 - v1 v2 v3 v4 v1 v2)
            if(len >= 4){
              g_PUSH(sName, g_PEEK(sName, 3));
              g_PUSH(sName, g_PEEK(sName, 3));
            }else{
              output = "\\!{parseStackFunction:2over.underflow, " + sName + "}";
            }
            break;
          
          case "1+": // (v1 - v1)
            if(len >= 1){
              g_POKE(sName, str(parseVariables(g_PEEK(sName)).Integer + 1), 0);
            }else{
              output = "\\!{parseStackFunction:1+.underflow, " + sName + "}";
            }
            break;
          
          case "1-": // (v1 - v1)
            if(len >= 1){
              g_POKE(sName, str(parseVariables(g_PEEK(sName)).Integer - 1), 0);
            }else{
              output = "\\!{parseStackFunction:1-.underflow, " + sName + "}";
            }
            break;
        }
      }else{ // stack is empty
        switch(args[0].Name){
          case "push": g_PUSH(sName, args[2].Name); break; // push to top of stack
          case "pushArgs": // ([Macro, Args] - Macro Args)
            for(int i = 0; i < CurrentMacroArgs.length; i++){
              g_PUSH(sName, CurrentMacroArgs[i].Name);
            }
            break;
          case "pushRevArgs": // ([Macro, Args] - Args Macro)
            for(int i = CurrentMacroArgs.length - 1; i >= 0; i--){
              g_PUSH(sName, CurrentMacroArgs[i].Name);
            }
            break;
          case "depth": output = "0"; break; // stack exists but has zero elements
          default: output = "\\!{parseStackFunction:" + args[0].Name + ".underflow, " + sName + "}"; break; // stack underflow error
        }
      }
    }else{ // stack does not exist
      switch(args[0].Name){
        case "createStack": // create a new, empty stack
          g_CREATESTACK(sName);
          break;
        case "push":
          if(initEmptyStacks == true){
            g_PUSHNEW(args[1].Name, args[2].Name); // create new stack and append
            break;
          }
        default: output = "\\!{parseStackFunction:" + args[0].Name + ".doesNotExist, " + sName + "}"; break; // stack does not exist error
      }
    }
  }
  
  return output;
}

String parseFileFunction(String input){
  if(hyperVerboseOutput){ println("parseFileFunction: " + input); }
  MacroArg[] args = getMacroArgs(input, 0);
  if(hyperVerboseOutput){ print("parseFileFunction:args = ");printArray(args); }
  String output = "";
  
  switch(args[0].Name){
    case "create": // create a new output file
    case "open": // open a pre-existing file
    case "close": // close and save a file early (will happen automatically at end of program)
    case "get": // get an entry at index
    case "set": // set an entry at index
    case "clear": // remove all entries
    case "size": // length of file (in lines!)
    case "remove": // remove an entry at index
    case "append": // add entry at end of file
    case "hasValue": // check if a value is a part of the file
    //case "sort": // free function from StringList
    //case "sortReverse": // free function from StringList
    //case "reverse": // free function from StringList
    //case "shuffle": // free function from StringList
    //case "lower": // free function from StringList
    //case "upper": // free function from StringList
  }
  
  return output;
}
