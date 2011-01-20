//
//  OscilloView.h
//  Oscilloscope
//
//  Created by koji on 11/01/21.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CoreAudioInputProcessor.h"


@interface OscilloView : NSView {
	id _processor;	//something which return left and right buffer
}

-(void)setProcessor:(CoreAudioInputProcessor *)processor;

//override
-(void)drawRect:(NSRect) dirtyRect;
	

@end
