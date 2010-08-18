//
//  CWebDAVHTTPHandler.m
//  TouchCode
//
//  Created by Jonathan Wight on 10/31/08.
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

#import "CWebDavHTTPHandler.h"

#import "CHTTPMessage.h"
#import "CHTTPMessage_ConvenienceExtensions.h"
#import "CHTTPConnection.h"
#import "CHTTPServer.h"
#import "CHTTPMessage_WebDAVExtensions.h"
#import "TouchHTTPDConstants.h"
#import "NSError_HTTPDExtensions.h"
#import "TouchXML.h"
#import "CFileSystem.h"
#import "CFileSystem_WebDAVExtensions.h"
#import "CWebDAVLock.h"
#import "CWebDAVLockDatabase.h"
#import "CDefaultFileSystem.h"
#import "NSString_Extensions.h"

@interface CWebDavHTTPHandler ()

@property (readwrite, retain) CWebDAVLockDatabase *lockDatabase;

- (CHTTPMessage *)responseForOptionsRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError;
- (CHTTPMessage *)responseForDeleteRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError;
- (CHTTPMessage *)responseForMoveRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError;
- (CHTTPMessage *)responseForCopyRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError;
- (CHTTPMessage *)responseForPropFindRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError;
- (CHTTPMessage *)responseForMkColRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError;
- (CHTTPMessage *)responseForPropPatchRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError;
- (CHTTPMessage *)responseForLockRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError;
- (CHTTPMessage *)responseForUnlockRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError;
@end

#pragma mark -

@implementation CWebDavHTTPHandler

@synthesize lockDatabase;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	self.lockDatabase = [[[CWebDAVLockDatabase alloc] init] autorelease];
	self.handlesPut = YES;
	}
return(self);
}

- (void)dealloc
{
self.lockDatabase = NULL;
//
[super dealloc];
}

#pragma mark -

- (NSString *)DAVClass
{
return(@"1,2");
}

- (NSArray *)allowedMethods
{
return([NSArray arrayWithObjects:@"OPTIONS", @"GET", @"HEAD", @"PUT", @"POST", @"COPY", @"PROPFIND", @"DELETE", @"MKCOL", @"MOVE", @"PROPPATCH", @"LOCK", @"UNLOCK", NULL]);
}

- (BOOL)handleRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection response:(CHTTPMessage **)ioResponse error:(NSError **)outError;
{
if (*ioResponse != NULL)
	return(YES);

CHTTPMessage *theResponse = NULL;
BOOL theResult = YES;

NSString *theRequestMethod = [inRequest requestMethod];
if ([theRequestMethod isEqualToString:@"OPTIONS"])
	{
	theResponse = [self responseForOptionsRequest:inRequest forConnection:inConnection error:outError];
	}
else if ([theRequestMethod isEqualToString:@"COPY"])
	{
	theResponse = [self responseForCopyRequest:inRequest forConnection:inConnection error:outError];
	}
else if ([theRequestMethod isEqualToString:@"PROPFIND"])
	{
	theResponse = [self responseForPropFindRequest:inRequest forConnection:inConnection error:outError];
	}
else if ([theRequestMethod isEqualToString:@"DELETE"])
	{
	theResponse = [self responseForDeleteRequest:inRequest forConnection:inConnection error:outError];
	}
else if ([theRequestMethod isEqualToString:@"MKCOL"])
	{
	theResponse = [self responseForMkColRequest:inRequest forConnection:inConnection error:outError];
	}
else if ([theRequestMethod isEqualToString:@"MOVE"])
	{
	theResponse = [self responseForMoveRequest:inRequest forConnection:inConnection error:outError];
	}
else if ([theRequestMethod isEqualToString:@"PROPPATCH"])
	{
	theResponse = [self responseForPropPatchRequest:inRequest forConnection:inConnection error:outError];
	}
else if ([theRequestMethod isEqualToString:@"LOCK"])
	{
	theResponse = [self responseForLockRequest:inRequest forConnection:inConnection error:outError];
	}
else if ([theRequestMethod isEqualToString:@"UNLOCK"])
	{
	theResponse = [self responseForUnlockRequest:inRequest forConnection:inConnection error:outError];
	}
else
	{
	theResult = [super handleRequest:inRequest forConnection:inConnection response:&theResponse error:outError];
	}

if (ioResponse)
	*ioResponse = theResponse;

return(theResult);
}

