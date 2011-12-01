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
