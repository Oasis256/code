#ifndef matrix_H
  #define matrix_H

  #include <ori.h>

/* Skipping later :: V3d Matrix::operator*(V3d u); // Method
*/


/* Skipping later ::  Matrix::Matrix(); // Method
*/


/* Skipping later :: // fillup Matrix Matrix::rotation(V3d axis,float ang); // Method
*/


/* Skipping later :: void Matrix::makerotation(V3d axis,float ang); // Method
*/


/* Skipping later :: void Matrix::makeorientation(Ori o); // Method
*/


Ori operator*(Matrix m,Ori o); // Method


#endif
