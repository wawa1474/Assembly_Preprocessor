void output_defword(String[] line){
  String name = line[0];
  String namelen = line[1];
  String flags = line[2];
  String label = line[3];
  output.append("\t#bank data");
  output.append("\t#align 2");
  output.append("name_" + label + ":");
  output.append("\t#d16 le(" + link + "`16)");
  link = "name_" + label;
  output.append("\t#d16 le((" + (!flags.equals("") ? (flags + " + ") : "") + namelen + ")`16)");
  output.append("\t#d " + name);
  output.append("\t#align 2");
  output.append(label + ":");
  output.append("\t#d16 le(DOCOL`16)");
}

void output_defcode(String[] line){
  String name = line[0];
  String namelen = line[1];
  String flags = line[2];
  String label = line[3];
  output.append("\t#bank data");
  output.append("\t#align 2");
  output.append("name_" + label + ":");
  output.append("\t#d16 le(" + link + "`16)");
  link = "name_" + label;
  output.append("\t#d16 le((" + (!flags.equals("") ? (flags + " + ") : "") + namelen + ")`16)");
  output.append("\t#d " + name);
  output.append("\t#align 2");
  output.append(label + ":");
  output.append("\t#d16 le(code_" + label + "`16)");
  output.append("\t#bank text");
  output.append("code_" + label + ":");
}

void output_defvar(String[] line){
  String name = line[0];
  String namelen = line[1];
  String flags = line[2];
  String label = line[3];
  String initial;
  if(line.length == 4){ initial = "0"; }
  else{ initial = line[4]; }
  output.append("\t#bank data");
  output.append("\t#align 2");
  output.append("name_" + label + ":");
  output.append("\t#d16 le(" + link + "`16)");
  link = "name_" + label;
  output.append("\t#d16 le((" + (!flags.equals("") ? (flags + " + ") : "") + namelen + ")`16)");
  output.append("\t#d " + name);
  output.append("\t#align 2");
  output.append(label + ":");
  output.append("\t#d16 le(code_" + label + "`16)");
  output.append("\t#bank text");
  output.append("code_" + label + ":");
  output.append("\tmov RB, [PC] var_" + label);
  output.append("\tmov push, RS[RB]");
  output.append("\tNEXT");
  output.append("\t#bank data");
  output.append("\t#align 2");
  output.append("var_" + label + ":");
  output.append("\t#d16 le(" + initial + "`16)");
}

void output_defconst(String[] line){
  String name = line[0];
  String namelen = line[1];
  String flags = line[2];
  String label = line[3];
  String value = line[4];
  output.append("\t#bank data");
  output.append("\t#align 2");
  output.append("name_" + label + ":");
  output.append("\t#d16 le(" + link + "`16)");
  link = "name_" + label;
  output.append("\t#d16 le((" + (!flags.equals("") ? (flags + " + ") : "") + namelen + ")`16)");
  output.append("\t#d " + name);
  output.append("\t#align 2");
  output.append(label + ":");
  output.append("\t#d16 le(code_" + label + "`16)");
  output.append("\t#bank text");
  output.append("code_" + label + ":");
  output.append("\tmov push, [PC] " + value);
  output.append("\tNEXT");
}
