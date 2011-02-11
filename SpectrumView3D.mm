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

//NOT GOOD!!!! needs simplify

static const int FFT_SIZE = 256 * 8;

static float rad(float degree){
	return 2 * M_PI/ 360 * degree;
}

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
	Point3D &rotateY(float theta){
		mX = mX*cos(theta) - mZ*sin(theta);
		//mY = mY;
		mZ = mX*sin(theta) + mZ*cos(theta);
		return *this;
	}
	Point3D &rotateZ(float theta){
		mX = mX*cos(theta) - mY*sin(theta);
		mY = mX*sin(theta) + mY*cos(theta);
		//mZ = mZ;
		return *this;
	}
	
	float operator[] (int i){
		switch(i){
			case 0:
				return mX;
			case 1:
				return mY;
			case 2:
				return mZ;
			default:
				return 0.0f;
		}
	}
	
	float x(){
		return mX;
	}
	float y(){
		return mY;
	}
	float z(){
		return mZ;
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
	
	NSPoint toNSPoint(){
		return NSMakePoint(mX, mY);
	}
	

};


//world corrdinate is basically [-100 100] for x,y, and z
@implementation SpectrumView3D

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_processor = nil;
								 
    }
    return self;
}
- (void)setProcessor:(CoreAudioInputProcessor *)processor{
	_processor = processor;
	[self setNeedsDisplay:YES];
	
	//TODO: manage timer. only if there are no timer, timer should initialized.
	[NSTimer scheduledTimerWithTimeInterval:1.0f/1
									 target:self
								   selector: @selector(ontimer:)
								   userInfo:nil
									repeats:true];
	
}

- (void)ontimer:(NSTimer *)timer {
	[self setNeedsDisplay:YES];
}

//camera -> screen
- (NSPoint) screenFromCamera:(NSPoint)point{
	NSSize camera_size;
	camera_size.width = 200;
	camera_size.height = 200;
	
	//shift
	float x = point.x + camera_size.width/2.0;
	float y = point.y + camera_size.height/2.0;
	
	NSRect bounds = [self bounds];
	
	//scale
	x = x * bounds.size.width/camera_size.width;
	y = y * bounds.size.height/camera_size.height;
	return NSMakePoint(x,y);
}

//world -> camera -> screen
- (NSPoint)pointXYFrom3DPoint:(Point3D)point3d{
	
	//we should be able to translate
	point3d.rotateY(rad(-40)).rotateX(rad(40));
	NSPoint pointXY = point3d.toCamera(600,1000);		//todo not change this!
	pointXY = [self screenFromCamera:pointXY];
	
	pointXY.x -= [self bounds].size.width/2.2;
	pointXY.y -= 20;
	return pointXY;
}

//TODO: handling nyquist refrection

-(void)drawSpectrum:(const Spectrum &)spectrum index:(int)index{
	NSBezierPath *path = [[NSBezierPath bezierPath] retain];

	int length = spectrum.size()/2;
	for (int i = 0 ; i < length ; i++){
		float amp = abs(spectrum[i])/spectrum.size();

		
		float db = 20 * std::log10(amp);
		if (db < -95){
			//to draw the base line
			db = -96;
		}
		float y = db + 96 + 40/*visible factor*/;
		float z = i;
		
		//scale to world coordinate:[-100,100]
		z = z * 100/length*2/*scale factor*/;
		y = y * 200/96 * 0.1/*scale factor*/;
		float x = float(index) * 200/(_spectrums.size());
		
		Point3D point3d(x,y,z);
		point3d.shift(0,0,0);
		//now cube is in [-100,100] for x,y and z
		
		NSPoint point = [self pointXYFrom3DPoint:point3d];		
		//screen
		if (i == 0){
			[path moveToPoint:point];
		}else{
			[path lineToPoint:point];
		}
	}
	NSColor *color = [NSColor colorWithCalibratedRed:0.5
											green:0.5 
											blue:0.5
											  alpha:1.0];
	//[[NSColor yellowColor] set];
	[color set];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[path stroke];
}



- (void)drawLineFrom:(Point3D) from to:(Point3D)to{
	NSPoint from_xy = [self pointXYFrom3DPoint:from];
	NSPoint to_xy = [self pointXYFrom3DPoint:to];

	[NSBezierPath strokeLineFromPoint:from_xy toPoint:to_xy];
}



- (void)drawText:(NSString *)text atPoint:(Point3D)point3d{
	NSPoint point_xy = [self pointXYFrom3DPoint:point3d];
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSFont fontWithName:@"Monaco" size:14.0f]
				   forKey:NSFontAttributeName];
	[attributes setObject:[NSColor whiteColor]
				   forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *at_text = [[NSAttributedString alloc] initWithString: text
														attributes: attributes];
	[at_text drawAtPoint:point_xy];
//withAttributes:<#(NSDictionary *)attrs#>
}
- (void)drawRect:(NSRect)dirtyRect {

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

	
	{
		Spectrum &spectrum = _spectrums.back();
		vector<complex<double> > buffer = vector<complex<double> >(FFT_SIZE, 0.0);
		const vector<float> *left = [_processor left];
		
		if ((left == NULL) || (left->size() < FFT_SIZE)){
			NSLog(@"not enough samples to get FFT");
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
	
	for(int index = 0; index < _spectrums.size(); index++){
		[self drawSpectrum:_spectrums[index] index:index];
	}

	
	//draw axis
	[[NSColor yellowColor] set];
	[self drawLineFrom:Point3D(0,-100,0) to:Point3D(0,100,0)];
	[self drawLineFrom:Point3D(-200,0,0) to:Point3D(200,0,0)];
	[self drawLineFrom:Point3D(0,0,-250) to:Point3D(0,0,250)];
	
	//draw axis label
	[self drawText:@"time(x)" atPoint:Point3D(200,0,0)];
	[self drawText:@"dB(y)" atPoint:Point3D(0,100,0)];
	[self drawText:@"freq(z)" atPoint:Point3D(0,0,250)];
	

	
}

@end
