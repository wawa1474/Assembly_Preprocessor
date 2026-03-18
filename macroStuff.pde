class Macro{
  String name;
  String[] args;
  String[] output;
  Argument[] Arguments;
  Token[] Tokens;
  
  Macro(){}
  
  Macro(String n){
    name = n;
  }
  
  Macro(String n, String[] o){
    name = n;
    output = o;
  }
  
  Macro(String n, Token[] t){
    name = n;
    Tokens = t;
  }
  
  Macro(String n, String[] a, Token[] t){
    name = n;
    args = a;
    Tokens = t;
  }
  
  String argString(){
    String tmp = name + ": [" + args.length + "] " + args[0];
    for(int i = 1; i < args.length; i++){
      tmp += ", " + args[i];
    }
    return tmp;
  }
}

class Argument{
  String name;
  String defualt;
  
  Argument(){}
  
  Argument(String n, String d){
    name = n;
    defualt = d;
  }
  
  String toString(){
    return "{" + name + "} = {" + defualt + "}";
  }
}

String[] getMacroArgs(String line){
  StringList args = new StringList();
  
  TokenReturn tokRet = getNextToken(line, 0); // eat macro name
  
  boolean stop = false;
  while(!stop){
    tokRet = getNextToken(line,tokRet.nextIndex);
    String tok = tokRet.string;
    if((tokRet.nextIndex >= line.length() && tok.equals("")) || tok.charAt(0) == ';'){
      stop = true;
    }else{
      int lastComma = tok.lastIndexOf(',');
      if(lastComma == tok.length() - 1){
        tok = tok.substring(0,lastComma);
      }
      args.append(tok);
    }
  }
  
  return args.toArray();
}

void buildMacro(String[] file){
  int state = 0;
  Macro tmpM = null;
  StringList tmpSL = new StringList();
  String tmpS = "";
  ArrayList<Token> tmpTL = new ArrayList<Token>();
  for(int i = 0; i < file.length; i++){
    TokenReturn tokRet = getNextToken(file[i],0,true);
    boolean stop = false;
    while(!stop){
      if(tokRet.string != null){
        //print("{" + token.Token + "} @ " + token.nextIndex);
        switch(state){
          case 0:
            switch(tokRet.string){
              case ".macro":
                tmpM = new Macro();
                state = 1;
                break;
              case ".let":
                state = 10;
                break;
              case ";":
                stop = true;
                break;
            }
            break;
          
          case 1:
            if(tmpM != null){ tmpM.name = tokRet.string; }
            state = 2;
            break;
          
          case 2:
            if(tokRet.string.equals(";")){
              stop = true;
            }else{
              tokRet.string = tokRet.string.replace(",","");
              //println("{[{[" + tokRet.string + "}]}]");
              tmpSL.append(tokRet.string);
            }
            break;
          
          case 3:
            if(tokRet.string.equals(";")){
              stop = true;
            }else if(tokRet.string.equals(".endm")){
              if(tmpM != null){ tmpM.Tokens = listToArray(tmpTL); }
              _Macros.add(cleanMacro(tmpM)); // 
              tmpM = null;
              tmpTL.clear();
              state = 0;
            }else{
              //println("buildMacro{" + tokRet.string + "}");
              tmpTL.add(new Token(tokRet.string));
              state = 3;
            }
            break;
          
          case 10:
            tmpS = tokRet.string;
            state = 11;
            break;
          
          case 11:
            _Vars.set(tmpS, tokRet.string);
            state = 0;
            break;
        }
        //print("{" + tokRet.string + "} ");
      }
      
      tokRet = getNextToken(file[i],tokRet.nextIndex);
      if(tokRet.nextIndex >= file[i].length() && tokRet.string.equals("")){
        stop = true; break;
      }
    }
    if(state == 2 && tmpM != null){
      tmpM.args = tmpSL.toArray();
      tmpSL.clear();
      state = 3;
    }else if(state == 3){
      tmpTL.add(new Token("\\n"));
    }
    //print("{" + token.Token + "} ");
    //println();
    //println("{" + token.Token + "} " + file[i]);
  }
}

boolean checkMacros(String macro, String line){
  for(int i = 0; i < _Macros.size(); i++){
    Macro tmp = _Macros.get(i);
    if(tmp.name.equals(macro)){
      //println(line);
      _output.append(parseMacro(tmp, line));
      return true;
    }
  }
  return false;
}

