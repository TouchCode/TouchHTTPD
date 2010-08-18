//
//  CHTTPFileSystemHandler.m
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

#import "CHTTPFileSystemHandler.h"

#import "CHTTPMessage.h"
#import "CHTTPMessage_ConvenienceExtensions.h"
#import "CHTTPConnection.h"
#import "CHTTPServer.h"
#import "CFileSystem.h"
#import "TouchHTTPDConstants.h"
#import "NSError_HTTPDExtensions.h"
#import "TouchXML.h"
#import "NSFileManager_Extensions.h"
#import "CTempFile.h"
#import "CDefaultFileSystem.h"
#import "NSString_Extensions.h"
#import "NSDate_InternetDateExtensions.h"

@interface CHTTPFileSystemHandler ()
@property (readwrite, retain) NSString *rootPath;

- (CHTTPMessage *)responseForGetRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError;
- (CHTTPMessage *)responseForHeadRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError;
- (CHTTPMessage *)responseForPutRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError;
@end

#pragma mark -

@implementation CHTTPFileSystemHandler

@synthesize rootPath;
@synthesize fileSystem;
@synthesize handlesPut;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	self.handlesPut = NO;
	}
return(self);
}

- (id)initWithRootPath:(NSString *)inRootPath
{
if ((self = [self init]) != NULL)
	{
	self.rootPath = inRootPath;
	self.fileSystem = [[[CDefaultFileSystem alloc] initWithRootDirectory:self.rootPath] autorelease];
	}
return(self);
}

- (void)dealloc
{
self.rootPath = NULL;
self.fileSystem = NULL;
//
[super dealloc];
}

#pragma mark -

// JIWTODO -- move this into CHTTPConnection or server or somewhere?
- (NSURL *)canonicalURLForRequest:(CHTTPMessage *)inRequest connection:(CHTTPConnection *)inConnection
{
NSString *thePath = [inRequest.requestURL.path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

BOOL theIsDirectoryFlag = NO;
[self.fileSystem fileExistsAtPath:thePath isDirectory:&theIsDirectoryFlag];

NSString *theScheme = inConnection.server.URLScheme;
NSString *theHost = [inRequest headerForKey:@"Host"];
if (theHost == NULL)
	{
	// JIWTODO this is bad.
	theHost = @"localhost"; // JIWTODO -- get from server!
	}

NSString *theURLString = [NSString stringWithFormat:@"%@://%@%@%@", theScheme, theHost, thePath, theIsDirectoryFlag == YES ? @"/" : @""];

theURLString = [theURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

NSURL *theURL = [NSURL URLWithString:theURLString];
return(theURL);
}

- (BOOL)handleRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection response:(CHTTPMessage **)ioResponse error:(NSError **)outError;
{
CHTTPMessage *theResponse = NULL;
NSString *theRequestMethod = [inRequest requestMethod];

if ([theRequestMethod isEqualToString:@"GET"])
	{
	theResponse = [self responseForGetRequest:inRequest forConnection:inConnection error:outError];
	}
else if ([theRequestMethod isEqualToString:@"HEAD"])
	{
	theResponse = [self responseForHeadRequest:inRequest forConnection:inConnection error:outError];	
	}
else if (self.handlesPut == YES && [theRequestMethod isEqualToString:@"PUT"])
	{
	theResponse = [self responseForPutRequest:inRequest forConnection:inConnection error:outError];	
	}

if (ioResponse)
	*ioResponse = theResponse;

return(YES);
}

- (CHTTPMessage *)responseForGetRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError
{
#pragma unused (inRequest, inConnection, outError)

NSString *thePath = [inRequest.requestURL.path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

CHTTPMessage *theResponse = NULL;

NSError *theError = NULL;

BOOL theIsDirectoryFlag = NO;
if ([self.fileSystem fileExistsAtPath:thePath isDirectory:&theIsDirectoryFlag] == YES)
	{
	if (theIsDirectoryFlag == YES)
		{
		if ([inRequest.requestURL.resourceSpecifier characterAtIndex:inRequest.requestURL.resourceSpecifier.length - 1] != '/')
			{
			theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_MovedPermanently];
			
			NSString *theNewLocation = [[self canonicalURLForRequest:inRequest connection:inConnection] absoluteString];
			[theResponse setHeader:theNewLocation forKey:@"Location"];
			
			return(theResponse);
			}

		CXMLElement *theRootElement = [CXMLNode elementWithName:@"entries"];

		for (NSString *theChildPath in [self.fileSystem contentsOfDirectoryAtPath:thePath maximumDepth:1 error:&theError])
			{
			NSString *theFullPath = [thePath stringByAppendingPathComponent:theChildPath];
			
			[self.fileSystem fileExistsAtPath:theFullPath isDirectory:&theIsDirectoryFlag];
			
			CXMLElement *theEntry = [theRootElement subelement:@"entry"];
			
			[theEntry subelement:@"name"].stringValue = [theChildPath lastPathComponent];
			[theEntry subelement:@"path"].stringValue = theFullPath;
			[theEntry subelement:@"href"].stringValue = theChildPath;
			if (theIsDirectoryFlag)
				[theEntry subelement:@"kind"].stringValue = @"directory";
			else
				[theEntry subelement:@"kind"].stringValue = @"file";
			}
		
		CXMLDocument *theDocument = [CXMLNode documentWithRootElement:theRootElement];
		CXMLNode *theProcessingInstruction = [CXMLNode processingInstructionWithName:@"xml-stylesheet" stringValue:@"type=\"text/xsl\" href=\"/static/entries.xsl\""];
		[theDocument insertChild:theProcessingInstruction atIndex:0];

		theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_OK];
		[theResponse setContentType:@"text/xml" bodyData:[theDocument XMLData]];
		
		return(theResponse);
		}
	else if (theIsDirectoryFlag == NO)
		{
		theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_OK];

		theResponse.contentType = [[NSFileManager defaultManager] mimeTypeForPath:thePath];

		NSDictionary *theFileAttributes = [self.fileSystem fileAttributesAtPath:thePath error:outError];
		
		[theResponse setHeader:[[theFileAttributes fileModificationDate] RFC1822StringValue] forKey:@"Last-Modified"];


		NSInteger theFileSize = theFileAttributes.fileSize;
		theResponse.contentLength = theFileSize;

		NSInputStream *theStream = [self.fileSystem inputStreamForFileAtPath:thePath error:&theError];
		theResponse.body = theStream;
		
		return(theResponse);
		}
	}
else
	{
	theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_NotFound underlyingError:NULL request:inRequest];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}

