//
//  main.m
//  TouchCode
//
//  Created by Jonathan Wight on 20090528.
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
