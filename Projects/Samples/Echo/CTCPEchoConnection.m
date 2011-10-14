//
//  CTCPEchoConnection.m
//  TouchCode
//
//  Created by Jonathan Wight on 03/11/08.
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

#import "CTCPEchoConnection.h"

#import "CMultiInputStream.h"

@implementation CTCPEchoConnection

- (void)dataReceived:(NSData *)inData
{
NSString *theString = [[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding] autorelease];
theString = [theString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
printf("Received: %s\n", [theString UTF8String]);

theString = [NSString stringWithFormat:@"You said ('%@'). I say 'Hello World'.\r\n", theString];
NSData *theData1 = [theString dataUsingEncoding:NSUTF8StringEncoding];

NSArray *theStreams = [NSArray arrayWithObjects:
	[NSInputStream inputStreamWithData:theData1],
	[NSInputStream inputStreamWithData:[@"xyzzy\r\n" dataUsingEncoding:NSUTF8StringEncoding]],
	[NSInputStream inputStreamWithData:[@"<eof>\r\n" dataUsingEncoding:NSUTF8StringEncoding]],
	NULL];

CMultiInputStream *theMultistream = [[[CMultiInputStream alloc] initWithStreams:theStreams] autorelease];

[self sendStream:theMultistream];
}

@end
