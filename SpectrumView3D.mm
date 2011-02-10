//
//  SpectrumView.m
//  AiffPlayer
//
//  Created by koji on 11/01/31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SpectrumView3D.h"
#include <vector>
#include <complex>
#include <iostream>
#include <math.h>

#include "fft.h"
#include "util.h"

#include "math.h"

static const int FFT_SIZE = 1024 * 2;

class Point3D{
	
private:
	float mX,mY,mZ;
	void update(float x,float y, float z){
		mX = x;
		mY = y;
		mZ = z;
	}
public:
	Point3D(float x,float y,float z){
		update(x,y,z);
	}
	
	Point3D &rotateX(float theta){
		//mX = mX;
		mY = mY * cos(theta) + mZ * sin(theta);
		mZ = -mY * sin(theta) + mZ * cos(theta);
		return *this;
	}
	const Point3D &rotateY(float theta){
		mX = mX*cos(theta) - mZ*sin(theta);
		//mY = mY;
		mZ = mX*sin(theta) + mZ*cos(theta);
		return *this;
	}
	const Point3D &rotateZ(float theta){
		mX = mX*cos(theta) - mY*sin(theta);
		mY = mX*sin(theta) + mY*cos(theta);
		//mZ = mZ;
		return *this;
	}
	
	Point3D copy(){
		return Point3D(mX,mY,mZ);
	}
	
	Point3D &shift(float x, float y, float z){
		mX += x;
		mY += y;
		mZ += z;
		return *this;
	}
	
	Point3D &scale(float x, float y, float z){
		mX *= x;
		mY *= y;
		mZ *= z;
		return *this;
	}
	
	NSPoint toCamera(float d1, float d2){
		float cameraX = mX * d1 / (d2 + mZ);
		float cameraY = mY * d1 / (d2 + mZ);
		return NSMakePoint(cameraX, cameraY);
	}
	
};

@implementation SpectrumView3D

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_processor = nil;
		for (int i = 0 ; i < 10 ; i++){
			//_spectrums.push_back(Spectrum(FFT_SIZE, 0.0));
		}
								 
    }
    return self;
}
- (void)setProcessor:(CoreAudioInputProcessor *)processor{
	_processor = processor;
	[self setNeedsDisplay:YES];
	
	//TODO: manage timer. only if there are no timer, timer should initialized.
	[NSTimer scheduledTimerWithTimeInterval:0.03 
									 target:self
								   selector: @selector(ontimer:)
								   userInfo:nil
									repeats:true];
	
}

- (void)ontimer:(NSTimer *)timer {
	//NSLog(@"timer");
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
//	const int FFT_SIZE = 1024 * 2;
    [[NSColor blackColor] set];
	NSRectFill([self bounds]);
	
	if (_processor == nil) return;
	using namespace std;
	
	//get the fft of current samples
	//new fft result has bigger index.
	if (_spectrums.size() > 10){
		_spectrums.pop_front();
	}
	_spectrums.push_back(Spectrum(FFT_SIZE,0.0));
	Spectrum &spectrum = _spectrums.back();
	
	//vector<complex <double> > spectrum = vector<complex<double> >(FFT_SIZE,0.0);
	{
		vector<complex<double> > buffer = vector<complex<double> >(FFT_SIZE, 0.0);
		const vector<float> *left = [_processor left];
		
		if ((left == NULL) || (left->size() < FFT_SIZE)){
			return;
		}
		@synchronized( _processor ){
			int offset = left->size() - FFT_SIZE;
			for (int i = 0 ; i < FFT_SIZE; i++){
				buffer[i] = (*left)[i + offset];
			}
		}
		fastForwardFFT(&buffer[0], FFT_SIZE, &(spectrum[0]));
	}
	
	
	NSRect bounds = [self bounds];
	
	
	NSBezierPath *path = [[NSBezierPath bezierPath] retain];
	[path moveToPoint:NSMakePoint(0,0)];
	for (int i = 0 ; i < spectrum.size() ; i++){
		float amp = abs(spectrum[i])/spectrum.size();
		float x = bounds.size.width*2 / spectrum.size() * i;
		
		float db = 20 * std::log10(amp);
		float y = (db+96) * (bounds.size.height)/96.0f ;
		
		double theta = 2 * M_PI / 360 * 6;// rotation for z-axis
		
		float newX = x * cos(theta) - y * sin(theta);
		float newY = x * sin(theta) + y * cos(theta);
		//[path lineToPoint:NSMakePoint(x,y)];
		[path lineToPoint:NSMakePoint(newX,newY)];
	}
	[[NSColor yellowColor] set];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[path stroke];

	
}

@end
