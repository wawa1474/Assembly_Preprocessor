/*
  dfw {name}, {flags: u8}, {prev: u16} => 0x00 @ name @ 0x00 @ flags @ le(prev)
  dfw {name},{name2}, {flags: u8}, {prev: u16} => 0x00 @ name @ name2 @ 0x00 @ flags @ le(prev)
  dfw {name},{name2},{name3}, {flags: u8}, {prev: u16} => 0x00 @ name @ name2 @ name3 @ 0x00 @ flags @ le(prev)
*/

//void output_dfw(String[] line){
//  //println(line[0]);
//  //println(line[1]);
//  //println(line[2]);
//  String name = line[0];
//  String flags = line[1];
//  String label = line[2];
//  _output.append("\t#d8 0x00");
//  _output.append("\t#d " + name);
//  _output.append("\t#d8 0x00");
//  _output.append("\t#d8 " + flags);
//  _output.append("\t#d16 le(" + label + "`16)");
//}

static final int Token_null = 0;
enum TokenType{
  Null,
  Macro_Start,
  Macro_Name,
  Macro_Args,
  Macro_End,
  Let,
}
enum TokenState{
  Error,
  Default,
  Macro,
  Macro_Name,
  Macro_Args,
  Macro_End,
  String,
  Let,
}

Token[] listToArray(ArrayList<Token> list){
  Token[] out = new Token[list.size()];
  
  for(int i = 0; i < out.length; i++){ // Token t : list
    out[i] = list.get(i);
  }
  
  return out;
}

ArrayList<Token> splitToken(String line){
  line += '\n';
  ArrayList<Token> tokens = new ArrayList<Token>();
  String cur = "";
  //TokenState state = TokenState.Default;
  //TokenState state2 = TokenState.Default;
  int state = 0;
  
  int index = 0;
  boolean stop = false;
  char c = ' ';
  while(!stop){
    if(index < line.length()){ c = line.charAt(index); }
    if(index == line.length() || isWhitespace(c)){
    }else{
      switch(state){
        case 0: // default
          if(isNumber(c)){
            state = 1; // number
            cur+=c;
          }else if(isAplha(c) || c == '_'){
            state = 2; // identifier
            cur+=c;
          }else if(c == '.'){ // preprocessor directive
            state = 3;
            cur+=c;
          }
          break;
        case 1: // number
          if(isNumber(c) || c == '.'){
            state = 1;
            cur+=c;
          }
      }
      
      cur += c;
      index++;
    }
  }
  
  //for(int i = 0; i < line.length(); i++){
  //  char c = line.charAt(i);
  //  if(!isWhitespace(c)){
  //    cur += c;
  //  }else{
  //    switch(state){
  //      case Default:
  //        switch(cur.toLowerCase()){
  //          case ".macro":
  //            tokens.add(new Token(TokenType.Macro_Start));
  //            state = TokenState.Macro;
  //            state2 = TokenState.Default;
  //            break;
  //          case ".endm":
  //            tokens.add(new Token(TokenType.Macro_End));
  //            state = TokenState.Default;
  //            state2 = TokenState.Default;
  //            break;
  //          case ".let":
  //            tokens.add(new Token(TokenType.Let));
  //            state = TokenState.Let;
  //            break;
  //        }
  //        break;
  //    }
  //    switch(cur.toLowerCase()){
  //      case ".macro":
  //        switch(state){
  //          case Default:
  //            tokens.add(new Token(TokenType.Macro_Start));
  //            state = TokenState.Macro;
  //            state2 = TokenState.Default;
  //            break;
  //          default:
  //            println("Attempted to start macro in bad spot!");
  //            break;
  //        }
  //        break;
  //      case ".endm":
  //        switch(state){
  //          case Macro:
  //            tokens.add(new Token(TokenType.Macro_End));
  //            state = TokenState.Default;
  //            state2 = TokenState.Default;
  //            break;
  //          default:
  //            println("Attempted to end macro outside of macro!");
  //            break;
  //        }
  //        break;
  //      case ".let":
  //        switch(state){
  //          case Let:
  //            println("Attempted to .let a .let!?");
  //            break;
  //          default:
  //            state2 = TokenState.Let;
  //            break;
  //        }
  //        break;
  //    }
  //  }
  //}
  
  return tokens;
}

