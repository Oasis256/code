#ifndef correlator2d_H
  #define correlator2d_H

  #include <region.h>
  #include <rgbmp.h>

extern int Correlator2dMethod; // Variable initialised in .c file // 1 = over-exclusive, 2 = over-inclusive

#define linearMode 0
#define joeysMode 1
#define perpMode 2

class Correlator2d {
public:
	int mode; // Exists
  List<V2d> points; // Exists // Points from which to find a line of best fit
  List<float> weights; // Exists // Weightings of the points

  int min; // Exists
  int maxposs; // Exists

  boolean made; // Exists
  // Redundant information (only exists after processing above)
  float bestang; // Exists
  List<int> pointskept; // Exists
  V2d centroid; // Exists
  float total; // Exists
  float besterr; // Exists

   Correlator2d(); // Method

   Correlator2d(List<V2d> pts); // Method


  void add(V2d v,float w); // Method

  void add(V2d v); // Method

  void add(Pixel p); // Method


  /* float total() {
    float total=0.0;
    for (int i=0;i<weights.len;i++)
      total+=weights.get(i);
    return total;
  }
  V2d centroid() {
    V2d cen=V2d(0,0);
    for (int i=0;i<points.len;i++)
      cen=cen+points.get(i);
    return cen/total();
  }
  void normalise() { // Normalises all points around centroid
    V2d cen=centroid();
    for (int i=0;i<points.len;i++)
      points.replace(i+1,points.get(i)-cen); // non-Java compensation
  } */

  void make(); // Method


  void addposs(List<int> n,List<List<int> > *poss,List<V2d> *cens,List<float> *totals); // Method


  void remake(); // Method


  float totalfor(List<int> ps); // Method


  V2d centroidfor(List<int> ps); // Method


  boolean tryset(List<int> ps); // Method


  boolean trysetJoeysMode(List<int> ps,V2d cen,float total); // Method


  boolean trysetPerpMode(List<int> ps,V2d cen,float total); // Method


	float errPerpMode(List<int> ps,float a,float b); // Method


  boolean tryset(List<int> ps,V2d cen,float total); // Method


  float angle(); // Method

  float error(); // Method

  Line2d line(); // Method


  float crossesy(); // Method


  void remakebruteforce(); // Method


    bool used(int i); // Method


    // See drawCorrelator2d(c) in region.c

};





/* RGBmp drawCorrelator2d(Correlator2d cc) {
    Region r=Region(cc.points);
    int left=r.listleftmost()-5;
    int right=r.listrightmost()+5;
    int top=r.listtopmost()-5;
    int bottom=r.listbottommost()+5;
    if (bottom<0 && top<0)
        bottom=0;
    if (top>0 && bottom>0)
        top=0;
    int wid=right-left;
    int hei=bottom-top;
    int mw = ( wid>hei ? 400 : 400*wid/hei );
    int mh = ( wid>hei ? 400*hei/wid : 400 );
  RGBmp m=RGBmp(mw,mh,myRGB::black);
  float symbolsize=5.0*(float)cc.points.len/(float)cc.total;
  printf("Plotting set %s\n",cc.pointskept.toString());
  for (int i=1;i<=cc.points.len;i++) {
    Pixel p=Pixel(m.width*(cc.points.num(i).x-left)/wid,
              m.height*(cc.points.num(i).y-top)/hei);
    p.y=m.height-1-p.y; // invert height so y goes up!
    myRGB colour=myRGB::white;
    if (!cc.pointskept.contains(i-1)) {
      colour=myRGB::red;
//   m.circle(p,symbolsize*cc.weights.num(i),myRGB::red);
    }
    m.cross(p,symbolsize*cc.weights.num(i),colour);
  }
  V2d c=cc.centroid;
  V2d mc=V2d(m.width*(c.x-left)/wid,m.height*(c.y-top)/hei);
  mc.y=m.height-1-mc.y;
  V2d dir=V2d::angle(cc.bestang)*200;
  dir.y=-dir.y;
  m.line(mc-dir,mc+dir,myRGB::yellow);
  return m;
} */


Map2d<bool> drawCorrelator2d(Correlator2d cc); // Method


RGBmp drawCorrelator2dInColour(Correlator2d cc); // Method


#endif
