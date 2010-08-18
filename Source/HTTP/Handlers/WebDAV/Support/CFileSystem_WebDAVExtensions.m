//
//  CFileSystem_WebDAVExtensions.m
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

#import "CFileSystem_WebDAVExtensions.h"

#import "TouchHTTPDConstants.h"
#import "TouchXML.h"
#import "NSDate_InternetDateExtensions.h"
#import "NSFileManager_Extensions.h"
#import "NSString_Extensions.h"
#import "CWebDAVLock.h"
#import "CWebDAVLockDatabase.h"
#import "CWebDavHTTPHandler.h"

@implementation CDefaultFileSystem (CFileSystem_WebDAVExtensions)

- (CXMLElement *)webDavPropResponseElementForHandler:(CWebDavHTTPHandler *)inHandler forPath:(NSString *)inPath properties:(CXMLDocument *)inDocument error:(NSError **)outError
{
NSString *theAbsolutePath = [self absolutePathForRelativePath:inPath];

BOOL theIsAppleDoubleFlag = [theAbsolutePath pathIsAppleDouble];
if (theIsAppleDoubleFlag)
	{
	theAbsolutePath = [theAbsolutePath pathByRemovingAppleDoublePrefix];
	}

BOOL theIsDirectoryFlag = NO;
BOOL theFileExistsFlag = [self.fileManager fileExistsAtPath:theAbsolutePath isDirectory:&theIsDirectoryFlag];
if (theFileExistsFlag == NO)
	{
	if (outError)
		{
		*outError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_NotFound userInfo:NULL];
		}
	return(NULL);
	}
if (theIsDirectoryFlag == YES)
	{
	if (theIsAppleDoubleFlag == YES)
		{
		theIsDirectoryFlag = NO;
		}
	else if ([inPath characterAtIndex:inPath.length - 1] != '/')
		{
		inPath = [inPath stringByAppendingString:@"/"];
		theAbsolutePath = [theAbsolutePath stringByAppendingString:@"/"];
		}
	}

CXMLElement *theResponseElement = [CXMLNode elementWithName:@"response" URI:@"DAV:"];
[theResponseElement subelement:@"href"].stringValue = inPath;

CXMLElement *thePropStatElement = [theResponseElement subelement:@"propstat"];
[thePropStatElement subelement:@"status"].stringValue = @"HTTP/1.1 200 OK";

CXMLElement *thePropElement = [thePropStatElement subelement:@"prop"];
[thePropElement subelement:@"displayname"].stringValue = [inPath lastPathComponent];

[thePropElement subelement:@"name"].stringValue = [inPath lastPathComponent];
	
NSError *theError = NULL;
BOOL theAllPropFlag = NO;

NSDictionary *theNamespaceMappings = [NSDictionary dictionaryWithObjectsAndKeys:
	@"DAV:", @"D",
	NULL];

if ([[inDocument nodesForXPath:@"/D:propfind/D:allprop" namespaceMappings:theNamespaceMappings error:&theError] count] == 1)
	theAllPropFlag = YES;

NSMutableArray *theNotHandledProperties = [NSMutableArray array];
NSDictionary *theFileAttributes = [self.fileManager fileAttributesAtPath:theAbsolutePath traverseLink:NO];
if (theFileAttributes == NULL)
	{
	if (outError)
		*outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:NULL];
	return(NULL);	
	}
	
/*
<name/>
<parentname/>
<href/>
<ishidden/>
<iscollection/>
<isreadonly/>
<getcontenttype/>
<contentclass/>
<getcontentlanguage/>
<creationdate/>
<lastaccessed/>
<getlastmodified/>
<getcontentlength/>
<resourcetype/>
<isstructureddocument/>
<defaultdocument/>
<displayname/>
<isroot/>
*/

// #### getlastmodified
if (theAllPropFlag == YES || [[inDocument nodesForXPath:@"/D:propfind/D:prop/D:getlastmodified" namespaceMappings:theNamespaceMappings error:&theError] count] == 1)
	{
	[thePropElement subelement:@"getlastmodified"].stringValue = [[theFileAttributes objectForKey:NSFileModificationDate] RFC1822StringValue];
	}

// #### getcontentlength
if ((theAllPropFlag == YES || [[inDocument nodesForXPath:@"/D:propfind/D:prop/D:getcontentlength" namespaceMappings:theNamespaceMappings error:&theError] count] == 1) && theIsDirectoryFlag == NO)
	{
	[thePropElement subelement:@"getcontentlength"].stringValue = [[theFileAttributes objectForKey:NSFileSize] stringValue];
	}

// #### lockdiscovery
if ((theAllPropFlag == YES || [[inDocument nodesForXPath:@"/D:propfind/D:prop/D:lockdiscovery" namespaceMappings:theNamespaceMappings error:&theError] count] == 1))
	{
	CWebDAVLock *theLock = [inHandler.lockDatabase lockByResource:[NSURL URLWithString:inPath]];
	if (theLock)
		{
		CXMLElement *theLockDiscoveryElement = [thePropElement subelement:@"lockdiscovery"];
		[theLockDiscoveryElement addChild:[theLock asActiveLockElement]];
		}
	}

// #### getetag
if ((theAllPropFlag == YES || [[inDocument nodesForXPath:@"/D:propfind/D:prop/D:getetag" namespaceMappings:theNamespaceMappings error:&theError] count] == 1))
	{
	NSString *theEtag = [self etagForItemAtPath:inPath];
	[thePropElement subelement:@"getetag"].stringValue = theEtag;
	}

// #### resourcetype
if (theIsDirectoryFlag == YES)
	[[thePropElement subelement:@"resourcetype"] subelement:@"collection"];
else
	[thePropElement subelement:@"resourcetype"];

// TODO is this list up to date? What about href displayname etc?
NSSet *theKnownPropertyes = [NSSet setWithObjects:@"allprop", @"getlastmodified", @"getcontentlength", @"resourcetype", @"lockdiscovery", @"getetag", NULL];

NSArray *theNodes = [inDocument nodesForXPath:@"/D:propfind/D:prop/*" namespaceMappings:theNamespaceMappings error:&theError];
for (CXMLElement *theProperty in theNodes)
	{
	if ([theProperty.URI isEqualToString:@"DAV:"] == YES)
		{
		if ([theKnownPropertyes containsObject:theProperty.localName] == NO)
			{
			[theNotHandledProperties addObject:theProperty];
			}
		}
	else
		{
		[theNotHandledProperties addObject:theProperty];
		}
	}

if (theNotHandledProperties.count > 0)
	{
	LOG_(@"NOT HANDLED PROPERTIES: %@", [[theNotHandledProperties valueForKey:@"name"] componentsJoinedByString:@","]);
	
	thePropStatElement = [theResponseElement subelement:@"propstat"];	
	[thePropStatElement subelement:@"status"].stringValue = @"HTTP/1.1 404 Not Found";
	thePropElement = [thePropStatElement subelement:@"prop"];
	for (CXMLElement *theProperty in theNotHandledProperties)
		{
		theProperty = [[theProperty copy] autorelease];		
		[thePropElement addChild:theProperty];
		}
	}
	
return(theResponseElement);
}
@end
