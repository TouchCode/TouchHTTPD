//
//  CTCPEchoServer.m
//  TouchCode
//
//  Created by Jonathan Wight on 12/8/08.
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

#import "CTCPEchoServer.h"

#import "CTCPEchoConnection.h"
#import "CTCPSocketListener_Extensions.h"

@implementation CTCPEchoServer

@synthesize socketListener;

- (void)serve
{
self.socketListener = [[[CTCPSocketListener alloc] init] autorelease];
self.socketListener.connectionCreationDelegate = self;
self.socketListener.port = 1234;

NSError *theError = NULL;
if ([self.socketListener serveForever:NO error:&theError] == NO)
	NSLog(@"%@", theError);
}

- (CTCPConnection *)TCPSocketListener:(CTCPSocketListener *)inSocketListener createTCPConnectionWithAddress:(NSData *)inAddress inputStream:(CFReadStreamRef)inInputStream outputStream:(CFWriteStreamRef)inOutputStream
{
CTCPEchoConnection *theConnection = [[[CTCPEchoConnection alloc] initWithAddress:inAddress inputStream:inInputStream outputStream:inOutputStream] autorelease];
return(theConnection);
}

@end
