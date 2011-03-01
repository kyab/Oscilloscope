//
//  OctaveView.mm
//  Oscilloscope
//
//  Created by koji on 11/03/02.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OctaveView.h"
#include "fft.h"
#include <math.h>

static double linearInterporation(double x0, double y0, double x1, double y1, double x){
	double rate = (x - x0) / (x1 - x0);
	double y = (1.0 - rate)*y0 + rate*y1;
	return y;
}
	
@implementation OctaveView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_processor = nil;
		_start = 1046;	//C5
		_stop = _start * 2;
    }
    return self;
}

- (void)setProcessor:(CoreAudioInputProcessor *)processor{
	_processor = processor;
	
	//TODO: manage timer instance, timer should initialized. only if there are no timer
	NSTimer *timer = [NSTimer timerWithTimeInterval:1.0f/20
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

-(void)getCurrentSpectrum:(Spectrum &) spectrum fftSize:(int)fftSize{
	using namespace std;
	
	vector<complex<double> > buffer = vector<complex<double> >(fftSize, 0.0);
	const vector<float> *left = [_processor left];
	
	if ((left == NULL) || (left->size() < fftSize)){
		return;
	}
	@synchronized( _processor ){
		int offset = left->size() - fftSize;
		for (int i = 0 ; i < fftSize; i++){
			buffer[i] = (*left)[i + offset];
		}
	}
	fastForwardFFT(&buffer[0], fftSize, &spectrum[0]);
}

	

-(double)calculateAmpForFreq:(double)freq fromSpectrum:(const Spectrum &)spectrum{

	
	//assume sampling rate = 44.1kHz
	static const double SAMPLING_RATE = 44100.0;
	
	double freq_left = 0;
	double freq_right = 0;
	double amp_left = 0;
	double amp_right = 0;
	//find the neaest 
	
	//TODO:ここの計算がめちゃくちゃ。書きなおし！！
	
	//get neaest index
	//double freq_per_index = SAMPLING_RATE / spectrum.size()
	int i = static_cast<int> (floor(freq / (SAMPLING_RATE/spectrum.size())));
	for( ; i < spectrum.size() ; i++){
		double f = SAMPLING_RATE/spectrum.size() * i;
		if (f < freq){
			freq_left = f;
			amp_left = abs(spectrum[i])/spectrum.size();
		}else{
			freq_right = f;
			amp_right = abs(spectrum[i])/spectrum.size();
			
			break;
		}
	}
	
	//線形補間
	double amp = linearInterporation(freq_left, amp_left, freq_right, amp_right, freq);
	//NSLog(@"calculate amp. target freq=%f, [%f to %f]", freq, freq_left, freq_right);
	//NSLog(@"calculate amp. target amp=%f, [%f to %f]", amp, amp_left, amp_right);
	return amp;
	
}

-(void)drawLabel{
	
	std::vector<float>freqs;
	freqs.push_back(_start);
	
	float note_freq_rate = 1.0594630943593f;
	for (int i=1; i <= 12 ;i++){
		freqs.push_back(freqs[0] * pow(note_freq_rate, i));
		//NSLog(@"freq:%f[Hz]", freqs[i]);
	}
	
	for (int i = 0; i < 12 ; i++){
		float pixel_per_freq = self.bounds.size.width / (_stop - _start);
		float f = freqs[i];
		float x = (f - _start) * pixel_per_freq ;
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x,0)
								   toPoint:NSMakePoint(x,self.bounds.size.height)];
	}
}

-(void)drawOctaves{
	if (_processor == nil ) return;
	
	static const int FFT_SIZE = 1024 * 16;
	
	using namespace std;
	
	static Spectrum spectrum = vector<Dcomplex>(FFT_SIZE,0.0);
	[self getCurrentSpectrum:spectrum fftSize:spectrum.size()];
	
	NSBezierPath *path = [[NSBezierPath bezierPath] retain];
	
	int start = _start, stop = _stop ;
	for (int f = start; f < stop ; f+=2){
		double amp = [self calculateAmpForFreq:f fromSpectrum:spectrum];
		double db = 20 * std::log10(amp);
		
		float pixel_per_freq = self.bounds.size.width / (stop-start);
		float x = (f - (start)) * pixel_per_freq ;
		float y = (db+96+30) * (self.bounds.size.height) / 96.0f;
		if (f == start){
			[path moveToPoint:NSMakePoint(x,y)];
		}else{
			[path lineToPoint:NSMakePoint(x,y)];
		}
	}
	
	
	[[NSColor yellowColor] set];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[path stroke];
}	
	

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor blackColor] set];
	NSRectFill([self bounds]);
	
	
	[self drawOctaves];
	[self drawLabel];
		
}

@end
