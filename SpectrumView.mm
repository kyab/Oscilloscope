//
//  SpectrumView.m
//  AiffPlayer
//
//  Created by koji on 11/01/31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SpectrumView.h"
#include <vector>
#include <complex>
#include <iostream>

#include "fft.h"
#include "util.h"

@implementation SpectrumView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_processor = nil;
    }
    return self;
}
- (void)setProcessor:(CoreAudioInputProcessor *)processor{
	_processor = processor;
	[self setNeedsDisplay:YES];
	
	//TODO: manage timer. only if there are no timer, timer should initialized.
	[NSTimer scheduledTimerWithTimeInterval:0.05  
									 target:self
								   selector: @selector(ontimer:)
								   userInfo:nil
									repeats:true];
	
}

- (void)ontimer:(NSTimer *)timer {
	//NSLog(@"timer");
	[self setNeedsDisplay:YES];
}

/*
-(void)updateCurrentFrame:(id)sender{
	NSLog(@"spectrum view: notified aiff play position change") ;
	[self setNeedsDisplay:YES];
}*/

- (void)drawRect:(NSRect)dirtyRect {

    [[NSColor blackColor] set];
	NSRectFill([self bounds]);
	
	if (_processor == nil) return;
	using namespace std;
	//vector<complex <double> > spectrum  = [_aiff getSlowFFTBuffer];
	//vector<complex <double> > spectrum  = [_aiff getFastFFTBuffer];
	//vector<complex <double> > spectrum  = [_aiff getDFTBuffer];
	
	//get the fft of current samples
	vector<complex <double> > spectrum = vector<complex<double> >(1024,0.0);
	{
		vector<complex<double> > buffer = vector<complex<double> >(1024, 0.0);
		const vector<float> *left = [_processor left];
		
		if ((left == NULL) || (left->size() < 1024)){
			return;
		}
		@synchronized( _processor ){
			int offset = left->size() - 1024;
			for (int i = 0 ; i < 1024; i++){
				buffer[i] = (*left)[i + offset];
			}
		}
		fastForwardFFT(&buffer[0], 1024, &spectrum[0]);
	}
		
	
	//NSLog(@" spectrum size = %d", spectrum.size());
	
	NSRect bounds = [self bounds];
	
	Timer timer; timer.start();
	
	NSBezierPath *path = [[NSBezierPath bezierPath] retain];
	[path moveToPoint:NSMakePoint(0,0)];
	for (int i = 0 ; i < spectrum.size() ; i++){
		//std::cout << spectrum[i] << std::endl;
		float amp = abs(spectrum[i])/spectrum.size();
		float x = bounds.size.width*2 / spectrum.size() * i;
		
		float db = 20 * std::log10(amp);
		float y = (db+96) * (bounds.size.height)/96.0f ;
		[path lineToPoint:NSMakePoint(x,y)];
	}
	[[NSColor yellowColor] set];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[path stroke];
	timer.stop();
	//NSLog(@"drwaing takes %f[msec]", timer.result()*1000);
	
}

@end