- (CHTTPMessage *)responseForOptionsRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError;
{
#pragma unused (inRequest, inConnection, outError)

CHTTPMessage *theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_OK];
[theResponse setHeader:[self DAVClass] forKey:@"DAV"];
[theResponse setHeader:[[self allowedMethods] componentsJoinedByString:@","] forKey:@"Allow"];

return(theResponse);
}

- (CHTTPMessage *)responseForDeleteRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError;
{
#pragma unused (inConnection, outError)

BOOL theResult = NO;
CHTTPMessage *theResponse = NULL;
NSString *thePath = [inRequest.requestURL.path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

NSString *theDepthString = [inRequest mainHeaderComponentForKey:@"Depth"];
if (theDepthString != NULL)
	{
	if ([theDepthString isEqualToString:@"infinity"] == NO)
		{
		NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:NULL request:inRequest];
		theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
		return(theResponse);
		}
	}

if ([self.fileSystem fileExistsAtPath:thePath isDirectory:NULL] == NO)
	{
	NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_NotFound underlyingError:NULL request:inRequest];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}

NSError *theError = NULL;
theResult = [self.fileSystem removeItemAtPath:thePath error:&theError];
if (theResult == NO)
	{
	LOG_(@"500: removeItemAtPath failed: %@", theError);
	theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_InternalServerError underlyingError:theError request:inRequest format:@"Could not remove file at path: %@", thePath];
	
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];

	return(theResponse);
	}
	
theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_OK];
return(theResponse);
}

#pragma mark -

- (CHTTPMessage *)responseForMoveRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError
{
#pragma unused (inConnection, outError)

CHTTPMessage *theResponse = NULL;

NSInteger theDepth = 0;
BOOL theResult = [inRequest getDepth:&theDepth];
if (theResult == NO || theDepth > 0)
	{
	NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:NULL request:inRequest];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}

BOOL theOverwriteFlag = [[inRequest overwrite] boolValue];

NSString *theSourcePath = [inRequest.requestURL.path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
BOOL theIsDirectoryFlag = NO;
BOOL theFileExistsFlag = [self.fileSystem fileExistsAtPath:theSourcePath isDirectory:&theIsDirectoryFlag];
if (theFileExistsFlag == NO)
	{
	NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_NotFound underlyingError:NULL request:inRequest];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}

NSString *theDestinationStringURL = [inRequest headerForKey:@"Destination"];
if (theDestinationStringURL == NULL)
	{
	NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:NULL request:inRequest];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}
// JIWTODO we should not ignore destination host
NSURL *theDestination = [NSURL URLWithString:theDestinationStringURL];
NSString *theDestinationPath = [theDestination path];

theFileExistsFlag = [self.fileSystem fileExistsAtPath:theDestinationPath isDirectory:&theIsDirectoryFlag];

if (theFileExistsFlag == YES && theOverwriteFlag == NO)
	{
	NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:NULL request:inRequest];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}
else if (theFileExistsFlag == YES && theOverwriteFlag == YES)
	{
	NSError *theError = NULL;
	theResult = [self.fileSystem removeItemAtPath:theDestinationPath error:&theError];
	if (theResult == NO)
		{
		LOG_(@"500: removeItemAtPath failed: %@", theError);
		
		theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_InternalServerError underlyingError:theError request:inRequest format:@"Could not remove file at path: %@", theDestinationPath];
		
		theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];

		return(theResponse);
		}
	}

NSError *theError = NULL;
theResult = [self.fileSystem moveItemAtPath:theSourcePath toPath:theDestinationPath error:&theError];
if (theResult == NO)
	{
	LOG_(@"500: moveItemAtPath failed: %@", theError);

	theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_InternalServerError underlyingError:theError request:inRequest format:@"Could not move file to path: %@", theDestinationPath];
	
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];

	return(theResponse);
	}

theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_OK];

return(theResponse);
}

- (CHTTPMessage *)responseForCopyRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError
{
#pragma unused (inConnection, outError)

CHTTPMessage *theResponse = NULL;

NSInteger theDepth = 0;
BOOL theResult = [inRequest getDepth:&theDepth];
if (theResult == NO || theDepth > 0)
	{
	NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:NULL request:inRequest];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}

BOOL theOverwriteFlag = [[inRequest overwrite] boolValue];

NSString *theSourcePath = [inRequest.requestURL.path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
BOOL theIsDirectoryFlag = NO;
BOOL theFileExistsFlag = [self.fileSystem fileExistsAtPath:theSourcePath isDirectory:&theIsDirectoryFlag];
if (theFileExistsFlag == NO)
	{
	NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_NotFound underlyingError:NULL request:inRequest];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}

