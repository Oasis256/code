#ifndef jfontformaps_C
  #define jfontformaps_C

  #include <jfontformaps.h>

// Starts of class FontBit


  template <class Object>
  void FontBit::writetomap(Map2d<Object> *j,int x,int y,float scale,Object c) {
    printf("arse\n");
  }
// End class 


// Starts of class FontChar


  // Variable declared in .h file
  // Variable declared in .h file
   FontChar::FontChar() {
  }
   FontChar::FontChar(String n) {
    name=n;
  }
  template<class Object>
  void FontChar::writetomap(Map2d<Object> *j,int x,int y,float scale,Object c) {
//    printf("Drawing character %s (%i)\n",name,bs.len);
    for (int i=1;i<=bs.len;i++) {
      FontBit *fb=bs.num(i);
      fb->writetomap(j,x,y,scale*0.5,c);
    }
  }
// End class 


// Starts of class FLine


  // Variable declared in .h file
  // Variable declared in .h file
  bool FLine::hor=false;
  bool FLine::ver=false;
  bool FLine::round=false;
  bool FLine::lng=false;
   FLine::FLine(float aa,float bb,float c,float d,float e,String t) {
    a=V2d(aa,bb);
    b=V2d(c,d);
    w=e;
    if (Sinstr(t,"H"))
      hor=true;
    if (Sinstr(t,"V") || diff(a.y,b.y)>diff(a.x,b.x))
      ver=true;
    if (Sinstr(t,"R"))
      round=true;
    if (Sinstr(t,"L"))
      lng=true;
  }
  template<class Object>
  void FLine::writetomap(Map2d<Object> *j,int x,int y,float scale,Object c) {
    if (round)
      j->rthickline(V2d(x,y)+scale*a,V2d(x,y)+scale*b,w*scale,c);
    else if (ver)
      j->thicklinev(V2d(x,y)+scale*a,V2d(x,y)+scale*b,w*scale,c);
    else if (hor)
      j->thicklineh(V2d(x,y)+scale*a,V2d(x,y)+scale*b,w*scale,c);
    else if (lng)
      j->thickline(V2d(x,y)+scale*a,V2d(x,y)+scale*b,w*scale,c);
    else
      j->sthickline(V2d(x,y)+scale*a,V2d(x,y)+scale*b,w*scale,c);
  }
// End class 


// Starts of class FArc


  // Variable declared in .h file
   FArc::FArc(float a,float b,float c,float d) {
    x=a;
    y=b;
    r=c;
    w=d;
    aa=0;
    ab=2*pi;
//    printf("new arc %f %f %f %f %f\n",x,y,r,aa,ab);
  }
  template<class Object>
  void FArc::writetomap(Map2d<Object> *j,int cx,int cy,float scale,Object c) {
    bool first=true;
    V2d o,i;
    if (ab<aa)
      ab+=2*pi;
//    for (float a=aa-0.001;a<=ab+0.001;a+=diff(ab,aa)/16.1) {
    //int sps=32*moddiff(ab,aa,2*pi)/pi;
    int sps=12.0*diff(ab,aa)/pi;
    for (int k=0;k<=sps;k++) {
      float a=pull(aa,(float)k/(float)sps,ab);
      V2d no=V2d(cx,cy)+scale*V2d(x+(r+w/2.0)*sin(a),-y-(r+w/2.0)*cos(a));
      V2d ni=V2d(cx,cy)+scale*V2d(x+(r-w/2.0)*sin(a),-y-(r-w/2.0)*cos(a));
      if (first)
        first=false;
      else {
        j->intertri(o,i,ni,c,c,c);
        j->intertri(o,ni,no,c,c,c);
        //j->fillquad(o,i,ni,no,c);
      }
      o=no;
      i=ni;
    }
  }
/*  void writetomap(Map2d<Object> *j,int cx,int cy,float scale,Object c) {
    bool first=true;
    V2d p,l;
    for (float a=aa;a<=ab;a+=pi/32.1) {
      p=V2d(cx,cy)+scale*V2d(x+r*sin(a),-y-r*cos(a));
      if (first)
        first=false;
      else
        j->thickline(l,p,w*scale-2,c);
      l=p;
    }
  }*/
// End class 


