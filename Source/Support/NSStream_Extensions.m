//
//  NSStream_Extensions.m
//  TouchCode
//
//  Created by Jonathan Wight on 12/6/08.
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

#import "NSStream_Extensions.h"

@implementation NSStream (NSStream_Extensions)

+ (NSString *)stringForStatus:(NSStreamStatus)inStatus
{
switch (inStatus)
	{
	case NSStreamStatusNotOpen:
		return(@"NSStreamStatusNotOpen");
	case NSStreamStatusOpening:
		return(@"NSStreamStatusOpening");
	case NSStreamStatusOpen:
		return(@"NSStreamStatusOpen");
	case NSStreamStatusReading:
		return(@"NSStreamStatusReading");
	case NSStreamStatusWriting:
		return(@"NSStreamStatusWriting");
	case NSStreamStatusAtEnd:
		return(@"NSStreamStatusAtEnd");
	case NSStreamStatusClosed:
		return(@"NSStreamStatusClosed");
	case NSStreamStatusError:
		return(@"NSStreamStatusError");
	}
return(NULL);
}

+ (NSString *)stringForEvent:(NSStreamEvent)inEvent
{
switch (inEvent)
	{
	case NSStreamEventNone:
		return(@"NSStreamEventNone");
	case NSStreamEventOpenCompleted:
		return(@"NSStreamEventOpenCompleted");
	case NSStreamEventHasBytesAvailable:
		return(@"NSStreamEventHasBytesAvailable");
	case NSStreamEventHasSpaceAvailable:
		return(@"NSStreamEventHasSpaceAvailable");
	case NSStreamEventErrorOccurred:
		return(@"NSStreamEventErrorOccurred");
	case NSStreamEventEndEncountered:
		return(@"NSStreamEventEndEncountered");
	}
return(NULL);
}

@end

#pragma mark -

@implementation NSInputStream (NSStream_Extensions)

- (NSString *)description
{
return([NSString stringWithFormat:@"%@ (status: %@, hasBytes: %d)", [super description], [[self class] stringForStatus:[self streamStatus]], [self hasBytesAvailable]]);
}

@end

#pragma mark -

@implementation NSOutputStream (NSStream_Extensions)

- (NSString *)description
{
return([NSString stringWithFormat:@"%@ (status: %@, hasSpace: %d)", [super description], [[self class] stringForStatus:[self streamStatus]], [self hasSpaceAvailable]]);
}

@end
