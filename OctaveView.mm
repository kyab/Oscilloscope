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

template <typename T>
class SimpleRange{
public:
	SimpleRange(const T &start , const T &end){
		m_start = start;
		m_end = end;
	}
	
	T start(){
		return m_start;
	}
	
	T end(){
		return m_end;
	}
	
	T range(){
		return m_end - m_start;
	}
	
private:
	T m_start;
	T m_end;
};


static double linearInterporation(double x0, double y0, double x1, double y1, double x){
	double rate = (x - x0) / (x1 - x0);
	double y = (1.0 - rate)*y0 + rate*y1;
	return y;
}
	
static const int FFT_SIZE = 1024 * 16;
	
@implementation OctaveView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_processor = nil;
		_start_freq = 261.626f;	//C3
		_stop_freq = _start_freq * 2;
		_spectrum = std::vector<Dcomplex>(FFT_SIZE, 0.0);
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
	freqs.push_back(_start_freq);
	
	float note_freq_rate = 1.0594630943593f;
	for (int i=1; i <= 12 ;i++){
		freqs.push_back(freqs[0] * pow(note_freq_rate, i));
		//NSLog(@"freq:%f[Hz]", freqs[i]);
	}
	
	/*linear
	for (int i = 0; i < 12 ; i++){
		float pixel_per_freq = self.bounds.size.width / (_stop_freq - _start_freq);
		float f = freqs[i];
		float x = (f - _start_freq) * pixel_per_freq ;
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x,0)
								   toPoint:NSMakePoint(x,self.bounds.size.height)];
	}
	*/
	//log
	[[NSColor blueColor] set];
	for (int i = 0 ; i < 12 ; i++){
		float f = freqs[i];
		float flog = std::log10(f);
		
		float freq_range_log = std::log10(_stop_freq) - std::log10(_start_freq);
		float pixel_per_freq_log = self.bounds.size.width / freq_range_log;
		float x = (flog -  std::log10(_start_freq)) * pixel_per_freq_log;
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x,0)
								  toPoint:NSMakePoint(x,self.bounds.size.height)];
	}		
		
}
	
-(NSBezierPath *)makeLineForOctave:(int)octave{
	
	static const double C3 = 261.626f;
	SimpleRange<float> freq_range = SimpleRange<float>(C3 * (1.0f + octave), C3 * (1.0f + octave)*2);
	float freq_range_log = std::log10(freq_range.end()) - std::log10(freq_range.start());
	float pixel_per_freq_log = self.bounds.size.width / freq_range_log;
	
	NSBezierPath *path = [[NSBezierPath bezierPath] retain];
		
	//TODO: 横に1オクターブだと狭いかもしれない.3オクターブくらい表示させる？？
	//TODO: ピークが弱いような気がする。単純な線形補完を使ってるからか？
	
	static const int RESOLUTION = 1200;		//how many points to draw in each octave?
	for (int i = 0 ; i < RESOLUTION ; i++){
		float freq = i * freq_range.range()/RESOLUTION + freq_range.start();
		
		double amp = [self calculateAmpForFreq:freq fromSpectrum:_spectrum];
		double db = 20 * std::log10(amp);
		//if (db < -180.0f) db = -180.0f;	//
		float y = (db+96+20) * (self.bounds.size.height) / (96.0+20.0f);
		
		float flog = std::log10(freq);
		float x = (flog -  std::log10(freq_range.start())) * pixel_per_freq_log;
		if (i == 0){
			[path moveToPoint:NSMakePoint(x,y)];
		}else{
			
			[path lineToPoint:NSMakePoint(x,y)];
		}		
	}
	return path;
}
	
-(void)drawOctaves{
	if (_processor == nil ) return;
	
	//getting spectrum from our processor.
	[self getCurrentSpectrum:_spectrum fftSize:_spectrum.size()];
	
	//draw line for each octave
	for (int o = 0 ; o < 4 ; o++){
		NSBezierPath *path = [self makeLineForOctave:o];
		
		//オクターブが上がるほど線を細くする。
		[path setLineWidth:4-o];
		
		float red = 0.5 + 0.5f * o / 2;
		NSColor *color = [NSColor colorWithCalibratedRed:red/*0.5*/
												   green:0.1 
													blue:0.1
												   alpha:0.9];
		[color set];
		[path stroke];
	}
	
}	
	

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor blackColor] set];
	NSRectFill([self bounds]);
	
	//[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	
	[self drawOctaves];
	[self drawLabel];
		
}

@end
