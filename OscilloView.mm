//
//  OscilloView.mm
//  Oscilloscope
//
//  Created by koji on 11/01/21.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OscilloView.h"
#include <vector>

@implementation OscilloView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _processor = nil;
		_showSampleNum = 44100;
    }
	
    return self;
}


-(void)setShowSampleNum:(UInt32) showSampleNum{
	_showSampleNum = showSampleNum;
	[self setNeedsDisplay:YES];
	
}
-(UInt32)showSampleNum{
	return _showSampleNum;
}
- (void)setProcessor:(CoreAudioInputProcessor *)processor{
	_processor = processor;
	
	//TODO: manage timer. only if there are no timer, timer should initialized.
	[NSTimer scheduledTimerWithTimeInterval:0.01  
										target:self
								   selector: @selector(ontimer:)
										userInfo:nil
									repeats:true];
	
}
	
- (void)ontimer:(NSTimer *)timer {
	//NSLog(@"timer");
	[self setNeedsDisplay:YES];
}

- (void)drawBackground{
	[[NSColor blackColor] set];
	NSRectFill([self bounds]);
}

- (void)drawSample_short:(const std::vector<float> &)samples{
	NSBezierPath *path = [NSBezierPath bezierPath];
	NSRect bounds = [self bounds];
	
	[path setLineWidth:1.0f];
	
	float y_addition = bounds.size.height / 2.0f;
	float y_ratio = bounds.size.height / 1.0f;
	
	//move to first point
	float val = (samples[0] * y_ratio) + y_addition;
	[path moveToPoint: NSMakePoint(0,val)];
	
	float pixel = 0.0f;
	for (UInt32 sample = 0;sample < samples.size() ; sample++){
		/*float */pixel = bounds.size.width/(float)samples.size() * sample;
		float val = (samples[sample] ) * y_ratio + y_addition;
		[path lineToPoint: NSMakePoint(pixel, val)];
	}
	
	[[NSColor cyanColor] set];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[path stroke];
	
	
	//NSLog(@"bounds size.width = %f, last pixel = %f", bounds.size.width, pixel);
	//[[NSGraphicsContext currentContext] setShouldAntialias:YES];
}

- (void)drawSample:(const std::vector<float> &)samples{
	
	NSBezierPath *path = [NSBezierPath bezierPath];
	NSRect bounds = [self bounds];
	
	float samples_per_pixel = float(samples.size())/bounds.size.width;
	
	if (samples_per_pixel < 10.0f){
		//shortcut sample drawing
		[self drawSample_short:samples];
		return;
	}
	
	[path setLineWidth:1.0f];
	
	
	float y_addition = bounds.size.height / 2.0f;
	float y_ratio = bounds.size.height / 2.0f;
	
	
	UInt32 sample_from = 1;
	UInt32 sample_to = 0;
	
	for (UInt32 pixel = 1; pixel < bounds.size.width ; pixel++){
		sample_to = (UInt32)floor(pixel * samples_per_pixel);
		
		float max = samples[sample_from];
		float min = max;
		for(int i =sample_from; i < sample_to; i++){
			float val = samples[i];
			if (val > 0.9) continue;
			if (val < -0.9) continue;
			if (val > max) max = val;
			if (val < min) min = val;
		}
		
		min = (min*y_ratio*1.5) + y_addition;
		max = (max*y_ratio*1.5) + y_addition;
		[path moveToPoint:NSMakePoint(pixel, min)];
		[path lineToPoint:NSMakePoint(pixel, max)];
		
		//oposite side
		//[path moveToPoint:NSMakePoint(bounds.size.width - pixel, min)];
		//[path lineToPoint:NSMakePoint(bounds.size.width - pixel, max)];
		
		sample_from = sample_to;
	}
	
	[[NSColor greenColor] set];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[path stroke];
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	
}
	

- (void)drawRect:(NSRect)dirtyRect {

	[self drawBackground];
	std::vector<float> flagment;

	@synchronized( _processor){
		const std::vector<float> *left = [_processor left];
		if ( (left == NULL) || (left->size() == 0) ){
			return;
		}
		
		size_t copySampleNum = _showSampleNum;
		flagment.assign(copySampleNum, 0.0f);
		if (left->size() < copySampleNum) {
			copySampleNum = left->size();
			memcpy(&flagment[0], &(*left)[0],copySampleNum * sizeof(float));
		}else{
			size_t offset = left->size() - copySampleNum;
			memcpy(&flagment[0], &(*left)[offset],copySampleNum * sizeof(float));
		}
	}		
	if (!flagment.empty()) 	[self drawSample:flagment];
		
	//NSLog(@"OscilloView:: , no sample");
}

@end
