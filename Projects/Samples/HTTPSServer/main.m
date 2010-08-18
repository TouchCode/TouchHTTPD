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

#import "CHelloWorldHTTPHandler.h"
#import "CHTTPServer.h"

int main (int argc, const char * argv[])
{
#pragma unused (argc, argv)

NSAutoreleasePool *theAutoreleasePool = [[NSAutoreleasePool alloc] init];

CHTTPServer *theHTTPServer = [[[CHTTPServer alloc] init] autorelease];

// *** Find the certificate ****************************************************
NSString *theLabel = @"ungoliant.local";
SecKeychainAttribute theAttributes[] = {
	{ .tag = kSecLabelItemAttr, .length = theLabel.length, .data = (void *)theLabel.UTF8String },
	};
SecKeychainAttributeList theAttributeList = { .count = 1, .attr = theAttributes };
SecKeychainSearchRef theSearchRef = NULL;
OSStatus theStatus = SecKeychainSearchCreateFromAttributes(NULL, kSecCertificateItemClass, &theAttributeList, &theSearchRef);
if (theStatus != noErr)
	[NSException raise:NSGenericException format:@"TODO failed with %d", theStatus];

SecKeychainItemRef theItem = NULL;
theStatus = SecKeychainSearchCopyNext(theSearchRef, &theItem);
if (theStatus != noErr)
	[NSException raise:NSGenericException format:@"TODO failed with %d", theStatus];

SecIdentityRef theIdentity;

//theStatus = SecIdentityCopyPreference((CFStringRef)@"ungoliant.local", CSSM_KEYUSE_ANY, NULL, &theIdentity);
//if (theStatus != noErr)
//	[NSException raise:NSGenericException format:@"TODO failed with %d", theStatus];

theStatus = SecIdentityCreateWithCertificate(NULL, (SecCertificateRef)theItem, &theIdentity);
if (theStatus != noErr)
	[NSException raise:NSGenericException format:@"TODO failed with %d", theStatus];

NSArray *theCertificates = [NSArray arrayWithObjects:(id)theIdentity, (id)theItem, NULL];

// *** ******************** ****************************************************

theHTTPServer.SSLCertificates = theCertificates;
theHTTPServer.useHTTPS = YES;
[theHTTPServer createDefaultSocketListener];

CHelloWorldHTTPHandler *theRequestHandler = [[[CHelloWorldHTTPHandler alloc] init] autorelease];
[theHTTPServer.defaultRequestHandlers addObject:theRequestHandler];

NSLog(@"Listener has started.");
[theHTTPServer.socketListener start:NULL];

NSInvocationOperation *theServerOperation = [[[NSInvocationOperation alloc] initWithTarget:theHTTPServer.socketListener selector:@selector(serveForever) object:NULL] autorelease];

NSOperationQueue *theQueue = [[[NSOperationQueue alloc] init] autorelease];
[theQueue addOperation:theServerOperation];

NSLog(@"Serving.");

NSURL *theURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@:%d", [[NSHost currentHost] name], theHTTPServer.socketListener.port]];
//[[NSWorkspace sharedWorkspace] openURL:theURL];

//NSError *theError = NULL;
//NSString *theString = [NSString stringWithContentsOfURL:theURL usedEncoding:NULL error:&theError];
//NSLog(@">>>>>>>>>>>>> %@ <<<<<<<<<<<<<<<<", theString);

sleep(60);

[theAutoreleasePool drain];
return 0;
}
