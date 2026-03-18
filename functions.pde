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
    
    case "uuid":
      output = getLabelUUID();
      break;
    
    case "label":
      updateVariable(args[1].Name, args[2].Name);
      output = args[2].Name;
      break;
    
    case "arg": // get a macro arg by index
      output = CurrentMacroArgs[tryInt(args[1].Name).Integer].Value;
      break;
    
    case "formatStr":
      // \#{formatStr, "this is a {0} that {1} to be {2}", string, needs, formatted}
      // \#{formatStr, "this is a {string} that {needs} to be {formatted}"}
      // may need to change how args[] is populated, so that we can know indices...
  }
  
  if(output.length() <= 0){
    String sName = args.length >= 2 ? args[1].Name : "";
    if(Stacks.size() <= 0){ // no stacks exist
      if(initEmptyStacks && args[0].Name.equals("push")){ // but we are pushing data
        g_PUSHNEW(args[1].Name, args[2].Name); // so create new stack and append
      }else if(args[0].Name.equals("createStack")){
        g_CREATESTACK(sName);
      }else{
        output = "\\!{parseFunction:stack.noStacks, " + sName + "}"; // otherwise output error message
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
              g_PUSH(sName, args[2].Name);
              break;
            
            case "pop": // (TOS - [TOS])
              output = g_POP(sName);
              break;
            
            case "TOS":
            case "peek": // (TOS - TOS [TOS])
              output = g_PEEK(sName);
              break;
            
            case "NOS":
              output = g_PEEK(sName, 1);
              break;
            
            case "clear": // (TOS - TOS [TOS])
              g_CLEAR(sName);
              break;
            
            case "pick": // (v1 v2 v3 #2 - v1 v2 v3 v1) [TOS=0, NOS=1, ...]
              idx = parseVariables(g_POP(sName)).Integer;
              len = g_DEPTH(sName);
              if(len > idx){
                g_PUSH(sName, g_PEEK(sName, idx));
              }else{
                output = "\\!{parseFunction:stack.pick.underflow, " + sName + "}";
              }
              break;
            
            case "pickF": // (v1 v2 v3 [#2] - v1 v2 v3 v1) [TOS=0, NOS=1, ...]
              idx = parseVariables(args[2].Name).Integer;
              if(len > idx){
                g_PUSH(sName, g_PEEK(sName, idx));
              }else{
                output = "\\!{parseFunction:stack.pickF.underflow, " + sName + "}";
              }
              break;
            
            case "pickO": // (v1 v2 v3 #2 - v1 v2 v3 [v1]) [TOS=0, NOS=1, ...]
              idx = parseVariables(g_POP(sName)).Integer;
              len = g_DEPTH(sName);
              if(len > idx){
                output = g_PEEK(sName, idx);
              }else{
                output = "\\!{parseFunction:stack.pick.underflow, " + sName + "}";
              }
              break;
            
            case "pickFO": // (v1 v2 v3 [#2] - v1 v2 v3 [v1]) [TOS=0, NOS=1, ...]
              idx = parseVariables(args[2].Name).Integer;
              if(len > idx){
                output = g_PEEK(sName, idx);
              }else{
                output = "\\!{parseFunction:stack.pickF.underflow, " + sName + "}";
              }
              break;
            
            case "pluck": // (v1 v2 v3 #2 - v2 v3 v1) [TOS=0, NOS=1, ...]
              idx = parseVariables(g_POP(sName)).Integer;
              len = g_DEPTH(sName);
              if(len > idx){
                g_PUSH(sName, g_PLUCK(sName, idx));
              }else{
                output = "\\!{parseFunction:stack.pluck.underflow, " + sName + "}";
              }
              break;
            
            case "pluckF": // (v1 v2 v3 [#2] - v2 v3 v1) [TOS=0, NOS=1, ...]
              idx = parseVariables(args[2].Name).Integer;
              if(len > idx){
                g_PUSH(sName, g_PLUCK(sName, idx));
              }else{
                output = "\\!{parseFunction:stack.pluckF.underflow, " + sName + "}";
              }
              break;
            
            case "pluckO": // (v1 v2 v3 #2 - v2 v3 [v1]) [TOS=0, NOS=1, ...]
              idx = parseVariables(g_POP(sName)).Integer;
              len = g_DEPTH(sName);
              if(len > idx){
                output = g_PLUCK(sName, idx);
              }else{
                output = "\\!{parseFunction:stack.pluck.underflow, " + sName + "}";
              }
              break;
            
            case "pluckFO": // (v1 v2 v3 [#2] - v2 v3 [v1]) [TOS=0, NOS=1, ...]
              idx = parseVariables(args[2].Name).Integer;
              if(len > idx){
                output = g_PLUCK(sName, idx);
              }else{
                output = "\\!{parseFunction:stack.pluckF.underflow, " + sName + "}";
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
              output = "\\!{parseFunction:stack.poke.underflow, " + sName + "}";
              break;
            
            case "pokeF": // (v1 v2 v3 [v4 #1] - v1 v4 v3) [TOS=0, NOS=1, ...]
              idx = parseVariables(args[2].Name).Integer;
              if(len > idx){
                g_POKE(sName, args[3].Name, idx);
              }else{
                output = "\\!{parseFunction:stack.pokeF.underflow, " + sName + "}";
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
                output = "\\!{parseFunction:stack.rot.underflow, " + sName + "}";
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
                output = "\\!{parseFunction:stack.-rot.underflow, " + sName + "}";
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
                output = "\\!{parseFunction:stack.spin.underflow, " + sName + "}";
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
                output = "\\!{parseFunction:stack.tuck.underflow, " + sName + "}";
              }
              break;
            
            case "tuckF": // (v1 v2 - v2 v1 v2)
              if(len >= 2){
                tmp1 = g_POP(sName);
                g_PUSH(sName, args[2].Name);
                g_PUSH(sName, tmp1);
                g_PUSH(sName, args[2].Name);
              }else{
                output = "\\!{parseFunction:stack.tuckF.underflow, " + sName + "}";
              }
              break;
            
            case "nip": // (v1 v2 - v2)
              if(len >= 2){
                tmp1 = g_POP(sName);
                g_POP(sName);
                g_PUSH(sName, tmp1);
              }else{
                output = "\\!{parseFunction:stack.nip.underflow, " + sName + "}";
              }
              break;
            
            case "under": // (v1 v2 - v1 v1 v2)
              if(len >= 2){
                tmp1 = g_POP(sName);
                g_PUSH(sName, g_PEEK(sName));
                g_PUSH(sName, tmp1);
              }else{
                output = "\\!{parseFunction:stack.under.underflow, " + sName + "}";
              }
              break;
            
            case "swap": // (v1 v2 - v2 v1)
              if(len >= 2){
                tmp2 = g_POP(sName);
                tmp1 = g_POP(sName);
                g_PUSH(sName, tmp2);
                g_PUSH(sName, tmp1);
              }else{
                output = "\\!{parseFunction:stack.swap.underflow, " + sName + "}";
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
                output = "\\!{parseFunction:stack.over.underflow, " + sName + "}";
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
                output = "\\!{parseFunction:stack.2swap.underflow, " + sName + "}";
              }
              break;
            
            case "2drop": // (v1 v2 -)
              if(len >= 2){
                g_POP(sName);
                g_POP(sName);
              }else{
                output = "\\!{parseFunction:stack.2drop.underflow, " + sName + "}";
              }
              break;
            
            case "2dup": // (v1 v2 - v1 v2 v1 v2)
              if(len >= 2){
                g_PUSH(sName, g_PEEK(sName, 1));
                g_PUSH(sName, g_PEEK(sName, 1));
              }else{
                output = "\\!{parseFunction:stack.2dup.underflow, " + sName + "}";
              }
              break;
            
            case "2over": // (v1 v2 v3 v4 - v1 v2 v3 v4 v1 v2)
              if(len >= 4){
                g_PUSH(sName, g_PEEK(sName, 3));
                g_PUSH(sName, g_PEEK(sName, 3));
              }else{
                output = "\\!{parseFunction:stack.2over.underflow, " + sName + "}";
              }
              break;
          }
        }else{ // stack is empty
          switch(args[0].Name){
            case "push": g_PUSH(sName, args[2].Name); break; // push to top of stack
            case "depth": output = "0"; break; // stack exists but has zero elements
            default: output = "\\!{parseFunction:stack." + args[0].Name + ".underflow, " + sName + "}"; break; // stack underflow error
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
          default: output = "\\!{parseFunction:stack." + args[0].Name + ".doesNotExist, " + sName + "}"; break; // stack does not exist error
        }
      }
    }
  }
  
  return output;
}
