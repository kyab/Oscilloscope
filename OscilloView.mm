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
    }
	
    return self;
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

- (void)drawSample:(const std::vector<float> &)samples{
	
	NSBezierPath *path = [NSBezierPath bezierPath];
	NSRect bounds = [self bounds];
	
	[path setLineWidth:1.0f];
	
	
	float y_addition = bounds.size.height / 2.0f;
	float y_ratio = bounds.size.height / 2.0f;
	
	float samples_per_pixel = float(samples.size())/bounds.size.width;
	UInt32 sample_from = 1;
	UInt32 sample_to = 0;
	
	for (UInt32 pixel = 1; pixel < bounds.size.width/2 ; pixel++){
		sample_to = (UInt32)floor(pixel * samples_per_pixel*2);
		
		float max = samples[sample_from];
		float min = max;
		for(int i =sample_from; i < sample_to; i++){
			float val = samples[i];
			if (val > 0.9) continue;
			if (val < -0.9) continue;
			if (val > max) max = val;
			if (val < min) min = val;
		}
		
		min = (min*y_ratio*0.6) + y_addition;
		max = (max*y_ratio*0.6) + y_addition;
		[path moveToPoint:NSMakePoint(pixel, min)];
		[path lineToPoint:NSMakePoint(pixel, max)];
		
		//oposite side
		[path moveToPoint:NSMakePoint(bounds.size.width - pixel, min)];
		[path lineToPoint:NSMakePoint(bounds.size.width - pixel, max)];
		
		sample_from = sample_to;
	}
	
	[[NSColor greenColor] set];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[path stroke];
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	
}
	

- (void)drawRect:(NSRect)dirtyRect {

	[self drawBackground];

	const std::vector<float> *left = [_processor left];

	if ( (left != NULL) && (left->size() != 0) ){
		size_t copySampleNum = 41000 / 2;
		std::vector<float> flagment = std::vector<float>(copySampleNum, 0.0f);
		
		@synchronized( _processor){
			if (left->size() < copySampleNum) {
				copySampleNum = left->size();
				memcpy(&flagment[0], &(*left)[0],copySampleNum * sizeof(float));
			}else{
				size_t offset = left->size() - copySampleNum;
				memcpy(&flagment[0], &(*left)[offset],copySampleNum * sizeof(float));
			}
		}		

		[self drawSample:flagment];
		
	}
	//NSLog(@"OscilloView:: , no sample");
}

@end
