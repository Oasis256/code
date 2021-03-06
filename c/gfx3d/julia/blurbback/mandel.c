/* All my source code is freely distributable under the GNU public licence.
   If you make money with this code, please give me some!
   If you find this code useful, or have any queries, please feel free to
   contact me: pclark@cs.bris.ac.uk / joeyclark@usa.net
   Paul "Joey" Clark, hacking for humanity, Feb 1999
   http://www.cs.bris.ac.uk/~pclark */


// 4d julia sliced through d-axis
// Rotated view

#include <joeylib.c>

// z=z^2+c

Quaternion current;

int julquat(Quaternion z) {
  int k=0;
  bool over=false;
  do {
    k++;
    z=z*z+current;
    if (k>255)
      over=true;
  } while (!over && !(z.mod()>2.0));
  if (over)
    k=0;
  return k;
}

void main() {
  int scrwid=320;
  int scrhei=200;
  float cenx=-0.5;
  float ceny=0;
  float wid=2.0;
  float hei=1.5;
  float left=cenx-wid;
  float right=cenx+wid;
  float top=ceny-hei;
  float bottom=ceny+hei;
  float front=-1.0;
  float back=0.5;
  float scale=2.0/(2.0*front);
  float crazy=0.1234567;
  int steps=20;
  int jump=1;
  int frames=30;
  JBmp *b=new JBmp(scrwid,scrhei);
  allegrosetup(scrwid,scrhei);
//  makepalette(&greypalette);
  _farsetsel(screen->seg);
  randomise();
  Map2d<float> *map=new Map2d<float>(scrhei,scrhei);
  for (int frame=0;frame<frames;frame++) {
    float angle=pi*(float)frame/(float)frames;
    for (int i=0;i<scrwid;i+=jump) {
      for (int j=0;j<scrhei;j+=jump) {
        // b->setpixelud(indent+i,j,255);
        // b->writetoscreen();
        int col=0;
        V3d tmp=V3d(left+2.0*wid*i/(float)scrwid,top+2.0*hei*j/(float)scrhei,0);
        tmp=V3d::rotate(tmp,V3d(0,1,0),angle);
        current=Quaternion(tmp.x,tmp.y,tmp.z,0);
        b->bmp[j][i]=julquat(Quaternion(0,0,0,0));
        if (key[KEY_SPACE])
          exit(0);
      }
    b->writetoscreen();
    }
//    PALETTE pal;
//    get_palette(pal);
//    save_bitmap(getnextfilename("bmp"),screen,pal);
  } while (!key[KEY_SPACE]);
  allegro_exit();
}
