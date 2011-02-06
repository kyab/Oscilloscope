//
//  SpectrumView.h
//  AiffPlayer
//
//  Created by koji on 11/01/31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CoreAudioInputProcessor.h"

@interface SpectrumView : NSView {
	id _processor;	//or sound buffer
	
}

- (void)setProcessor:(CoreAudioInputProcessor *)processor;

@end
