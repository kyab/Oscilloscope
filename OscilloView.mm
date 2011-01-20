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
	
	//TODO:need start the timer
}
	

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
	
	[[NSColor blackColor] set];
	NSRectFill([self bounds]);
	
	const std::vector<float> *left;

	left = [_processor left];
	if ( (left != NULL) && (left->size() != 0) ){
			//TODO:make path and render
			//actual code should be here;
	}
	
	

	
}

@end
