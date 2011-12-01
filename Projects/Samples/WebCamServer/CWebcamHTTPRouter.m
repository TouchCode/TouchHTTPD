//
//  CWebcamHTTPRouter.m
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

#import "CWebcamHTTPRouter.h"

#import "CRoutingHTTPRequestHandler.h"
#import "CHTTPMessage.h"
#import "CHTTPMessage_ConvenienceExtensions.h"
#import "CQTCaptureSnapshot.h"

@implementation CWebcamHTTPRouter

@synthesize snapshot;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	self.snapshot = [[CQTCaptureSnapshot alloc] init];
	}
return(self);
}

- (void)dealloc
{
self.snapshot = NULL;
//
[super dealloc];
}

- (BOOL)routeConnection:(CRoutingHTTPRequestHandler *)inConnection request:(CHTTPMessage *)inRequest toTarget:(id *)outTarget selector:(SEL *)outSelector error:(NSError **)outError;
{
#pragma unused (inConnection, inRequest, outTarget, outSelector, outError)
NSURL *theURL = [inRequest requestURL];

*outTarget = self;

if ([[theURL path] isEqualToString:@"/favicon.ico"])
	*outSelector = @selector(favIconResponseForRequest:error:);
else
	*outSelector = @selector(webcamResponseForRequest:error:);

return(YES);
}

- (CHTTPMessage *)favIconResponseForRequest:(CHTTPMessage *)inRequest error:(NSError **)outError
{
#pragma unused (inRequest, outError)
CHTTPMessage *theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:200 statusDescription:@"OK" httpVersion:kHTTPVersion1_0];

NSData *theBodyData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"/Users/schwa/Pictures/Icons/schwa.png"]];
[theResponse setContentType:@"image/png" body:theBodyData];
return(theResponse);
}

- (CHTTPMessage *)webcamResponseForRequest:(CHTTPMessage *)inRequest error:(NSError **)outError
{
#pragma unused (inRequest, outError)
CHTTPMessage *theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:200 statusDescription:@"OK" httpVersion:kHTTPVersion1_0];
NSData *theBodyData = self.snapshot.jpegData;
[theResponse setContentType:@"image/jpeg" body:theBodyData];
return(theResponse);
}

@end
