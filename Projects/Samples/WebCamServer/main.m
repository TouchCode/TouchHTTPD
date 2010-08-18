//
//  main.m
//  TouchCode
//
//  Created by Jonathan Wight on 20090528.
//  Copyright 2009 toxicsoftware.com. All rights reserved.
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

#import <Foundation/Foundation.h>

#import "CTCPSocketListener.h"
#import "CTCPEchoConnection.h"
#import "CHTTPConnection.h"
#import "CRoutingHTTPRequestHandler.h"
#import "CNATPMPManager.h"
#import "CHTTPServer.h"
#import "CWebcamHTTPRouter.h"

int main (int argc, const char * argv[])
{
#pragma unused (argc, argv)

NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

CHTTPServer *theHTTPServer = [[[CHTTPServer alloc] init] autorelease];
[theHTTPServer createDefaultSocketListener];

CWebcamHTTPRouter *theRequestRouter = [[[CWebcamHTTPRouter alloc] init] autorelease];

CRoutingHTTPRequestHandler *theRoutingRequestHandler = [[[CRoutingHTTPRequestHandler alloc] init] autorelease];
theRoutingRequestHandler.router = theRequestRouter;


[theHTTPServer.defaultRequestHandlers addObject:theRoutingRequestHandler];

[theHTTPServer.socketListener start:NULL];

NSError *theError = NULL;
CNATPMPManager *theManager = [[[CNATPMPManager alloc] init] autorelease];
[theManager externalAddress:&theError];
[theManager openPortForProtocol:NATPMP_PROTOCOL_TCP privatePort:theHTTPServer.socketListener.port publicPort:theHTTPServer.socketListener.port lifetime:5 * 60 error:&theError];

NSURL *theURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d", [[NSHost currentHost] name], theHTTPServer.socketListener.port]];
[[NSWorkspace sharedWorkspace] openURL:theURL];

[theHTTPServer.socketListener serveForever:YES error:NULL];

[pool drain];
return 0;
}