NSString *theDestinationStringURL = [inRequest headerForKey:@"Destination"];
if (theDestinationStringURL == NULL)
	{
	NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:NULL request:inRequest];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}
// JIWTODO we should not ignore destination host
NSURL *theDestination = [NSURL URLWithString:theDestinationStringURL];
NSString *theDestinationPath = [theDestination path];

theFileExistsFlag = [self.fileSystem fileExistsAtPath:theDestinationPath isDirectory:&theIsDirectoryFlag];

if (theFileExistsFlag == YES && theOverwriteFlag == NO)
	{
	NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:NULL request:inRequest];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}
else if (theFileExistsFlag == YES && theOverwriteFlag == YES)
	{
	NSError *theError = NULL;
	theResult = [self.fileSystem removeItemAtPath:theDestinationPath error:&theError];
	if (theResult == NO)
		{
		LOG_(@"500: removeItemAtPath failed: %@", theError);

		theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_InternalServerError underlyingError:theError request:inRequest format:@"Could not remove file at path: %@", theDestinationPath];
		
		theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];

		return(theResponse);
		}
	}

NSError *theError = NULL;
theResult = [self.fileSystem copyItemAtPath:theSourcePath toPath:theDestinationPath error:&theError];
if (theResult == NO)
	{
	LOG_(@"500: copyItemAtPath failed: %@", theError);
	theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_InternalServerError underlyingError:theError request:inRequest format:@"Could not copy file from %@ to path: %@", theSourcePath, theDestinationPath];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}

if (theFileExistsFlag == YES)
	theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_OK];
else
	theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_Created];

return(theResponse);
}

- (CHTTPMessage *)responseForPropFindRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError
{
#pragma unused (inConnection, outError)

CHTTPMessage *theResponse = NULL;
NSString *theRootPath = [inRequest.requestURL.path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

if ([self.fileSystem fileExistsAtPath:theRootPath isDirectory:NULL] == NO)
	{
	return([CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_NotFound]);
	}
//
NSInteger theDepth = -1;
NSString *theDepthString = [inRequest mainHeaderComponentForKey:@"Depth"];
if (theDepthString != NULL)
	{
	if ([theDepthString isEqualToString:@"0"])
		theDepth = 0;
	else if ([theDepthString isEqualToString:@"1"])
		theDepth = 1;
	else if ([theDepthString isEqualToString:@"infinity"])
		theDepth = -1;
	else
		{
		NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:NULL request:inRequest];
		theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
		return(theResponse);
		}
	}

NSError *theError = NULL;
CXMLDocument *theDocument = [inRequest XMLBodyWithError:&theError];
if (theDocument == NULL)
	{
	if (theError)
		{
		theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:theError request:inRequest];
		theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
		return(theResponse);
		}
	
	// JIWTODO optimize this somehow (i.e. dont create XML here)
	NSString *theString = @"<?xml version=\"1.0\" encoding=\"utf-8\" ?><D:propfind xmlns:D=\"DAV:\"><D:allprop/></D:propfind>";
	NSData *theData = [theString dataUsingEncoding:NSUTF8StringEncoding];
	theDocument = [[[CXMLDocument alloc] initWithData:theData options:0 error:outError] autorelease];
	}

//

CXMLElement *theMultiStatusElement = [CXMLNode elementWithName:@"multistatus" URI:@"DAV:"];

// JIWTODO a caste here is dangerous. RETHINK webDavPropResponseElementForPath
CXMLElement *theResponseElement = [(CDefaultFileSystem *)self.fileSystem webDavPropResponseElementForHandler:self forPath:theRootPath properties:theDocument error:&theError];
if (theResponseElement == NULL)
	{
	theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_NotFound underlyingError:NULL request:inRequest];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}

[theMultiStatusElement addChild:theResponseElement];

if (theDepth > 0 || theDepth == -1)
	{
	NSArray *thePaths = [self.fileSystem contentsOfDirectoryAtPath:theRootPath maximumDepth:theDepth error:&theError];
	for (NSString *thePath in thePaths)
		{
		thePath = [theRootPath stringByAppendingPathComponent:thePath];

		CXMLElement *theResponseElement = [(CDefaultFileSystem *)self.fileSystem webDavPropResponseElementForHandler:self forPath:thePath properties:theDocument error:&theError];
		if (theResponseElement == NULL)
			{
			LOG_(@"WARNING: Could not get response element for %@", thePath);
			}
		
		if (theResponseElement == NULL)
			{
			theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
			return(theResponse);
			}
		
		[theMultiStatusElement addChild:theResponseElement];
		}
	}

theDocument = [CXMLNode documentWithRootElement:theMultiStatusElement];

