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
    for(int i = 0; i < args.size(); i++){
      if(cur.contains(".%" + args.get(i))){ // labels
        cur = cur.replace("%" + args.get(i), "%l" + i + "_");
      }else{
        cur = cur.replace("%" + args.get(i), "%" + i + "_");
      }
    }
    output.append(cur);
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
    for(int j = 0; j < line.length; j++){
      if(cur.contains("%" + j + "_")){ cur = cur.replace("%" + j + "_", line[j]); }
      else if(cur.contains("%l" + j + "_")){ cur = cur.replace("%l" + j + "_", stripLabel(line[j])); } // labels
    }
    _output.append(cur);
  }
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

boolean isNumber(char c){
  return c >= '0' && c <= '9';
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
