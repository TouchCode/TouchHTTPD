//
//  CNATPMPManager.m
//  TouchCode
//
//  Created by Jonathan Wight on 03/11/08.
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

#import "CNATPMPManager.h"

#include "natpmp.h"
#include "getgateway.h"

@implementation CNATPMPManager

@synthesize publicAddress;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	initnatpmp(&natpmp);
	}
return(self);
}

- (void)dealloc
{
closenatpmp(&natpmp);
//
[super dealloc];
}

- (NSData *)externalAddress:(NSError **)outError;
{
#pragma unused (outError)

int theResult = sendpublicaddressrequest(&natpmp);
natpmpresp_t theResponse;
while (YES)
	{
	theResult = readnatpmpresponseorretry(&natpmp, &theResponse);
	if(theResult < 0 && theResult != NATPMP_TRYAGAIN)
		{
		return(NULL);
		}
	else if (theResult != NATPMP_TRYAGAIN)
		{
		self.publicAddress = [NSData dataWithBytes:&theResponse.publicaddress.addr length:sizeof(theResponse.publicaddress.addr)];
		return (self.publicAddress);
		}
	}
}

- (BOOL)openPortForProtocol:(int)protocol privatePort:(int)privateport publicPort:(int)publicport lifetime:(int)lifetime error:(NSError **)outError
{
#pragma unused (outError)
natpmpresp_t theResponse;
int theResult;

theResult = sendnewportmappingrequest(&natpmp, protocol, privateport, publicport, lifetime);

while (YES)
	{
	theResult = readnatpmpresponseorretry(&natpmp, &theResponse);
	if (theResult < 0 && theResult != NATPMP_TRYAGAIN)
		return(NO);
	else if(theResult!=NATPMP_TRYAGAIN)
		{
//		NSLog(@"mapped public port: %d", theResponse.newportmapping.mappedpublicport);
//		NSLog(@" private port: %d", theResponse.newportmapping.privateport);
//		NSLog(@"mapped lifetime: %d", theResponse.newportmapping.lifetime);
//				copy(publicport, response.newportmapping.mappedpublicport);
//				copy(privateport, response.newportmapping.privateport);
//				copy(mappinglifetime, response.newportmapping.lifetime);
		return(YES);
		}
	}
}


@end
