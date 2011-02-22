/*
 *  fft.cpp
 *  AiffPlayer
 *
 *  Created by koji on 11/02/05.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "fft.h"
#include <iostream>

static const double PI = M_PI;//3.1415926536;

typedef double (*window_func)(double);


static double hamming_window(double x){
	return 0.54 - 0.46*cos(2*PI*x);
}

static double hann_window(double x){
	return 0.5 - 0.5*cos(2*PI*x);
}

static double blackman_window(double x){
	return 0.42 -0.5*cos(2*PI*x) + 0.08*cos(4*PI*x);
}

static double zero_window(double x){
	return 0;
}

static void slowFFTRecursion(
							 complex<double> *samples, 
							 int length, 
							 int start, 
							 int skip, 
							 complex<double>*result){
	
	if (length == 1){
		*result = samples[start];
		return;
	}
	
	//compute half size
	slowFFTRecursion( samples, length/2, start, skip*2, result);
	slowFFTRecursion( samples, length/2, start + skip, skip*2, result + length/2);
	
	//compute sums and differences of pairs
	for (int j = 0 ; j < length/2; j++){
		complex<double> t = result[j+length/2] * polar(1.0, -2*PI*j/length);
		
		result[j + length / 2] = result[j] - t;
		result[j] += t;
	}	
}
	

void slowForwardFFT(complex<double> *samples, int length, complex<double> *result){
	slowFFTRecursion(samples, length, 0, 1, result);
}

static void windowing(complex<double> *samples, int length, window_func func){
	for (int i = 0 ; i < length ; i++){
		samples[i] *= func((double)i/(length-1));
	}
	
}	

static void rearrange(complex<double> *samples, int length){
	//printf("size of int = %lu\n", sizeof(int));
	
	//windowing
	windowing(samples, length, hann_window);
	
	static unsigned int rearrangeSize = 0;	//size of rearrange table
	static unsigned int *rearrange = 0;
	
	if (rearrangeSize != length){
		if(rearrange) delete [] rearrange;
		rearrange = new unsigned int[length];
		
		rearrange[0] = 0;
		for (unsigned int limit = 1, bit=length/2; limit < length; limit <<=1, bit >>= 1){
			for (int i = 0; i < limit; i++){
				rearrange[i + limit] = rearrange[i] + bit;
			}
		}
		
		for (int i = 0; i < length; i++) {
			if (rearrange[i] == i) rearrange[i] = 0;
			else rearrange[ rearrange[i] ] = 0;
		}
		rearrangeSize = length;
	}
	
	//use the rearrange table to swap elements
	complex<double> t;
	for (int i = 0 ; i < length; i++){
		if (rearrange[i]){
			t = samples[i];
			samples[i] = samples[ rearrange[i] ];
			samples[ rearrange[i] ] = t;
		}
	}
	
}

void fastForwardFFT(complex<double> *samples_org, int length, complex<double> *result){
	for (int i = 0 ; i < length ; i++){
		result[i] = samples_org[i];
		//result[i] *= std::polar(1.0, -2.3);// * 3.2;
	}
	
	rearrange(result, length);
	
	for (int halfSize = 1; halfSize < length; halfSize *= 2){
		complex<double> phaseShiftStep = std::polar(1.0, -PI/halfSize);
		complex<double> currentPhaseShift(1,0);
		
		for (int fftStep = 0; fftStep < halfSize; fftStep++){
			for (int i= fftStep ; i < length; i += 2*halfSize){
				complex<double> t = currentPhaseShift * result[ i + halfSize];
				result[i + halfSize] = result[i] - t;
				result[i] += t;
				
			}
	 		currentPhaseShift *= phaseShiftStep;
		}
		
		//std::cout << currentPhaseShift << "\n";
	}
	
}
	
void DFT(complex<double> *samples, int length, complex<double> *result){
	for (int f = 0; f < length; f++){
		result[f] = complex<double>(0.0);
		for (int t = 0 ; t < length; t++){
			complex<double> val = samples[t];
			result[f] += val * polar(1.0, -2*PI*f*t/length);
		}
	}
}
	