//
//  SpectrumView3D.h
//  Oscilloscope
//
//  Created by koji on 11/02/08.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CoreAudioInputProcessor.h"
#include <vector>
#include <list>
#include <complex>

typedef std::complex<double> Dcomplex;
typedef std::vector<Dcomplex>  Spectrum;

@interface SpectrumView3D : NSView {
	id _processor;	//or sound buffer
	std::list<Spectrum> _spectrums;
	
}

- (void)setProcessor:(CoreAudioInputProcessor *)processor;

@end

