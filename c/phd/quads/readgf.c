#include <joeylib.c>

struct QuadsLine2d {
  V2d a,b;
  float length;
  QuadsLine2d() { }
  QuadsLine2d(V2d aa,V2d bb) {
    a=aa;
    b=bb;
    length=V2d::dist(a,b);
  }
  void swapends() {
    V2d tmp=a;
    a=b;
    b=tmp;
  }
  String toString() {
    return Sformat("Line %s-%s\n",a.toString(),b.toString());
  }
};

List<QuadsLine2d> *getquad(List<QuadsLine2d> *l,List<QuadsLine2d> *sf,float cd) {
//  printf("%i %i\n",l->len,sf->len);
  if (sf->len==4)
    if (V2d::dist(sf->num(1).a,sf->num(sf->len).b)<cd)
      return sf;
    else
      return NULL;
  QuadsLine2d last=sf->num(sf->len);
  for (int i=1;i<=l->len;i++) {
    QuadsLine2d c=l->num(i);
    if (V2d::dist(last.b,c.b)<cd)
      c.swapends();
    if (V2d::dist(last.b,c.a)<cd) {
      sf->add(c);
      l->removenum(i);
      List<QuadsLine2d> *q=getquad(l,sf,cd);
//      if (q.len==4)
      if (q!=NULL)
        return q;
      l->add(c);
      l->swapelements(i,l->len);
      sf->removenum(sf->len);
    }
  }
  return NULL;
}      

/*void display(List<QuadsLine2d> *l) {
  allegrosetup(640,480);
  JBmp b=JBmp(640,480);
  for (int i=1;i<=l->len;i++)
    b.line(4.8*l->num(i).a,4.8*l->num(i).b,15);
  b.writetoscreen();
}*/

void main(int argc, String *argv) {

  ArgParser a=ArgParser(argc,argv);

  String inname=a.argafter("-i","Input gf file","ls.gf");
  String outname=a.argafter("-o","Output gf file","quads.gf");
  float cornerdist=a.floatafter("-c","Maximum distance of corners",10.0);
  float minarea=a.floatafter("-a","Minimum area of quadrilateral",200.0);
  float minlen=a.floatafter("-l","Minimum length of a line",1.0);

  // Read list from file
  FILE *fp=fopen("ls.gf","r");
  List<QuadsLine2d> l=List<QuadsLine2d>();

  String s;
  while (!Seq(Sleft(s,4),"@SET")) {
    s=getlinefromfile(fp);
//    printf("Read line %s\n",s);
  }

  s=getlinefromfile(fp);
  s=getlinefromfile(fp);
  s=getlinefromfile(fp);
  while (!Seq(Sleft(s,1),"@")) {
    // Dummies
    int n,w;
    float t,r,sx,sy,ex,ey,p;
//    printf("Scanning line %s\n",s);
    sscanf(s,"%i %f %f %f %f %f %f %i %f",&n,&t,&r,&sx,&sy,&ex,&ey,&w,&p);
    l.add(QuadsLine2d(V2d(sx,sy),V2d(ex,ey)));
//    printf(l.num(l.len).toString());
    s=getlinefromfile(fp);
  }
  
  fclose(fp);

/*  for (int i=1;i<=1000;i++) {
    V2d a=V2d(myrnd()*100,myrnd()*100);
    V2d b=V2d(myrnd()*100,myrnd()*100);
    l.add(QuadsLine2d(a,b));
  }*/

  printf("%i lines read from %s.\n",l.len,inname);

  // Strip out small lines
  for (int i=1;i<=l.len;i++) {
    if (l.num(i).length<minlen) {
      l.removenum(i);
      i--;
    }
  }

  printf("Stripped small lines, now %i.\n",l.len);

//  display(&l);

  // Find quadrilaterals
  List< List<QuadsLine2d> > qs=List< List<QuadsLine2d> >();
  while (l.len>0) {
    List<QuadsLine2d> *q=new List<QuadsLine2d>();
    q->add(l.num(1));
    l.removenum(1);
    q=getquad(&l,q,cornerdist);
    if (q!=NULL) {
      // Join corners
      for (int i=1;i<=q->len;i++) {
        int j=1+(i%q->len);
        q->num(i).b.print();
        printf(",");
        q->num(j).a.print();
        printf(" = ");
        q->p2num(i)->b=(q->p2num(i)->b+q->p2num(j)->a)/2.0;
        q->p2num(i)->b.print();
        q->p2num(j)->a=q->p2num(i)->b;
        printf("\n");
      }
      qs.add(*q);
//      printf("Quad found!\n");
    }
  }

  printf("%i quadrilaterals found.\n",qs.len);
  
  FILE *g=fopen(outname,"w");
  
  fprintf(g,"@Set Description\n");
  fprintf(g,"Format Text\n");
  fprintf(g,"Joey's quadrilaterals\n");
  fprintf(g,"@\n");
  fprintf(g,"@SET Quads\n");
  fprintf(g,"GeomStruct line startx starty endx endy\n");
  fprintf(g,"format idpointset line\n");
  
  for (i=1;i<=qs.len;i++) {
    List<QuadsLine2d> *q=qs.p2num(i);
      for (int j=1;j<=q->len;j++) {
        QuadsLine2d l=q->num(j);
        fprintf(g,"%i %f %f %f %f\n",4*(i-1)+j,l.a.x,l.a.y,l.b.x,l.b.y);
      }
  }
  
  fprintf(g,"@\n");
  fclose(g);
  printf("File %s written.\n",outname);

}