void buildMacro(String line){
  String name = "";
  StringList args = new StringList();
  line = split(line, ".macro ")[1];
  
  boolean gotName = false;
  String tmp = "";
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    if(c == ' '){
      if(!gotName){ name = tmp; gotName = true; }
      else{ args.append(tmp); }
      tmp = "";
    }else if(c != ','){
      tmp += c;
    }
  }
  args.append(tmp);
  
  StringList output = new StringList();
  
  String cur = tmpFileHolder.contents[tmpFileHolder.indexArray++];
  while(!cur.contains(".endm") && tmpFileHolder.indexArray < tmpFileHolder.contents.length){
    if(cur.charAt(0) != ';'){ // ignore 'full-line' comments
      for(int i = 0; i < args.size(); i++){
        if(cur.contains("%%")){ // global variables
          //cur = cur.replace("%" + args.get(i), "%l" + i + "_");
        }else if(cur.contains(".%" + args.get(i))){ // labels
          cur = cur.replace("%" + args.get(i), "%l" + i + "_");
        }else{
          cur = cur.replace("%" + args.get(i), "%" + i + "_");
        }
      }
      output.append(cur);
    }
    cur = tmpFileHolder.contents[tmpFileHolder.indexArray++];
  }
  
  println(name);
  printArray(args);
  printArray(output);
  
  _Macros.add(new Macro(name, output.toArray()));
}

void outputMacro(Macro m, String[] line){
  for(int i = 0; i < m.output.length; i++){
    String cur = m.output[i];
    boolean skipOutput = false;
    
    if(cur.contains(".let")){
      println(cur + " : " + line[2]);
      setVariable(cur, line[2]);
      //skipOutput = true;
    }
    
    if(cur.contains("%%")){ // global variable
      int index = cur.indexOf("%%") + 2;
      char c = cur.charAt(index++);
      String vName = "";
      while(!(c == ' ' || c == '\t' || c == '\n' || c == '\r') && index < cur.length()){
        vName += "" + c;
        c = cur.charAt(index++);
      }
      vName += "" + c;
      String v = _Vars.get(vName);
      println("%%" + vName + " : " + v);
      if(v != null){
        cur = cur.replace("%%" + vName, v);
      }
    }
    
    for(int j = 0; j < line.length; j++){
      if(cur.contains("%" + j + "_")){ cur = cur.replace("%" + j + "_", line[j]); }
      else if(cur.contains("%l" + j + "_")){ cur = cur.replace("%l" + j + "_", stripLabel(line[j])); } // labels
    }
    if(!skipOutput){ _output.append(cur); }
  }
}

void setVariable(String line){
  String name = "";
  String value = "";
  String cur = "";
  int state = 0;
  
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    //println(cur);
    switch(state){
      case 0: // eat .let
        if(c == ' '){
          cur = "";
          state = 1;
        }else{
          cur += c;
        }
        break;
      
      case 1: // get name
        if(c == ' '){
          name = cur;
          cur = "";
          state = 2;
        }else{
          cur += c;
        }
        break;
      
      case 2: // get value
        if(c == ' ' || c == '\n' || c == '\r'){
          value = cur;
          cur = "";
          state = -1;
        }else{
          cur += c;
        }
        break;
    }
  }
  
  println("set var: " + name + " to " + cur);
  _Vars.set(name,value);
}

void setVariable(String line, String value){
  String name = "";
  String cur = "";
  int state = 0;
  
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    switch(state){
      case 0:
        if(c == ' '){
          cur = "";
          state = 1;
        }else{
          cur += c;
        }
        break;
      
      case 1:
        if(c == ' '){
          name = cur;
          cur = "";
          state = -1;
        }else{
          cur += c;
        }
        break;
    }
  }
  
  _Vars.set(name,value);
}

String stripLabel(String l){
  String out = "";
  for(int i = 0; i < l.length(); i++){
    char c = l.charAt(i);
    boolean found = false;
    //if(isAplha(c) || isNumber(c)){ out += c; }
    if(c == '"'){ continue; }
    if(c == '\\' && l.charAt(i+1) == 'u' && l.charAt(i+2) == '{'){
      i+=3;
      int t = (l.charAt(i++) - '0') << 4;
      t += l.charAt(i++) - '0';
      c = char(t);
    }
    for(int j = 0; j < _labelReplace.length; j++){
      if(c == _labelReplace[j].original){
        out += _labelReplace[j].replace;
        found = true;
      }
    }
    if(!found){
      out += c;
    }
  }
  return out;
}

