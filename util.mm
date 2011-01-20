//
//  util.m
//  AiffPlayer
//
//  Created by koji on 11/01/06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "util.h"
#include <string>

extern "C" char *__cxa_demangle (
								 const char *mangled_name,
								 char *output_buffer,
								 size_t *length,
								 int *status);

std::string demangle(const char * name) {
    size_t len = strlen(name) + 256;
    char output_buffer[len];
    int status = 0;
    return std::string(
					   __cxa_demangle(name, output_buffer, 
									  &len, &status));
}


NSString *EnumToFOURCC(UInt32 val){
	char cc[5];
	cc[4] = '\0';
	
	char *p = (char *)&val;
	cc[0] = p[3];
	cc[1] = p[2];
	cc[2] = p[1];
	cc[3] = p[0];
	NSString *ret = [NSString stringWithUTF8String:cc];
	
	/* below should same
	 char formatID[5];
	 *(UInt32 *)formatID = CFSwapInt32HostToBig(err);
	 formatID[4] = '\0';
	 fprintf(stderr, "ExtAudioFileSetProperty FAILED! '%-4.4s'\n", formatID);
	 */
	 	
	return ret;
}
