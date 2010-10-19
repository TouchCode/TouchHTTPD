//
//  CWireProtocol.m
//  TouchCode
//
//  Created by Jonathan Wight on 04/06/08.
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

#import "CWireProtocol.h"

#import "CTransport.h"

@interface CWireProtocol ()
@end

#pragma mark -

@implementation CWireProtocol

@synthesize lowerLink;
@synthesize upperLink;

- (void)dealloc
{
self.lowerLink = NULL;
self.upperLink = NULL;
//
[super dealloc];
}

#pragma mark -

- (CWireProtocol *)upperLink
{
return(upperLink);
}

- (void)setUpperLink:(CWireProtocol *)inUpperLink
{
if (upperLink != inUpperLink)
	{
	if (upperLink != NULL)
		{
		upperLink.lowerLink = NULL;
		//
		[upperLink release];
		upperLink = NULL;
		}

	if (inUpperLink != NULL)
		{
		upperLink = [inUpperLink retain];
		upperLink.lowerLink = self;
		}
    }
}

- (CTransport *)transport
{
return(self.lowerLink.transport);
}

#pragma mark -

- (void)close
{
if (self.lowerLink)
	[self.lowerLink close];
}

- (void)dataReceived:(NSData *)inData
{
if (self.upperLink)
	[self.upperLink dataReceived:inData];
}

- (size_t)sendData:(NSData *)inData
{
//size_t theCount = 0;
//if (self.lowerLink)
//	theCount = [self.lowerLink sendData:inData];
//return(theCount);

NSInputStream *theStream = [NSInputStream inputStreamWithData:inData];
[self sendStream:theStream];
return(0);
}

- (void)sendStream:(NSInputStream *)inInputStream
{
if (self.lowerLink)
	[self.lowerLink sendStream:inInputStream];
}

@end
