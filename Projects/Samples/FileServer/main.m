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

#import <Cocoa/Cocoa.h>

#import "CTCPSocketListener.h"
#import "CTCPSocketListener_Extensions.h"
#import "CHTTPConnection.h"
#import "CHTTPFileSystemHandler.h"
#import "CHTTPServer.h"
#import "CWebDavHTTPHandler.h"
#import "CHTTPStaticResourcesHandler.h"
#import "CHTTPDefaultHandler.h"
#import "CHTTPLogHandler.h"

int main (int argc, const char * argv[])
{
#pragma unused (argc, argv)

NSAutoreleasePool *theAutoreleasePool = [[NSAutoreleasePool alloc] init];

CHTTPServer *theHTTPServer = [[[CHTTPServer alloc] init] autorelease];
[theHTTPServer createDefaultSocketListener];

CHTTPFileSystemHandler *theRequestHandler = [[[CWebDavHTTPHandler alloc] initWithRootPath:@"/Users/schwa/Sites/Test"] autorelease];
[theHTTPServer.defaultRequestHandlers addObject:theRequestHandler];

CHTTPStaticResourcesHandler *theStaticResourceHandler = [[[CHTTPStaticResourcesHandler alloc] init] autorelease];
theStaticResourceHandler.rootDirectory = [@"~/Sites/static" stringByExpandingTildeInPath];
[theHTTPServer.defaultRequestHandlers addObject:theStaticResourceHandler];

CHTTPDefaultHandler *theDefaultHandler = [[[CHTTPDefaultHandler alloc] init] autorelease];
[theHTTPServer.defaultRequestHandlers addObject:theDefaultHandler];

CHTTPLogHandler *theLogHandler = [[[CHTTPLogHandler alloc] init] autorelease];
[theHTTPServer.defaultRequestHandlers addObject:theLogHandler];


[theHTTPServer.socketListener start:NULL];

//NSURL *theURL = [NSURL URLWithString:[NSString stringWithFormat:@"webdav://%@:%d", [[NSHost currentHost] name], theHTTPServer.socketListener.port]];
//[[NSWorkspace sharedWorkspace] openURL:theURL];

[theHTTPServer.socketListener serveForever:YES error:NULL];

[theAutoreleasePool drain];
return 0;
}
