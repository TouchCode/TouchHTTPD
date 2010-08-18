//
//  CSecureTransportConnection.m
//  TouchCode
//
//  Created by Jonathan Wight on 04/07/08.
//  Copyright 2008 toxicsoftware.com. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "CSecureTransportConnection.h"

static OSStatus MySSLReadFunc(SSLConnectionRef connection, void *data, size_t *dataLength);
static OSStatus MySSLWriteFunc(SSLConnectionRef connection, const void *data, size_t *dataLength);

@interface CSecureTransportConnection ()

@property (readwrite, assign) SSLContextRef context;
@property (readwrite, retain) NSMutableData *inputBuffer;

@end

@implementation CSecureTransportConnection

@synthesize certificates;
@synthesize inputBuffer;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	self.inputBuffer = [NSMutableData data];
	}
return(self);
}

- (void)dealloc
{
self.certificates = NULL;
self.context = NULL;
self.inputBuffer = NULL;

[super dealloc];
}

#pragma mark -

- (SSLContextRef)context
{
if (context == NULL)
	{
	SSLContextRef theContext;
	OSStatus theStatus = SSLNewContext(YES, &theContext);
	if (theStatus != noErr)
		[NSException raise:NSGenericException format:@"SSLNewContext failed with %d", theStatus];

	theStatus = SSLSetIOFuncs(theContext, MySSLReadFunc, MySSLWriteFunc);
	if (theStatus != noErr)
		[NSException raise:NSGenericException format:@"SSLSetIOFuncs failed with %d", theStatus];

	theStatus = SSLSetCertificate(theContext, (CFArrayRef)self.certificates);
	if (theStatus != noErr)
		[NSException raise:NSGenericException format:@"SSLSetCertificate failed with %d", theStatus];

	theStatus = SSLSetConnection(theContext, self);
	if (theStatus != noErr)
		[NSException raise:NSGenericException format:@"SSLSetConnection failed with %d", theStatus];

	SSLSessionState theState;
	theStatus = SSLGetSessionState(theContext, &theState);
	if (theStatus != noErr)
		[NSException raise:NSGenericException format:@"SSLSetConnection failed with %d", theStatus];

	context = theContext;
	}
return(context);
}

- (void)setContext:(SSLContextRef)inContext
{
if (context != inContext)
	{
	if (context)
		{
		SSLDisposeContext(context);
		}
	context = inContext;
	}
}

#pragma mark -

- (void)close
{
[super close];
}

- (void)dataReceived:(NSData *)inData
{
[self.inputBuffer appendData:inData];

SSLSessionState theState;
OSStatus theStatus = SSLGetSessionState(self.context, &theState);
if (theStatus != noErr)
	[NSException raise:NSGenericException format:@"SSLGetSessionState failed with %d", theStatus];
if (theState == kSSLIdle || theState == kSSLHandshake)
	{
	theStatus = SSLHandshake(self.context);
	if (theStatus != noErr && theStatus != errSSLWouldBlock)
		[NSException raise:NSGenericException format:@"SSLHandshake failed with %d", theStatus];
	}
else if (theState >= kSSLConnected)
	{
	size_t theBufferLength = 0;
	theStatus = SSLGetBufferedReadSize(self.context, &theBufferLength);
	if (theStatus != noErr)
		[NSException raise:NSGenericException format:@"SSLGetBufferedReadSize failed with %d", theStatus];

	if (theBufferLength > 0)
		{
		NSMutableData *theData = [NSMutableData dataWithLength:theBufferLength];
		size_t theProcessedLength = 0;
		theStatus = SSLRead(self.context, [theData mutableBytes], theBufferLength, &theProcessedLength);
		theData.length = theProcessedLength;
		if (theStatus != noErr)
			[NSException raise:NSGenericException format:@"SSLRead failed with %d", theStatus];
		[super dataReceived:theData];
		}
	}
}

@end

static OSStatus MySSLReadFunc(SSLConnectionRef inConnection, void *data, size_t *dataLength)
{
CSecureTransportConnection *theConnection = (CSecureTransportConnection *)inConnection;

const size_t theBufferLength = theConnection.inputBuffer.length;
const size_t theActualDataLength = MIN(*dataLength, theBufferLength);

[theConnection.inputBuffer getBytes:data length:theActualDataLength];

if (theActualDataLength < theBufferLength)
	theConnection.inputBuffer = [NSMutableData dataWithBytes:(char *)theConnection.inputBuffer.mutableBytes + theActualDataLength length:theBufferLength - theActualDataLength];
else
	theConnection.inputBuffer = [NSMutableData data];

if (theActualDataLength < *dataLength)
	{
	*dataLength = theActualDataLength;
	return(errSSLWouldBlock);
	}
else
	{
	*dataLength = theActualDataLength;
	return(noErr);
	}
}

static OSStatus MySSLWriteFunc(SSLConnectionRef inConnection, const void *data, size_t *dataLength)
{
CSecureTransportConnection *theConnection = (CSecureTransportConnection *)inConnection;
NSData *theData = [NSData dataWithBytesNoCopy:(void *)data length:*dataLength freeWhenDone:NO];
[theConnection sendData:theData];
return(noErr);
}
