//
//  SpectrumView.m
//  AiffPlayer
//
//  Created by koji on 11/01/31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SpectrumView3D_mesh.h"
#include <vector>
#include <complex>
#include <iostream>
#include <math.h>

#include "fft.h"
#include "util.h"

#include "math.h"
#import "3d.h"


static const int FFT_SIZE = 128;
static const int SPECTRUM3D_COUNT = 40;



//world corrdinate is basically [-100 100] for x,y, and z

@implementation SpectrumView3D_mesh

@synthesize rotateX = _rotateX,rotateY = _rotateY, rotateZ = _rotateZ;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_processor = nil;
		_rotateX = 64.96;// 30;
		_rotateY = -10.8;//-40;
		_rotateZ = -21.6;
		
    }
    return self;
}
- (void)setProcessor:(CoreAudioInputProcessor *)processor{
	_processor = processor;
	
	//TODO: manage timer instance, timer should initialized. only if there are no timer
	NSTimer *timer = [NSTimer timerWithTimeInterval:1.0f/10
											 target:self
										   selector: @selector(ontimer:)
										   userInfo:nil
											repeats:true];
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	[runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
	
	//fire the timer even in mouse tracking!
	[runLoop addTimer:timer forMode:NSEventTrackingRunLoopMode];
	
	[self setNeedsDisplay:YES];
	
}

- (void)ontimer:(NSTimer *)timer {
	
	//NSLog(@"timer in mode:%@", [[NSRunLoop currentRunLoop] currentMode]);
	[self setNeedsDisplay:YES];
}

//camera -> screen
- (NSPoint) screenFromCamera:(NSPoint)point{
	NSSize camera_size;
	camera_size.width = 300;
	camera_size.height = 300;
	
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
	
	point3d.rotateX(rad(_rotateX)).rotateY(rad(_rotateY)).rotateZ(rad(_rotateZ));

	NSPoint pointXY = point3d.toCamera_noPerspective();
	pointXY = [self screenFromCamera:pointXY];
	
	//tweak shift
	pointXY.x -= [self bounds].size.width/2.2;
	pointXY.y -= 20;
	return pointXY;
}


//周波数毎のライン
-(void)drawVerticalSpectrum{
	for (int f = 0 ; f < FFT_SIZE/2; f+=1){
		NSBezierPath *path = [[NSBezierPath bezierPath] retain];
		for (int i=0; i < _spectrums.size(); i++){
			float amp = abs(_spectrums[i][f])/FFT_SIZE;
			float db = 20 * std::log10(amp);
			if (db < -95){ db = -96;}
			
			float y = db + 96 + 0;
			float z = f;
			z = z * 100/FFT_SIZE*4;
			y = y * 200/96 * 0.4;
			float x = float(i) * 200/(_spectrums.size())*1.3;
			
			Point3D point3d(x,y,z);
			NSPoint point = [self pointXYFrom3DPoint:point3d];
			if (i == 0){
				[path moveToPoint:point];
			}else{
				[path lineToPoint:point];
			}
		}
		[[NSColor yellowColor] set];
		[path stroke];
	}
	
}

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
		
		float y = db + 96 + 0/*visible factor*/;
		float z = i;
		
		//scale to world coordinate:[-100,100]
		z = z * 100/length*2/*scale factor*/;
		y = y * 200/96 * 0.4/*scale factor*/;
		float x = float(index) * 200/(_spectrums.size()) * 1.3/*scale factor*/;
		
		Point3D point3d(x,y,z);
		
		//now point3d is 3D point in world coordinate.
		
		NSPoint point = [self pointXYFrom3DPoint:point3d];		
		if (i == 0){
			[path moveToPoint:point];
		}else{
			[path lineToPoint:point];
		}
	}
	float red = 1.0f * index / _spectrums.size();
	NSColor *color = [NSColor colorWithCalibratedRed:red/*0.5*/
											   green:0.1 
												blue:0.1
											   alpha:0.9];
	[color set];

	//last point to -96 decibel
	/*
	{
		float x,y,z;
		x = float(index) * 200/(_spectrums.size()) * 1.3;
		y = 0.0f;
		y = y * 200/96 * 0.4;
		z = float(length)*100/length*2;
		Point3D point3d(x,y,z);
		NSPoint zeroAtMaxFreq = [self pointXYFrom3DPoint:point3d];
		[path lineToPoint:zeroAtMaxFreq];
	}
	
	{
		float x,y,z;
		x = float(index) * 200/(_spectrums.size()) * 1.3;
		y = 0.0f;
		y = y * 200/96 * 0.4;
		z = 0.0f*100/length*2;
		Point3D point3d(x,y,z);
		NSPoint zeroAtMinFreq = [self pointXYFrom3DPoint:point3d];
		[path lineToPoint:zeroAtMinFreq];
	}*/
	
	
	
	//[path closePath];
	//[path fill];
	[[NSColor yellowColor] set];
	[path stroke];
	
}


- (void)drawLineFrom:(Point3D)from to:(Point3D)to{
	NSPoint from_xy = [self pointXYFrom3DPoint:from];
	NSPoint to_xy = [self pointXYFrom3DPoint:to];
	
	[NSBezierPath strokeLineFromPoint:from_xy toPoint:to_xy];
}


- (void)drawText:(NSString *)text atPoint:(Point3D)point3d{
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSFont fontWithName:@"Monaco" size:14.0f]
				   forKey:NSFontAttributeName];
	[attributes setObject:[NSColor whiteColor]
				   forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *at_text = [[NSAttributedString alloc] initWithString: text
																  attributes: attributes];
    
    NSPoint point_xy = [self pointXYFrom3DPoint:point3d];
    [at_text drawAtPoint:point_xy];
	
}


- (void)drawRect:(NSRect)dirtyRect {
	
    [[NSColor blackColor] set];
	NSRectFill([self bounds]);
	
	if (_processor == nil) return;
	
	using namespace std;
	
	//draw spectrum(s).
	if (_spectrums.size() > SPECTRUM3D_COUNT){
		_spectrums.pop_front();
	}
	_spectrums.push_back(Spectrum(FFT_SIZE,0.0));
	
	{
		Spectrum &spectrum = _spectrums.back();
		vector<complex<double> > buffer = vector<complex<double> >(FFT_SIZE, 0.0);
		const vector<float> *left = [_processor left];
		
		if ((left == NULL) || (left->size() < FFT_SIZE)){
			//NSLog(@"not enough samples to get FFT");
			return;
		}
		
		//get the fft of latest FFT_SIZE samples.
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
	[self drawVerticalSpectrum]; 
	//draw axis
	
	[[NSColor yellowColor] set];
	[self drawLineFrom:Point3D(0,-100,0) to:Point3D(0,100,0)];
	[self drawLineFrom:Point3D(-100,0,0) to:Point3D(100,0,0)];
	[self drawLineFrom:Point3D(0,0,-100) to:Point3D(0,0,100)];
	
	//draw axis label
	[self drawText:@"time(x)" atPoint:Point3D(200,0,0)];
	[self drawText:@"dB(y)" atPoint:Point3D(0,100,0)];
	[self drawText:@"freq(z)" atPoint:Point3D(0,0,200)];
	
}

@end
