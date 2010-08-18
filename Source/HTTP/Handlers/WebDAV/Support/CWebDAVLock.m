//
//  CWebDAVLock.m
//  TouchCode
//
//  Created by Jonathan Wight on 11/14/08.
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

#import "CWebDAVLock.h"

#import "CHTTPMessage.h"
#import "CHTTPMessage_WebDAVExtensions.h"
#import "TouchXML.h"
#import "NSError_HTTPDExtensions.h"
#import "TouchHTTPDConstants.h"

@interface CWebDAVLock ()
@property (readwrite, retain) NSURL *resource;
@property (readwrite, retain) NSString *token;
@property (readwrite, assign) NSInteger depth;
@property (readwrite, retain) NSDate *timeout;
@property (readwrite, assign) EWebDavLockScope scope;
@property (readwrite, assign) EWebDavLockType type;
@property (readwrite, retain) NSString *owner;
@end

#pragma mark -

@implementation CWebDAVLock

@synthesize resource;
@synthesize token;
@synthesize depth;
@synthesize timeout;
@synthesize scope;
@synthesize type;
@synthesize owner;

+ (CWebDAVLock *)WebDavLockWithHTTPRequest:(CHTTPMessage *)inRequest error:(NSError **)outError
{
CWebDAVLock *theLock = [[[self alloc] init] autorelease];

// #### Get the resource
theLock.resource = [inRequest requestURL];

// #### Get the depth
NSNumber *theDepthValue = inRequest.depth;
if (theDepthValue == NULL)
	{
	if (outError)
		*outError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:NULL request:inRequest];
	return(NULL);
	}
NSInteger theDepth = [theDepthValue integerValue];
if (theDepth != 0 && theDepth != -1)
	{
	if (outError)
		*outError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:NULL request:inRequest];
	return(NULL);
	}

// JIWTODO currently ignoring timeout - but in future we can implement it

CXMLDocument *theDocument = [inRequest XMLBodyWithError:outError];
if (theDocument == NULL)
	{
	if (outError)
		*outError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:NULL request:inRequest];
	return(NULL);
	}

// JIWTODO this needs to be made global!
NSDictionary *theNamespaceMappings = [NSDictionary dictionaryWithObjectsAndKeys:
	@"DAV:", @"D",
	NULL];

NSError *theError = NULL;
NSArray *theNodes = NULL;

// #### Get the lock scope (exclusive vs shared)
theNodes = [theDocument nodesForXPath:@"/D:lockinfo/D:lockscope/D:exclusive" namespaceMappings:theNamespaceMappings error:&theError];
if (theNodes.count == 1)
	theLock.scope = WebDavLockScope_Exclusive;
else
	{
	theNodes = [theDocument nodesForXPath:@"/D:lockinfo/D:lockscope/D:shared" namespaceMappings:theNamespaceMappings error:&theError];
	if (theNodes.count == 1)
		theLock.scope = WebDavLockScope_Shared;
	}

// #### Get the lock type (exclusive vs shared)
theNodes = [theDocument nodesForXPath:@"/D:lockinfo/D:locktype/D:write" namespaceMappings:theNamespaceMappings error:&theError];
if (theNodes.count == 0)
	{
	if (outError)
		*outError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:NULL request:inRequest];
	return(NULL);
	}
theLock.type = WebDavLockType_Write;

// #### Get the lock owner (and convert into an NSData)
theNodes = [theDocument nodesForXPath:@"/D:lockinfo/D:owner" namespaceMappings:theNamespaceMappings error:&theError];
if (theNodes.count != 1)
	{
	if (outError)
		*outError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:NULL request:inRequest];
	return(NULL);
	}
CXMLElement *theOwnerElement = [theNodes objectAtIndex:0];
theLock.owner = [theOwnerElement XMLString];

// #### Create a token for the new lock.
CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
CFStringRef theUUIDString = CFUUIDCreateString(kCFAllocatorDefault, theUUID);;
CFRelease(theUUID);
theLock.token = [NSString stringWithFormat:@"urn:uuid:%@", theUUIDString];
CFRelease(theUUIDString);

return(theLock);
}

- (id)init
{
if ((self = [super init]) != NULL)
	{
	}
return(self);
}

- (void)dealloc
{
self.resource = NULL;
self.token = NULL;
self.timeout = NULL;
self.owner = NULL;
//	
[super dealloc];
}

#pragma mark -

- (NSString *)debuggingDescription
{
return([NSString stringWithFormat:@"%@ {resource:'%@', token:'%@', depth:%d, timeout:%@, scope:%d, type:%d, owner:'%@'}", [self description], self.resource, self.token, self.depth, self.timeout, self.scope, self.type, self.owner]);
}

#pragma mark -

- (CXMLElement *)asActiveLockElement
{
CXMLElement *theLockElement = [CXMLNode elementWithName:@"activelock" URI:@"DAV:"];
if (self.type == WebDavLockType_Write)
	[[theLockElement subelement:@"locktype"] subelement:@"write"];

if (self.scope == WebDavLockScope_Shared)
	[[theLockElement subelement:@"lockscope"] subelement:@"shared"];
else if (self.scope == WebDavLockScope_Exclusive)
	[[theLockElement subelement:@"lockscope"] subelement:@"exclusive"];
else
	return(NULL);

if (self.depth == 0)
	[theLockElement subelement:@"depth"].stringValue = @"0";
else if (self.depth == -1)
	[theLockElement subelement:@"depth"].stringValue = @"infinity";
else
	return(NULL);

CXMLDocument *theOwnerDocument = [[[CXMLDocument alloc] initWithXMLString:self.owner options:0 error:NULL] autorelease];
CXMLElement *theOwnerElement = theOwnerDocument.rootElement;

[[theLockElement subelement:@"owner"] addChild:[[theOwnerElement copy] autorelease]];

[theLockElement subelement:@"timeout"].stringValue = @"Second-600";

[[theLockElement subelement:@"locktoken"] subelement:@"href"].stringValue = self.token;

[[theLockElement subelement:@"lockroot"] subelement:@"href"].stringValue = [self.resource relativeString];

return(theLockElement);
}

@end
