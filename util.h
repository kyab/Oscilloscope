//
//  util.h
//  AiffPlayer
//
//  Created by koji on 11/01/06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#ifndef __UTIL_H__
#define __UTIL_H__

#import <Cocoa/Cocoa.h>

#import "MacRuby/MacRuby.h"
#include <string>
#include <typeinfo>


//demangle function
//http://d.hatena.ne.jp/hidemon/20080731/1217488497
#include <string>


std::string demangle(const char * name);


//dump C struct with MacRuby
//using ruby to meta
template <typename T>
void dump_struct(const T &t){
	const std::type_info &type = typeid(t);
	std::string demangled_type_name = demangle(type.name());
	
	NSValue *v = [NSValue valueWithPointer:&t];
	NSString *typeName = [NSString stringWithCString:demangled_type_name.c_str() encoding:kCFStringEncodingUTF8 ];
	id ruby_util = [[MacRuby sharedRuntime] evaluateString:@"RUtil"];
	[ruby_util performRubySelector:@selector(dump_struct_withName:) withArguments:v,typeName,NULL];
}

//convert enum four cc to human readable
NSString *EnumToFOURCC(UInt32 val);



// macro IF_FAILED(result,message){...}

/*
 usage:
 OSStatus result = SomeAPIReturnsOSStatus(....);
 IF_FAILED(result, "uups failed to SomeAPIReturnsOSStatus")){
 return ;
 }
 
 //in above code . block only exeuted if result != noErr.
 */

#define FAILED_BLOCK(result,message) if ( FailChecker checker = FailChecker(result,message) ){} else
#define IF_FAILED(result,message) if ( FailChecker checker = FailChecker(result,message) ){} else

class FailChecker{
public:
	FailChecker(OSStatus result, const char *msg){
		_result = result;
		if (_result != noErr){
			NSLog(@"%s. err=%d", msg, _result);
		}
	}
	operator bool (){
		return (_result == noErr);
	}
	
private:
	OSStatus _result;
};



#endif //__UTIL_H__