String[] parseMacro(Macro macro, String line){
  StringList output = new StringList();
  String cur = "";
  
  //output.append(";" + line);
  
  String[] macroArgs = getMacroArgs(line);
  
  for(int i = 0; i < macro.Tokens.length; i++){
    //println(macro.Tokens[i]);
    //cur += macro.Tokens[i];
    Token t = macro.Tokens[i];
    switch(t.Type){
      case External:
        switch(t.Str){
          case "\\n":
            output.append(cur);
            cur = "";
            break;
          case "\\t":
            cur += "\t";
            break;
          default:
            if(t.Str.contains("\\")){
              cur += cleanEscape(t.Str);
            }else{
              cur += t.Str + " ";
            }
            break;
        }
        break;
      case Argument:
        //printArray(macro.Arguments);
        //printArray(args);
        for(int a = 0; a < macro.Arguments.length; a++){
          if(macro.Arguments[a].name.equals(t.Value)){
            //println("{[{[" + t.Str + "}]}]");
            if(a >= macroArgs.length){
              cur += macro.Arguments[a].defualt;
            }else{
              if(macroArgs[a].contains("\\")){
                cur += t.Str.replace("%", cleanEscape(macroArgs[a]));
              }else{
                cur += t.Str.replace("%", macroArgs[a]);
              }
              //cur += t.Str.replace("%", args[a]);
            }
            break;
          }
        }
        //cur+=getVariable(new VariableReturn(TokenType.Argument, t.Value), macro, macroArgs);
        //println("failed to find arg: " + t.Value);
        break;
      case Label:
        break;
      case Variable:
        cur += t.Str.replace("%", _Vars.get(t.Value));
        break;
      case Include:
        break;
      case Let: // TODO: .let needs to handle variables and arguments!
        //println("var {" + t.Variable + "} and {" + t.Str.replace("%", t.Value) + "}");
        //cur += ";.let " + t.Variable + " " + t.Str.replace("%", t.Value);
        String v = _Vars.get(t.Value);
        if(v != null){
          //println("set var {" + t.Variable + "} to {" + t.Value + "}");
          _Vars.set(t.Variable, t.Str.replace("%", t.Value));
        }else{
          for(int a = 0; a < macro.Arguments.length; a++){
            if(macro.Arguments[a].name.equals(t.Value)){
              //println("set var {" + t.Str + "} to {" + args[a] + "}");
              _Vars.set(t.Variable, t.Str.replace("%", macroArgs[a]));
              break;
            }
          }
        }
        break;
      default:
        break;
    }
  }
  if(cur.length() > 0){ output.append(cur); }
  
  return output.toArray();
}

Macro cleanMacro(Macro macro){
  Macro output = new Macro(macro.name);
  
  output.Arguments = new Argument[macro.args.length];
  for(int i = 0; i < macro.args.length; i++){
    if(macro.args[i].contains("=")){
      String[] tmp = split(macro.args[i], '=');
      output.Arguments[i] = new Argument(tmp[0], tmp[1]);
    }else{
      output.Arguments[i] = new Argument(macro.args[i], null);
    }
  }
  
  int state = 0;
  ArrayList<Token> tmpTL = new ArrayList<Token>();
  Token tmpT = new Token();
  boolean newline = false;
  for(int i = 0; i < macro.Tokens.length; i++){
    String s = macro.Tokens[i].Str;
    //println("{{{" + s + "}}}");
    boolean push = false;
    switch(state){
      case 0:
        if(s.equals(".let")){
          tmpT.Type = TokenType.Let;
          newline = true;
          state = 1;
        }else if(s.equals("")){
          newline = false;
          state = 0;
        }else if(s.contains("%%")){
          tmpT = parseVariable(s, TokenType.Variable);
          //println("{[{[" + tmpT.Value + "}]}]");
          newline = false;
          push = true;
        }else if(s.contains("%")){
          tmpT = parseVariable(s, TokenType.Argument);
          //println("{[{[" + tmpT.Value + "}]}]");
          newline = false;
          push = true;
        }else{
          tmpT.Type = TokenType.External;
          tmpT.Str = s;
          if(s.equals("\\n")){
            if(!newline){ push = true; }
            newline = true;
          }else{
            newline = false;
            push = true;
          }
          state = 0;
        }
        break;
      
      case 1:
        tmpT.Variable = s;
        state = 2;
        break;
      
      case 2:
        Token tmp = parseVariable(s, TokenType.Let); // TODO: rework parseVariable to work for .let
        tmpT.Str = tmp.Str;
        tmpT.Value = tmp.Value;
        newline = true;
        push = true;
        break;
        
    }
    
    if(push){
      //println("cleanMacro{" + tmpT + "}");
      tmpTL.add(tmpT);
      tmpT = new Token();
      state = 0;
    }
  }
  output.Tokens = listToArray(tmpTL);
  
  return output;
}