return(NULL);
}

- (CHTTPMessage *)responseForHeadRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError
{
CHTTPMessage *theResponse = [self responseForGetRequest:inRequest forConnection:inConnection error:outError];
NSString *theContentLength = [theResponse headerForKey:@"Content-Length"];
theResponse.bodyData = NULL;
[theResponse setHeader:theContentLength forKey:@"Content-Length"];
return(theResponse);
}

- (CHTTPMessage *)responseForPutRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection error:(NSError **)outError
{
#pragma unused (inConnection, outError)

CHTTPMessage *theResponse = NULL;
BOOL theResult = NO;
NSError *theError = NULL;

NSString *thePath = [inRequest.requestURL.path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

BOOL theIsDirectoryFlag = NO;
BOOL theFileExistsFlag = [self.fileSystem fileExistsAtPath:thePath isDirectory:&theIsDirectoryFlag];
if (theFileExistsFlag && theIsDirectoryFlag)
	{
	NSError *theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_MethodNotAllowed underlyingError:NULL request:inRequest];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	return(theResponse);
	}
	
if (theFileExistsFlag)
	{
	[self.fileSystem removeItemAtPath:thePath error:&theError];
	// JIWTODO error handling.
	}

NSAssert([inRequest.body isKindOfClass:[CTempFile class]], @"Request body is not a CTempFile");

CTempFile *theTempFile = inRequest.body; 

// JIWTODO this needs to be put in fileSystem
theResult = [self.fileSystem moveLocalFileSystemItemAtPath:theTempFile.path toPath:thePath error:&theError];
if (theResult == NO)
	{
	LOG_(@"500: moveLocalFileSystemItemAtPath failed: %@", theError);
	theError = [NSError errorWithDomain:kHTTPErrorDomain code:kHTTPStatusCode_InternalServerError underlyingError:theError request:inRequest ];
	theResponse = [CHTTPMessage HTTPMessageResponseWithError:theError];
	}
else
	{
	if (theFileExistsFlag)
		theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_NoContent];
	else
		theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:kHTTPStatusCode_Created];
	}

return(theResponse);
}

@end
