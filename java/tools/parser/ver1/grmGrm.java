import java.lang.String;
import java.util.Vector;

import Grammar;
import RuleSet;

public class grmGrm {
  public static void setupgrammar() {
    Vector rulesets=Grammar.rulesets;
    RuleSet ruleset;
    Vector rule;

    // This grammar defines defines the file
    // format for a grammar

    ruleset=new RuleSet("Main");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("GrammarDefn"));
      ruleset.add(rule);
    // Replacements



    // java: "package grammars;\n\n" GrammarDefn

    ruleset=new RuleSet("GrammarDefn");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("Grm"));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Text("import java.lang.String;\nimport java.util.Vector;\n\nimport Grammar;\nimport RuleSet;\n\npublic class grmGrm {\n  public static void setupgrammar() {\n    Vector rulesets=Grammar.rulesets;\n    RuleSet ruleset;\n    Vector rule;\n\n"));
        rule.add(new Atom("Grm"));
        rule.add(new Text("  }\n}\n"));
    ruleset.replacements.put("java",rule);

    rule=new Vector();
        rule.add(new Text("module Grammar where\n\ndata Type = Atom String | Var String | Str String\n          | VarExcl String String\n  deriving (Eq)\n\ndata Match = No | Yes Type String [Match] String\n  deriving (Eq)\n\ntype RuleSet = [[Type]]\n\ntype Rule = ( Type , RuleSet , [Replacement] )\n\ntype Replacement = ( String , [Type])\n\n\nrules = [ "));
        rule.add(new Atom("Grm"));
        rule.add(new Text(" ]\n"));
    ruleset.replacements.put("hugs",rule);



    ruleset=new RuleSet("Grm");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("GrmBit"));
        rule.add(new Atom("Grm"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Atom("GrmBit"));
      ruleset.add(rule);
    // Replacements



    ruleset=new RuleSet("GrmBit");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Text("\n"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Atom("Whitespace"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Atom("Comment"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Atom("Atom"));
      ruleset.add(rule);
    // Replacements



    ruleset=new RuleSet("Comment");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Text("#"));
        rule.add(new Var("comment","\n"));
        rule.add(new Text("\n"));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Text("    //"));
        rule.add(new Var("comment"));
        rule.add(new Text("\n"));
    ruleset.replacements.put("java",rule);



    // hugs: "-- " <comment> "\n"

    ruleset=new RuleSet("Atom");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("AtomWithout"));
        rule.add(new Text("\n\n"));
      ruleset.add(rule);
    // Replacements



    ruleset=new RuleSet("AtomWithout");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Var("atomname","^.<>\n\" ="));
        rule.add(new Text(" = "));
        rule.add(new Atom("Defn"));
        rule.add(new Atom("OptReplacements"));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Text("    ruleset=new RuleSet(\""));
        rule.add(new Var("atomname"));
        rule.add(new Text("\");\n      rulesets.add(ruleset);\n      rule=new Vector();\n"));
        rule.add(new Atom("Defn"));
        rule.add(new Text("      ruleset.add(rule);\n"));
        rule.add(new Atom("OptReplacements"));
        rule.add(new Text("\n"));
    ruleset.replacements.put("java",rule);

    rule=new Vector();
        rule.add(new Text("  ( Atom \""));
        rule.add(new Var("atomname"));
        rule.add(new Text("\",[\n    [ "));
        rule.add(new Atom("Defn"));
        rule.add(new Text(" ]\n    ] , [\n"));
        rule.add(new Atom("OptReplacements"));
        rule.add(new Text("\n  ] ) ,\n"));
    ruleset.replacements.put("hugs",rule);



    ruleset=new RuleSet("OptReplacements");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Text("\n"));
        rule.add(new Atom("Replacements"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Text(""));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Text("    // Replacements\n"));
        rule.add(new Atom("Replacements"));
    ruleset.replacements.put("java",rule);



    ruleset=new RuleSet("Replacements");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("TwoReplacements"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Atom("Replacement"));
      ruleset.add(rule);
    // Replacements



    ruleset=new RuleSet("TwoReplacements");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("Replacement"));
        rule.add(new Text("\n"));
        rule.add(new Atom("Replacements"));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Atom("Replacement"));
        rule.add(new Text(",\n"));
        rule.add(new Atom("Replacements"));
    ruleset.replacements.put("hugs",rule);



    ruleset=new RuleSet("Replacement");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Var("target","<>\n\" :"));
        rule.add(new Text(": "));
        rule.add(new Atom("Defn"));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Text("    rule=new Vector();\n"));
        rule.add(new Atom("Defn"));
        rule.add(new Text("    ruleset.replacements.put(\""));
        rule.add(new Var("target"));
        rule.add(new Text("\",rule);\n"));
    ruleset.replacements.put("java",rule);

    rule=new Vector();
        rule.add(new Text("      ( \""));
        rule.add(new Var("target"));
        rule.add(new Text("\" , [ "));
        rule.add(new Atom("Defn"));
        rule.add(new Text(" ] ) "));
    ruleset.replacements.put("hugs",rule);



    ruleset=new RuleSet("Defn");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("DefnOr"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Atom("DefnAnd"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Atom("DefnBit"));
      ruleset.add(rule);
    // Replacements



    ruleset=new RuleSet("DefnBit");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("RelativeElement"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Atom("BasicElement"));
      ruleset.add(rule);
    // Replacements



    ruleset=new RuleSet("BasicElement");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("Variable"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Atom("Text"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Atom("AtomRef"));
      ruleset.add(rule);
    // Replacements



    ruleset=new RuleSet("DefnOr");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("DefnBit"));
        rule.add(new Atom("Whitespace"));
        rule.add(new Text("|"));
        rule.add(new Atom("Whitespace"));
        rule.add(new Atom("Defn"));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Atom("DefnBit"));
        rule.add(new Text("      ruleset.add(rule);\n      rule=new Vector();\n"));
        rule.add(new Atom("Defn"));
    ruleset.replacements.put("java",rule);

    rule=new Vector();
        rule.add(new Atom("DefnBit"));
        rule.add(new Text("] ,\n      [ "));
        rule.add(new Atom("Defn"));
    ruleset.replacements.put("hugs",rule);



    ruleset=new RuleSet("DefnAnd");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("DefnBit"));
        rule.add(new Text(" "));
        rule.add(new Atom("Defn"));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Atom("DefnBit"));
        rule.add(new Atom("Defn"));
    ruleset.replacements.put("java",rule);

    rule=new Vector();
        rule.add(new Atom("DefnBit"));
        rule.add(new Text(", "));
        rule.add(new Atom("Defn"));
    ruleset.replacements.put("hugs",rule);



    ruleset=new RuleSet("Variable");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("Var"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Atom("VarDeny"));
      ruleset.add(rule);
    // Replacements



    ruleset=new RuleSet("Var");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Text("<"));
        rule.add(new Var("varname","<>\n\"/ "));
        rule.add(new Text(">"));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Text("        rule.add(new Var(\""));
        rule.add(new Var("varname"));
        rule.add(new Text("\"));\n"));
    ruleset.replacements.put("java",rule);

    rule=new Vector();
        rule.add(new Text("Var \""));
        rule.add(new Var("varname"));
        rule.add(new Text("\""));
    ruleset.replacements.put("hugs",rule);



    ruleset=new RuleSet("VarDeny");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Text("<"));
        rule.add(new Var("varname","<>\n\"/ "));
        rule.add(new Text("/\""));
        rule.add(new Var("denied","\""));
        rule.add(new Text("\">"));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Text("        rule.add(new Var(\""));
        rule.add(new Var("varname"));
        rule.add(new Text("\",\""));
        rule.add(new Var("denied"));
        rule.add(new Text("\"));\n"));
    ruleset.replacements.put("java",rule);

    rule=new Vector();
        rule.add(new Text("VarExcl \""));
        rule.add(new Var("varname"));
        rule.add(new Text("\" \""));
        rule.add(new Var("denied"));
        rule.add(new Text("\""));
    ruleset.replacements.put("hugs",rule);



    ruleset=new RuleSet("AtomRef");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Var("atomtype","^.<>\n\" "));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Text("        rule.add(new Atom(\""));
        rule.add(new Var("atomtype"));
        rule.add(new Text("\"));\n"));
    ruleset.replacements.put("java",rule);

    rule=new Vector();
        rule.add(new Text("Atom \""));
        rule.add(new Var("atomtype"));
        rule.add(new Text("\""));
    ruleset.replacements.put("hugs",rule);



    ruleset=new RuleSet("Text");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Text("\""));
        rule.add(new Var("text","\""));
        rule.add(new Text("\""));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Text("\"\""));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Text("        rule.add(new Text(\""));
        rule.add(new Var("text"));
        rule.add(new Text("\"));\n"));
    ruleset.replacements.put("java",rule);

    rule=new Vector();
        rule.add(new Text("Str \""));
        rule.add(new Var("text"));
        rule.add(new Text("\""));
    ruleset.replacements.put("hugs",rule);



    ruleset=new RuleSet("RelativeElement");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("RelUp"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Atom("RelDown"));
      ruleset.add(rule);
    // Replacements



    ruleset=new RuleSet("RelUp");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("Ref"));
        rule.add(new Text("^"));
        rule.add(new Atom("Var"));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Text("        { Vector realrule=rule; rule=new Vector(); "));
        rule.add(new Atom("Var"));
        rule.add(new Text(" realrule.add(new RelElement('^',"));
        rule.add(new Atom("Ref"));
        rule.add(new Text(",(Var)rule.get(0))); rule=realrule; }\n"));
    ruleset.replacements.put("java",rule);



    ruleset=new RuleSet("RelDown");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("Ref"));
        rule.add(new Text("."));
        rule.add(new Atom("Var"));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Text("        { Vector realrule=rule; rule=new Vector(); "));
        rule.add(new Atom("Var"));
        rule.add(new Text(" realrule.add(new RelElement('.',"));
        rule.add(new Atom("Ref"));
        rule.add(new Text(",(Var)rule.get(0))); rule=realrule; }\n"));
    ruleset.replacements.put("java",rule);



    ruleset=new RuleSet("Ref");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Var("ref"," \"\n.^"));
      ruleset.add(rule);
    // Replacements
    rule=new Vector();
        rule.add(new Text("\""));
        rule.add(new Var("ref"));
        rule.add(new Text("\""));
    ruleset.replacements.put("java",rule);



    ruleset=new RuleSet("Whitespace");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Atom("WhitespaceBit"));
        rule.add(new Atom("Whitespace"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Atom("WhitespaceBit"));
      ruleset.add(rule);
    // Replacements



    ruleset=new RuleSet("WhitespaceBit");
      rulesets.add(ruleset);
      rule=new Vector();
        rule.add(new Text("\n"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Text(" "));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Text("\t"));
      ruleset.add(rule);
      rule=new Vector();
        rule.add(new Text("\r"));
      ruleset.add(rule);
    // Replacements





  }
}
