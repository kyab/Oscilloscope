//
//  CoreAudioInputProcessor.m
//  Oscilloscope
//
//  Created by koji on 11/01/20.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CoreAudioInputProcessor.h"
#include <AudioToolbox/AudioFormat.h>
#include "util.h"

#define SUCCEEDED(result) (result == noErr)
#define FAILED(result) (result != noErr)

#define LOGENTER	NSLog(@"enter %@()", NSStringFromSelector(_cmd))



//


//use vector as smart pointer for C-arrays
#include <vector>	
#define Array std::vector	//oops, need temlate typedef of C++0x,,

//callback for audio unit
OSStatus InputProc(
				   void *inRefCon,
				   AudioUnitRenderActionFlags *ioActionFlags,
				   const AudioTimeStamp *inTimeStamp,
				   UInt32 inBusNumber,
				   UInt32 inNumberFrames,
				   AudioBufferList * ioData)
{

	
	//NSLog(@"input proc called");
	/*
    err= AudioUnitRender(InputUnit,
						 ioActionFlags,
						 inTimeStamp, 
						 inBusNumber,     //will be '1' for input data
						 inNumberFrames, //# of frames requested
						 theBufferList);
	*/
	
	CoreAudioInputProcessor *processor = (CoreAudioInputProcessor *)inRefCon;
	return [processor inputComming:ioActionFlags :inTimeStamp :inBusNumber :inNumberFrames :ioData];

}


@implementation CoreAudioInputProcessor

-(void) allocateTempBuffer{
	//main code is copied from RecordAudioToFile sample.
	
	_tempBufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList) +  sizeof(AudioBuffer)); //two channel
	if (_tempBufferList == NULL){
		NSLog(@"failed to allocalte bufferlist");
		return ;
	}
	UInt32 frames = 0;
	UInt32 size = sizeof(UInt32);
	//get the size form device
	OSStatus result = AudioUnitGetProperty(_inputUnit, kAudioDevicePropertyBufferFrameSize,
							   	kAudioUnitScope_Global, 0, &frames, &size);
	IF_FAILED(result,"can not get buffer frame size"){
		return;
	}
	NSLog(@"frame size = %u", frames);
	UInt32 byteSize = frames * sizeof(float);
	
	_tempBufferList->mNumberBuffers = 2;	//2ch
	for (int i = 0; i < 2 ; i++){
		_tempBufferList->mBuffers[i].mNumberChannels = 1;
		_tempBufferList->mBuffers[i].mDataByteSize = byteSize;
		_tempBufferList->mBuffers[i].mData = malloc(byteSize);
		if (_tempBufferList->mBuffers[i].mData == NULL){
			NSLog(@"failed to allocate buffer memory byteSize = %d", byteSize);
			return;
		}
	}
}
	

//find the audio device which name is SoundFlower
-(AudioDeviceID) getSoundFlowerDeviceID{
	
	OSStatus result = noErr;
	UInt32 propSize;
	result = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices,&propSize,NULL);
	if(FAILED(result)){
		NSLog(@"failed to get device list err = %d\n", result);
		return 0;
	}
	
	int nDevices = propSize / sizeof(AudioDeviceID);
	Array<AudioDeviceID> deviceIDs = std::vector<AudioDeviceID>(nDevices);
	
	result = AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &propSize, &deviceIDs[0]);
	if(FAILED(result)){
		NSLog(@"failed to get device list err = %d\n", result);
		return 0;
	}
	
	for (int i = 0; i < nDevices; i++){
		UInt32 size = 256;
		char name[256];
		
		result = AudioDeviceGetProperty(deviceIDs[i], 0,1/*input side*/,kAudioDevicePropertyDeviceName, &size, name);
		NSLog(@"Device: %ld, name = %s", deviceIDs[i], name);
		
		if (strcmp("Soundflower (2ch)", name) == 0){
			AudioDeviceID sf_id = deviceIDs[i];
			NSLog(@"found sound flower: AudioDeviceID=%ld", sf_id);
			return sf_id;
		}
	}
	
	return 0;
}


-(bool)setInputDevice{
	
	OSStatus result = noErr;
	
	//we should enable input and disable output at first.. shit! see TN2091. 
	{
		
		UInt32 enableIO = 1;
	
		result = AudioUnitSetProperty(_inputUnit,
						 kAudioOutputUnitProperty_EnableIO,
						 kAudioUnitScope_Input,
						 1, // input element
						 &enableIO,
						 sizeof(enableIO));
	
		IF_FAILED(result, "failed to enable input."){
			return false;
		}
	
		enableIO = 0;
		AudioUnitSetProperty(_inputUnit,
						 kAudioOutputUnitProperty_EnableIO,
						 kAudioUnitScope_Output,
						 0,   //output element
						 &enableIO,
						 sizeof(enableIO));	
	
		IF_FAILED(result, "failed to disable output."){
			return false;
		}
	}
	
   	AudioDeviceID in = [self getSoundFlowerDeviceID];
	
	//set the current to specified in
	{
		UInt32 size = sizeof(AudioDeviceID);
		//should we init something??	
		
		result = AudioUnitSetProperty(_inputUnit, 
									kAudioOutputUnitProperty_CurrentDevice,
									kAudioUnitScope_Global,
									0,
									&in,
									size);
		IF_FAILED(result, "##Failed to set input device to sound flower!!!"){
			return false;
		}
	}
		
	return true;
}

