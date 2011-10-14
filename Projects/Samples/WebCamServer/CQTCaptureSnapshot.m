//
//  CQTCaptureSnapshot.m
//  TouchCode
//
//  Created by Jonathan Wight on 03/12/08.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of toxicsoftware.com.

#import "CQTCaptureSnapshot.h"

#import <QTKit/QTKit.h>
#import <QuartzCore/QuartzCore.h>

@implementation CQTCaptureSnapshot

@synthesize session;
@synthesize image;
@synthesize jpegData;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	self.session = [[[QTCaptureSession alloc] init] autorelease];
	
	NSError *theError;
	
	QTCaptureDevice *theDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
	[theDevice open:&theError];
	QTCaptureDeviceInput *theInput = [QTCaptureDeviceInput deviceInputWithDevice:theDevice];
	[self.session addInput:theInput error:&theError];
	
	QTCaptureVideoPreviewOutput *theOutput = [[[QTCaptureVideoPreviewOutput alloc] init] autorelease];
	theOutput.delegate = self;
	[self.session addOutput:theOutput error:&theError];
	
	[self.session startRunning];

	while (self.image == NULL)
		{
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		}
	}
return(self);
}

- (void)dealloc
{
[self.session stopRunning];
self.session = NULL;

[super dealloc];
}

- (NSData *)jpegData
{
if (jpegData == NULL && self.image)
	{
	CGRect theExtent = [self.image extent];

	if (theExtent.size.width <= 0.0 || theExtent.size.height <= 0.0) [NSException raise:NSGenericException format:@"Cannot create CGImage from CIImage with zero extents"];

	const size_t theRowBytes = theExtent.size.width * 4;
	const size_t theSize = theRowBytes * theExtent.size.height;

	NSMutableData *theData = [NSMutableData dataWithLength:theSize];
	if (theData == NULL) [NSException raise:NSGenericException format:@"Could not create data."];

	CGColorSpaceRef theColorSpace = CGColorSpaceCreateDeviceRGB();
	if (theColorSpace == NULL) [NSException raise:NSGenericException format:@"CGColorSpaceCreateDeviceRGB() failed."];

	CGContextRef theBitmapContext = CGBitmapContextCreate([theData mutableBytes], theExtent.size.width, theExtent.size.height, 8, theRowBytes, theColorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
	if (theBitmapContext == NULL) [NSException raise:NSGenericException format:@"theBitmapContext() failed."];

	CIContext *theCoreImageContext = [CIContext contextWithCGContext:theBitmapContext options:0];
	if (theCoreImageContext == NULL) [NSException raise:NSGenericException format:@"Coult not create CIContext"];

	[theCoreImageContext drawImage:self.image inRect:theExtent fromRect:theExtent];
	CFRelease(theBitmapContext);

	CGDataProviderRef theDataProvider = CGDataProviderCreateWithData(NULL, [theData mutableBytes], [theData length], NULL);
	if (theDataProvider == NULL) [NSException raise:NSGenericException format:@"CGDataProviderCreateWithData() failed."];

	CGImageRef theCGImage = CGImageCreate(theExtent.size.width, theExtent.size.height, 8, 32, theRowBytes, theColorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst, theDataProvider, NULL, NO, kCGRenderingIntentDefault);
	if (theCGImage == NULL) [NSException raise:NSGenericException format:@"CGImageCreate() failed."];

	CFRelease(theDataProvider);

	CFRelease(theColorSpace);

	//////////////////////////////////////////////


	theData = [NSMutableData data];

	CGImageDestinationRef theDestination = CGImageDestinationCreateWithData((CFMutableDataRef)theData, CFSTR("public.jpeg"), 1, NULL);
	if (theDestination == NULL)
		[NSException raise:NSGenericException format:@"CGImageDestinationCreateWithURL failed"];
	CGImageDestinationAddImage(theDestination, theCGImage, (CFDictionaryRef)[NSDictionary dictionary]);
	BOOL theResult = CGImageDestinationFinalize(theDestination);
	if (theResult == NO)
		[NSException raise:NSGenericException format:@"CGImageDestinationFinalize failed"];

	CFRelease(theDestination);
	CFRelease(theCGImage);

	self.jpegData = theData;
	}
return(jpegData);
}

- (void)setJpegData:(NSData *)inJpegData
{
if (jpegData != inJpegData)
	{
	[jpegData autorelease];
	jpegData = [inJpegData retain];
    }
}

- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)inVideoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection;
{
#pragma unused (captureOutput, sampleBuffer, connection)

CIImage *theCIImage = [CIImage imageWithCVImageBuffer:inVideoFrame];
self.image = theCIImage;
self.jpegData = NULL;
}

@end