boolean isAplha(char c){
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

boolean isHex(char c){
  return (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

boolean isNumber(char c){
  return c >= '0' && c <= '9';
}

boolean isWhitespace(char c){
  return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

LabelReplace[] _labelReplace = new LabelReplace[] {
  new LabelReplace('0', "zero"),
  new LabelReplace('1', "one"),
  new LabelReplace('2', "two"),
  new LabelReplace('3', "three"),
  new LabelReplace('4', "four"),
  new LabelReplace('5', "five"),
  new LabelReplace('6', "six"),
  new LabelReplace('7', "seven"),
  new LabelReplace('8', "eight"),
  new LabelReplace('9', "nine"),
  new LabelReplace('`', "tick"),
  new LabelReplace('~', "neg"),
  new LabelReplace('!', "bang"),
  new LabelReplace('@', "at"),
  new LabelReplace('#', "hash"),
  new LabelReplace('$', "dollar"),
  new LabelReplace('%', "mod"),
  new LabelReplace('^', "caret"),
  new LabelReplace('&', "and"),
  new LabelReplace('*', "star"),
  new LabelReplace('(', "paren"),
  new LabelReplace(')', "paren"),
  new LabelReplace('-', "minus"),
  new LabelReplace('+', "plus"),
  new LabelReplace('=', "equ"),
  new LabelReplace('[', "brack"),
  new LabelReplace(']', "brack"),
  new LabelReplace('{', "curly"),
  new LabelReplace('}', "curly"),
  new LabelReplace(':', "colon"),
  new LabelReplace(';', "semi"),
  new LabelReplace('"', "quote"),
  new LabelReplace('\'', "quote"),
  new LabelReplace(',', "comma"),
  new LabelReplace('.', "dot"),
  new LabelReplace('<', "lst"),
  new LabelReplace('>', "grt"),
  new LabelReplace('?', "q"),
  new LabelReplace('/', "div"),
};

class LabelReplace{
  char original;
  String replace;
  
  LabelReplace(char c, String s){
    original = c; replace = s;
  }
}

//void output_defword(String[] line){
//  String name = line[0];
//  String namelen = line[1];
//  String flags = line[2];
//  String label = line[3];
//  _output.append("\t#bank data");
//  _output.append("\t#align 2");
//  _output.append("name_" + label + ":");
//  _output.append("\t#d16 le(" + link + "`16)");
//  link = "name_" + label;
//  _output.append("\t#d16 le((" + (!flags.equals("") ? (flags + " + ") : "") + namelen + ")`16)");
//  _output.append("\t#d " + name);
//  _output.append("\t#align 2");
//  _output.append(label + ":");
//  _output.append("\t#d16 le(DOCOL`16)");
//}

//void output_defcode(String[] line){
//  String name = line[0];
//  String namelen = line[1];
//  String flags = line[2];
//  String label = line[3];
//  _output.append("\t#bank data");
//  _output.append("\t#align 2");
//  _output.append("name_" + label + ":");
//  _output.append("\t#d16 le(" + link + "`16)");
//  link = "name_" + label;
//  _output.append("\t#d16 le((" + (!flags.equals("") ? (flags + " + ") : "") + namelen + ")`16)");
//  _output.append("\t#d " + name);
//  _output.append("\t#align 2");
//  _output.append(label + ":");
//  _output.append("\t#d16 le(code_" + label + "`16)");
//  _output.append("\t#bank text");
//  _output.append("code_" + label + ":");
//}

//void output_defvar(String[] line){
//  String name = line[0];
//  String namelen = line[1];
//  String flags = line[2];
//  String label = line[3];
//  String initial;
//  if(line.length == 4){ initial = "0"; }
//  else{ initial = line[4]; }
//  _output.append("\t#bank data");
//  _output.append("\t#align 2");
//  _output.append("name_" + label + ":");
//  _output.append("\t#d16 le(" + link + "`16)");
//  link = "name_" + label;
//  _output.append("\t#d16 le((" + (!flags.equals("") ? (flags + " + ") : "") + namelen + ")`16)");
//  _output.append("\t#d " + name);
//  _output.append("\t#align 2");
//  _output.append(label + ":");
//  _output.append("\t#d16 le(code_" + label + "`16)");
//  _output.append("\t#bank text");
//  _output.append("code_" + label + ":");
//  _output.append("\tmov RB, [PC] var_" + label);
//  _output.append("\tmov push, RS[RB]");
//  _output.append("\tNEXT");
//  _output.append("\t#bank data");
//  _output.append("\t#align 2");
//  _output.append("var_" + label + ":");
//  _output.append("\t#d16 le(" + initial + "`16)");
//}

//void output_defconst(String[] line){
//  String name = line[0];
//  String namelen = line[1];
//  String flags = line[2];
//  String label = line[3];
//  String value = line[4];
//  _output.append("\t#bank data");
//  _output.append("\t#align 2");
//  _output.append("name_" + label + ":");
//  _output.append("\t#d16 le(" + link + "`16)");
//  link = "name_" + label;
//  _output.append("\t#d16 le((" + (!flags.equals("") ? (flags + " + ") : "") + namelen + ")`16)");
//  _output.append("\t#d " + name);
//  _output.append("\t#align 2");
//  _output.append(label + ":");
//  _output.append("\t#d16 le(code_" + label + "`16)");
//  _output.append("\t#bank text");
//  _output.append("code_" + label + ":");
//  _output.append("\tmov push, [PC] " + value);
//  _output.append("\tNEXT");
//}