-(bool)setFormat{
	AudioStreamBasicDescription format;
	UInt32 size = sizeof(AudioStreamBasicDescription);
	
	OSStatus result = noErr;
	result = AudioUnitGetProperty(_inputUnit, kAudioUnitProperty_StreamFormat,
								  	kAudioUnitScope_Input,
								   1, /*input element*/
								  &format,
								  &size);
	IF_FAILED(result ," failed to get stream format"){
		return false;
	}
				
	dump_struct(format);
	NSLog(@"format = %@", EnumToFOURCC(format.mFormatID));
	if (format.mFormatFlags & kAudioFormatFlagIsFloat){
		NSLog(@"format is float");
	}
	if (format.mFormatFlags & kAudioFormatFlagIsNonInterleaved){
		NSLog(@"format is non-interleaved");
	}else{
		NSLog(@"format is interleaved");
	}
	
	// i want to use non-interleaved stereo float(32bit).
	AudioStreamBasicDescription newFormat;
	memcpy(&newFormat, &format, sizeof( newFormat ));
	newFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
	newFormat.mBytesPerPacket = 4;	//for non-interleaved, this should be ok see AudioInputProc sample in Core Audio SDK
	newFormat.mFramesPerPacket = 1;
	newFormat.mBytesPerFrame = 4;
	newFormat.mChannelsPerFrame = 2;	//note a packet include frames
	newFormat.mBitsPerChannel = 32;
	
	//set the output side of input element(1)
	result = AudioUnitSetProperty(_inputUnit, kAudioUnitProperty_StreamFormat,
								  kAudioUnitScope_Output,
								  1, /*input element*/
								  &newFormat,
								  size);
	IF_FAILED(result ," failed to set stream format"){
		if (result == kAudioFormatUnsupportedDataFormatError){
			NSLog(@"Unsupported format error");
		}
		return false;
	}
	
	return true;
}
-(bool)setCallback{
	AURenderCallbackStruct input;
	input.inputProc = InputProc;
	input.inputProcRefCon = self;
	
	OSStatus result = noErr;
	result = AudioUnitSetProperty(
						 _inputUnit, 
						 kAudioOutputUnitProperty_SetInputCallback, 
						 kAudioUnitScope_Global, //somehow, this is global task
						 0,						//so, ignore this.
						 &input, 
						 sizeof(input));
	IF_FAILED(result , "failed to set callback!!"){
		return false;
	}
	
	NSLog(@"succeeded to set callback. now ready to go");
	return true;
		
}





-(bool) initProcessor{
	NSLog(@"init");
	
	OSStatus result = noErr;
	ComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_HALOutput;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	
	Component comp = FindNextComponent(NULL, &desc);
	if (comp == NULL){
		NSLog(@"failed to get HALOutput Audio Component\n");
	}
	
	result = OpenAComponent(comp, &_inputUnit);
	if (_inputUnit == NULL){
		NSLog(@"failed to open Audio HAL Unit. OpenAComponent err = %ld\n", result);
		return false;
	}
	
	result = AudioUnitInitialize(_inputUnit);
	if (FAILED(result)){
		NSLog(@"failed to init Audio HAL Unit. er = %ld\n", result);
		return false;
	}
	
	
	if (![self setInputDevice]) return false;
	if (![self setFormat]) return false;
	if (![self setCallback]) return false;
	
	[self allocateTempBuffer];
	
	return true;
}




-(bool) start{
	NSLog(@"start");
	
	OSStatus result = noErr;
	
	result = AudioUnitInitialize(_inputUnit);
	IF_FAILED(result, "failed to initialize in start()"){
		return false;
	}
	
	result = AudioOutputUnitStart(_inputUnit);
	IF_FAILED(result, "failed to AudioOutputUnitStart() in start()"){
		return false;
	}
	
	NSLog(@"successfully startd Audio Unit Engine for Record");
	return true;
}

-(bool) stop{
	NSLog(@"%s",  _cmd);
	OSStatus result = noErr;
	result = AudioOutputUnitStop(_inputUnit);
	IF_FAILED(result, "failed to AudioOutputUnitStop() in stop()"){
		return false;
	}
	
	
	return true;
}
- (OSStatus) inputComming:(AudioUnitRenderActionFlags *)ioActionFlags :(const AudioTimeStamp *) inTimeStamp:
		(UInt32) inBusNumber: (UInt32) inNumberFrames :(AudioBufferList *)ioData{
	NSLog(@"inputComming, bus number = %u, frames = %u, flag=%d",inBusNumber, inNumberFrames, *ioActionFlags  );

	
	OSStatus result =  AudioUnitRender(
									   	_inputUnit, 
									   ioActionFlags, 
									   inTimeStamp, 
									   inBusNumber, 
									   inNumberFrames, 
									   _tempBufferList
									   ); 
	if (result != noErr){
		NSLog(@"failed to AudioUnitRender");
	}
	float *temp_left = (float *)(_tempBufferList->mBuffers[0].mData);
	float *temp_right = (float *)(_tempBufferList->mBuffers[1].mData);
	NSLog(@"first sample is %+6.5f", temp_left[0]);		//-0.11096, +0.22430,, etc
	
	for (int i = 0 ; i < inNumberFrames; i++){
		left.push_back(temp_left[i]);
		right.push_back(temp_right[i]);
	}
	
	//AudioUnitRener()..
	return noErr;
}


-(std::vector<float> *) left{
	return &left;
}

-(std::vector<float> *) right{
	return &right;
}



@end
