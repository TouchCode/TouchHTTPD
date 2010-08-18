//
//  CMultiInputStream.m
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

#import "CMultiInputStream.h"

@interface CMultiInputStream ()
@property (readwrite, retain) NSRunLoop *runLoop;
@property (readwrite, retain) NSString *mode;
@property (readwrite, retain) NSArray *streams;
@property (readwrite, retain) NSInputStream *currentStream;
@property (readwrite, retain) NSInputStream *nextStream;
@property (readwrite, retain) NSEnumerator *enumerator;

- (NSInputStream *)currentStream;
@end

#pragma mark -

@implementation CMultiInputStream

@synthesize runLoop;
@synthesize mode;
@synthesize delegate;
@synthesize streams;
@synthesize enumerator;

- (id)initWithStreams:(NSArray *)inStreams
{
if ((self = [super init]) != NULL)
	{
	self.streams = inStreams;
	self.enumerator = [self.streams objectEnumerator];
	}
return(self);
}

- (void)dealloc
{
self.delegate = NULL;
self.runLoop = NULL;
self.mode = NULL;
self.streams = NULL;
self.currentStream = NULL;
self.enumerator = NULL;
//
[super dealloc];
}

#pragma mark -

- (NSInputStream *)currentStream
{
if (currentStream == NULL)
	{
	currentStream = self.nextStream;
	}

return(currentStream);
}


- (void)setCurrentStream:(NSInputStream *)inCurrentStream
{
if (currentStream != inCurrentStream)
	{
	[currentStream autorelease];
	currentStream = [inCurrentStream retain];
    }
}

- (NSInputStream *)nextStream
{
if (currentStream)
	{
	[currentStream removeFromRunLoop:self.runLoop forMode:self.mode];
	currentStream.delegate = NULL;
	[currentStream close];
	}

NSInputStream *theNextStream = [self.enumerator nextObject];
if (theNextStream)
	{
	[theNextStream scheduleInRunLoop:self.runLoop forMode:self.mode];
	theNextStream.delegate = self;
	[theNextStream open];
	}

return(theNextStream);
}


#pragma mark -

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)inMode
{
self.runLoop = aRunLoop;
self.mode = inMode;
}

- (void)open
{
[self.currentStream open];
}

- (void)close
{
[self.currentStream close];
self.enumerator = NULL;
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
NSInteger theReadLength = 0;

theReadLength = [self.currentStream read:buffer maxLength:len];

return(theReadLength);
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len
{
#pragma unused(buffer, len)
return(NO);
}

- (BOOL)hasBytesAvailable
{
return([self.currentStream hasBytesAvailable] || self.currentStream != [self.streams lastObject]);
}

#pragma mark -

- (NSStreamStatus)streamStatus
{
return([self.currentStream streamStatus]);
}

- (NSError *)streamError
{
return([self.currentStream streamError]);
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode;
{
#pragma unused(aStream)

if (eventCode == NSStreamEventEndEncountered)
	{
	self.currentStream = [self nextStream];
	if (self.currentStream != NULL)
		return;
	}

@try
	{
	[self.delegate stream:self handleEvent:eventCode];
	}
@catch (NSException *e)
	{
	LOG_(@"#### Exception caught: %@", e);
	}
}

@end