NSData *theBody = [theDocument XMLDataWithOptions:0];
theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_Multi_Status];
[theResponse setContentType:@"application/xml" bodyData:theBody];

return(theResponse);
}

- (CHTTPMessage *)responseForMkColRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError
{
#pragma unused (inConnection, outError)

CHTTPMessage *theResponse = NULL;

NSString *thePath = [inRequest.requestURL.path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

BOOL theIsDirectoryFlag = NO;
BOOL theFileExistsFlag = [self.fileSystem fileExistsAtPath:thePath isDirectory:&theIsDirectoryFlag];

if (theFileExistsFlag == YES)
	{
	NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_MethodNotAllowed underlyingError:NULL request:inRequest];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}

if ([inRequest headerForKey:@"Content-Type"])
	{
	theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_UnsupportedMediaType];
	return(theResponse);
	}
	
NSArray *theComponents = [thePath pathComponents];
theComponents = [theComponents subarrayWithRange:NSMakeRange(1, theComponents.count - 2)];
NSString *theTestPath = @"";
for (NSString *theComponent in theComponents)
	{
	theTestPath = [theTestPath stringByAppendingPathComponent:theComponent];

	theFileExistsFlag = [self.fileSystem fileExistsAtPath:theTestPath isDirectory:&theIsDirectoryFlag];
	if (theFileExistsFlag == NO)
		{
		theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_Conflict];
		return(theResponse);
		}
	else if (theFileExistsFlag == YES && theIsDirectoryFlag == NO)
		{
		theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_Forbidden];
		return(theResponse);
		}
	}

NSError *theError = NULL;
BOOL theResult = [self.fileSystem createDirectoryAtPath:thePath withIntermediateDirectories:NO attributes:NULL error:&theError];
if (theResult == NO)
	{
	LOG_(@"500: createDirectoryAtPath failed: %@", theError);
	theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_InternalServerError underlyingError:theError request:inRequest format:@"Could not create directory at path: %@", thePath];
	
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}

theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_Created];
return(theResponse);
}

#pragma mark -

- (CHTTPMessage *)responseForPropPatchRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError
{
#pragma unused (inRequest, inConnection, outError)

return(NULL);
}

- (CHTTPMessage *)responseForLockRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError
{
#pragma unused (inConnection, outError)
NSError *theError = NULL;
CWebDAVLock *theLock = [CWebDAVLock WebDavLockWithHTTPRequest:inRequest error:&theError];
//NSLog(@"LOCK: %@ -> %@", theLock.token, [theLock debuggingDescription]);
if (theLock == NULL)
	{
	CHTTPMessage *theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}

[self.lockDatabase addLock:theLock];

CXMLElement *thePropElement = [CXMLNode elementWithName:@"prop" URI:@"DAV:"];


CXMLElement *theLockDiscoveryElement = [thePropElement subelement:@"lockdiscovery"];
[theLockDiscoveryElement addChild:[theLock asActiveLockElement]];

CXMLDocument *theDocument = [CXMLNode documentWithRootElement:thePropElement];

CHTTPMessage *theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_OK];
[theResponse setContentType:@"application/xml" bodyData:[theDocument XMLData]];

[theResponse setHeader:[NSString stringWithFormat:@"<%@>", theLock.token] forKey:@"Lock-Token"];

return(theResponse);
}

- (CHTTPMessage *)responseForUnlockRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError
{
#pragma unused (inConnection, outError)
NSString *theLockToken = [inRequest headerForKey:@"Lock-Token"];
if (theLockToken == NULL)
	{
	NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_BadRequest underlyingError:NULL request:inRequest];
	CHTTPMessage *theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}

CWebDAVLock *theLock = [self.lockDatabase lockByToken:theLockToken];
if (theLock == NULL)
	{
	// Convert <foo> into foo.
	theLockToken = [theLockToken substringWithRange:NSMakeRange(1, theLockToken.length - 2)];
	theLock = [self.lockDatabase lockByToken:theLockToken];
	}

//NSLog(@"UNLOCK: %@ -> %@", theLockToken, [theLock debuggingDescription]);

if (theLock == NULL)
	{
	NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_Conflict underlyingError:NULL request:inRequest];
	CHTTPMessage *theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}

if ([inRequest.requestURL isEqual:theLock.resource] == NO)
	{
	NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_Conflict underlyingError:NULL request:inRequest];
	CHTTPMessage *theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}
	
[self.lockDatabase removeLock:theLock];

CHTTPMessage *theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_NoContent];
return(theResponse);
}

@end
