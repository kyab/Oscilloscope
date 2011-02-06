/*
 *  fft.h
 *  AiffPlayer
 *
 *  Created by koji on 11/02/05.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include <vector>
#include <complex>
#include <math.h>

using namespace std;

void slowForwardFFT(complex<double> *samples, int length, complex<double> *result);
void fastForwardFFT(complex<double> *samples, int length, complex<double> *result);
void DFT(complex<double> *samples, int length, complex<double> *result);