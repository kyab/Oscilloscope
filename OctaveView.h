//
//  OctaveView.h
//  Oscilloscope
//
//  Created by koji on 11/03/02.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CoreAudioInputProcessor.h"
#include <vector>
#include <deque>
#include <complex>

typedef std::complex<double> Dcomplex;
typedef std::vector<Dcomplex>  Spectrum;

@interface OctaveView : NSView {
	id _processor;	//or sound buffer
	float _start_freq;
	float _stop_freq;
	
	Spectrum _spectrum;
	
}

- (void)setProcessor:(CoreAudioInputProcessor *)processor;


@end