List<FontChar> parsefontchars(String fname) {
  // We parse from
  List<String> lines=readlinesfromfile(fname);
  // into
  List<FontChar> fcs=List<FontChar>();
  float fw=tofloat(lines.num(1));
  for(int i=2;i<=lines.len;i++) {
    String current=lines.num(i);
    StringParser s=StringParser(current);
    if (s.someleft() && !Seq("//",Sleft(current,2))) {
    String character=s.getbefore(":");
    FontChar fc=FontChar(character);
    while (s.someleft()) {
      char whatisit=s.getchar();
      if (whatisit=='L') {
        String type=s.getanyof("HVRL");
        float xa=tofloat(s.getbefore(","));
        float ya=tofloat(s.getbefore("_"));
        bool keepgoing=true;
        while (keepgoing) {
          float xb=tofloat(s.getbefore(","));
          float yb=s.getfloat();
//          printf("new line %f %f %f %f\n",xa,ya,xb,yb);
          fc.bs.add(new FLine(xa,-ya,xb,-yb,fw,type));
          xa=xb; ya=yb;
          // printf("one line added\n");
          // printf("From %s we pick off ",s.current);
          char c=s.getchar();
          // printf("%c, to get %s\n",c,s.current);
          if (c==';')
            keepgoing=false;
          else
          if (c!='_')
            s.error(Sformat("Expected _, got %c",c));
        };
      }
      if (whatisit=='C') {
        String type=s.getanyof("TBLRNESWXO");
        bool anti=false;
        if (Seq(Sleft(type,1),"X")) {
          anti=true;
          type=Sfrom(type,2);
        }
        float x=tofloat(s.getbefore(","));
        float y=tofloat(s.getbefore(","));
        String next=( Seq(type,"O") ? "," : ";" );
        float r=tofloat(s.getbefore(next));
        FArc *fa=new FArc(x,y,r,fw);
        if (Slen(type)==0) {
          fa->aa=0;
          fa->ab=2*pi;
        }
        if (Seq(type,"O")) {
          fa->aa=tofloat(s.getbefore(","))*2*pi/8.0;
          fa->ab=tofloat(s.getbefore(";"))*2*pi/8.0;
        }
        if (Seq(type,"T")) {
          fa->aa=-pi/2.0;
          fa->ab=pi/2.0;
        }
        if (Seq(type,"B")) {
          fa->aa=pi/2.0;
          fa->ab=2*pi-pi/2.0;
        }
        if (Seq(type,"L")) {
          fa->aa=-pi;
          fa->ab=0;
        }
        if (Seq(type,"R")) {
          fa->aa=0;
          fa->ab=pi;
        }
        if (Seq(type,"NW")) {
          fa->aa=-pi/2.0;
          fa->ab=0;
        }
        if (Seq(type,"NE")) {
          fa->aa=0;
          fa->ab=pi/2.0;
        }
        if (Seq(type,"SE")) {
          fa->aa=pi/2.0;
          fa->ab=pi;
        }
        if (Seq(type,"SW")) {
          fa->aa=-pi;
          fa->ab=-pi/2.0;
        }
        if (anti)
          swap(&fa->aa,&fa->ab);
        /*if (Seq(type,"XSE")) {
          fa->aa=-pi;
          fa->ab=pi/2.0;
        }
        if (Seq(type,"XNW")) {
          fa->aa=0;
          fa->ab=2*pi-pi/2.0;
        }*/
        fc.bs.add(fa);
      }
      if (whatisit=='+') {
        String search=s.getbefore(";");
        int find=0;
        for (int j=1;j<=fcs.len && find==0;j++) {
          if (Seq(search,fcs.p2num(j)->name))
            find=j;
        }
        if (find==0)
          error("You haven't defined character %s before %s",search,character);
        fc.bs.add(fcs.p2num(find)->bs);
        // default:
        // printf("What kind of FontBit is a %s?",toString(whatisit));
      }
    };
    fcs.add(fc);
    printf("%s (%i) ... ",fc.name,fc.bs.len);
    }
  }
  printf("\n");
  lines.freedom();
  return fcs;
}

// Starts of class JFont

  // Variable declared in .h file

   JFont::JFont(String fname) {
    fcs=parsefontchars(fname);
  }
   bool JFont::fcalled(FontChar *f,String s) {
    return Seq(f->name,s);
  }
  template<class Object>
  void JFont::writechar(String s,Map2d<Object> *j,int x,int y,float scale,Object c) {
    int i=fcs.find(&fcalled,s);
    if (i>0) {
      FontChar *fc=fcs.p2num(i);
      fc->writetomap(j,x,y,scale,c);
    }
  }
  template<class Object>
  void JFont::writeString(String s,Map2d<Object> *j,int x,int y,float scale,Object c) {
    for (int i=1;i<=Slen(s);i++) {
      String z=Smid(s,i,1);
      int k=fcs.find(&fcalled,z);
      if (k>0) {
        FontChar *fc=fcs.p2num(k);
        fc->writetomap(j,x+1.5*scale*(float)i,y,scale,c);
      }
    }
  }
  template<class Object>
  void JFont::centerString(String s,Map2d<Object> *j,int y,float scale,Object c) {
    int x=j->width/2-scale*1.5*(Slen(s)-1)/2.0;
    writeString(s,j,x,y,scale,c);
  }
  template<class Object>
  void JFont::centerString(String s,Map2d<Object> *j,int cx,int y,float scale,Object c) {
    int x=cx-scale*1.5*(Slen(s)-1)/2.0;
    writeString(s,j,x,y,scale,c);
  }
// End class 


#endif
