//
//  CStreamConnector.m
//  TouchCode
//
//  Created by Jonathan Wight on 11/17/08.
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

#import "CStreamConnector.h"

#import "NSStream_Extensions.h"

@interface CStreamConnector ()
@property (readwrite, retain) NSMutableData *buffer;
@property (readwrite, assign) BOOL connected;

- (void)disconnect;
- (void)read;
- (void)write;

@end

#pragma mark -

@implementation CStreamConnector

@synthesize inputStream;
@synthesize outputStream;
@synthesize delegate;
@synthesize maximumBufferLength;
@synthesize buffer;
@synthesize connected;

+ (id)streamConnectorWithInputStream:(NSInputStream *)inInputStream outputStream:(NSOutputStream *)inOutputStream;
{
return([[[self alloc] initWithInputStream:inInputStream outputStream:inOutputStream] autorelease]);
}

- (id)initWithInputStream:(NSInputStream *)inInputStream outputStream:(NSOutputStream *)inOutputStream
{
if ((self = [self init]) != NULL)
	{
	self.inputStream = inInputStream;
	self.outputStream = inOutputStream;
	self.maximumBufferLength = 16 * 1024; // 16K is proving to be a good size buffer. 
	self.buffer = [NSMutableData dataWithCapacity:self.maximumBufferLength];
	}
return(self);
}

- (void)dealloc
{
[self disconnect];
//
if (self.inputStream.delegate == self)
	self.inputStream.delegate = NULL;
if (self.outputStream.delegate == self)
	self.outputStream.delegate = NULL;

self.inputStream = NULL;
self.outputStream = NULL;
self.delegate = NULL;
self.buffer = NULL;
//
[super dealloc];
}

#pragma mark -

- (void)connect
{
if (self.connected == NO)
	{
	expectingMoreInputFlag = YES;
	self.connected = YES;
	}
}

- (void)disconnect
{
if (self.connected == YES)
	{
	self.connected = NO;
	
	[self.delegate streamConnectorDidFinish:self];
	}
}

- (void)read
{
if (expectingMoreInputFlag && [self.inputStream hasBytesAvailable])
	{
	if (self.buffer.length != 0)
		{
		return;
		}

	self.buffer.length = self.maximumBufferLength;
	NSInteger theBytesRead = [self.inputStream read:self.buffer.mutableBytes maxLength:self.buffer.length];
	if (theBytesRead >= 0)
		{
		self.buffer.length = theBytesRead;
		}
	else if (theBytesRead < 0)
		{
		LOG_(@"ERROR: [CStreamConnector read] %d bytes read.", theBytesRead);
		}
	}
}

- (void)write
{
if ([self.outputStream hasSpaceAvailable])
	{
	NSInteger theBufferLength = self.buffer.length;
	if (theBufferLength > 0)
		{
		NSInteger theBytesWritten = [self.outputStream write:self.buffer.mutableBytes maxLength:theBufferLength];
		if (theBytesWritten == theBufferLength)
			{
			self.buffer = [NSMutableData data];
			}
		else if (theBytesWritten < 0)
			{
			LOG_(@"ERROR: [CStreamConnector read] %d bytes written.", theBytesWritten);

			}
		else if (theBytesWritten < theBufferLength)
			{
			self.buffer = [NSMutableData dataWithBytes:self.buffer.bytes + theBytesWritten length:theBufferLength - theBytesWritten];
			}
		}
	}
}

#pragma mark -

- (void)stream:(NSStream *)inStream handleEvent:(NSStreamEvent)inEventCode
{
if (inEventCode == NSStreamEventErrorOccurred)
	{
	LOG_(@"ERROR with %@ (%@)", inStream, inStream.streamError);
	return;
	}

if (self.connected == NO)
	return;

if (inStream == self.inputStream && inEventCode == NSStreamEventEndEncountered)
	{
	expectingMoreInputFlag = NO;
	}

[self read];

[self write];

if (expectingMoreInputFlag == NO && self.buffer.length == 0)
	{
	[self disconnect];
	}	
}

@end
