//
//  NSError_HTTPDExtensions.m
//  TouchCode
//
//  Created by Jonathan Wight on 11/13/08.
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

#import "NSError_HTTPDExtensions.h"

#import "CHTTPMessage.h"

@implementation NSError (NSError_HTTPDExtensions)

+ (id)errorWithDomain:(NSString *)domain code:(NSInteger)code underlyingError:(NSError *)inUnderlyingError request:(CHTTPMessage *)inRequest
{
NSMutableDictionary *theUserInfo = [NSMutableDictionary dictionary];
if (inUnderlyingError)
	[theUserInfo setObject:inUnderlyingError forKey:NSUnderlyingErrorKey];
if (inRequest && [inRequest debuggingDescription])
	[theUserInfo setObject:[inRequest debuggingDescription] forKey:@"TouchHTTPRequestKey"];

NSError *theError = [self errorWithDomain:domain code:code userInfo:theUserInfo];

return(theError);
}


+ (id)errorWithDomain:(NSString *)domain code:(NSInteger)code underlyingError:(NSError *)inUnderlyingError request:(CHTTPMessage *)inRequest format:(NSString *)inFormat, ...
{
NSMutableDictionary *theUserInfo = [NSMutableDictionary dictionary];
if (inUnderlyingError)
	[theUserInfo setObject:inUnderlyingError forKey:NSUnderlyingErrorKey];
if (inRequest && [inRequest debuggingDescription])
	[theUserInfo setObject:[inRequest debuggingDescription] forKey:@"TouchHTTPRequestKey"];

va_list theArgs;
va_start(theArgs, inFormat);
NSString *theDescription = [[[NSString alloc] initWithFormat:inFormat arguments:theArgs] autorelease];
va_end(theArgs);

[theUserInfo setObject:theDescription forKey:NSLocalizedDescriptionKey];

NSError *theError = [self errorWithDomain:domain code:code userInfo:theUserInfo];

return(theError);
}

@end
