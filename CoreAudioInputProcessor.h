//
//  CoreAudioInputProcessor.h
//  Oscilloscope
//
//  Created by koji on 11/01/20.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include <CoreAudio/CoreAudio.h>
#include <AudioUnit/AudioUnit.h>

#include <vector>

@interface CoreAudioInputProcessor : NSObject {
	AudioUnit _inputUnit;
	AudioBufferList *_tempBufferList;
	std::vector<float> left;	//TODO: Make this ring-buffer
	std::vector<float> right;
}

-(bool) initProcessor;
-(bool) start;
-(bool) stop;

-(std::vector<float> *) left;
-(std::vector<float> *) right;

- (OSStatus) inputComming:(AudioUnitRenderActionFlags *)ioActionFlags :(const AudioTimeStamp *) inTimeStamp:
(UInt32) inBusNumber: (UInt32) inNumberFrames :(AudioBufferList *)ioData;


@end
