//
//  CDefaultFileSystem.m
//  TouchCode
//
//  Created by Jonathan Wight on 1/2/09.
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

#import "CDefaultFileSystem.h"

#import "NSString_Extensions.h"
#import "NSFileManager_Extensions.h"
#import "TouchHTTPDConstants.h"

@interface CDefaultFileSystem ()
@end

@implementation CDefaultFileSystem

@synthesize fileManager;
@synthesize rootDirectory;
@synthesize supportAppleDouble;
@synthesize showDotFiles;

- (id)initWithRootDirectory:(NSString *)inRootDirectory
{
if ((self = [self init]) != NULL)
	{
	self.fileManager = [NSFileManager defaultManager];
	self.rootDirectory = inRootDirectory;
	self.supportAppleDouble = NO;
	self.showDotFiles = NO;
	}
return(self);
}

- (void)dealloc
{
self.fileManager = NULL;
self.rootDirectory = NULL;
//
[super dealloc];
}

#pragma mark -

- (NSString *)absolutePathForRelativePath:(NSString *)inRelativePath
{
NSString *theAbsolutePath = [self.rootDirectory stringByAppendingPathComponent:inRelativePath];
theAbsolutePath = [theAbsolutePath stringByStandardizingPath];
return(theAbsolutePath);
}

#pragma mark -

- (NSString *)etagForItemAtPath:(NSString *)inPath
{
// http://bitworking.org/news/150/REST-Tip-Deep-etags-give-you-more-benefits
NSString *thePath = [self absolutePathForRelativePath:inPath];

NSDictionary *theAttributes = [self.fileManager fileAttributesAtPath:thePath traverseLink:NO];


// JIWTODO - this should really be MD5ed or SHA1ed.

NSString *theEtagString = [NSString stringWithFormat:@"\"%qu/%u/%f\"", theAttributes.fileSize, theAttributes.fileSystemFileNumber, [theAttributes.fileModificationDate timeIntervalSinceReferenceDate]];

return(theEtagString);
}

- (BOOL)fileExistsAtPath:(NSString *)inPath isDirectory:(BOOL *)outIsDirectory
{
NSString *thePath = [self absolutePathForRelativePath:inPath];
if (self.supportAppleDouble == YES && [thePath pathIsAppleDouble] == YES)
	{
	thePath = [thePath pathByRemovingAppleDoublePrefix];
	BOOL theResult = [self.fileManager fileExistsAtPath:thePath isDirectory:NULL];
	if (outIsDirectory)
		*outIsDirectory = NO;
	return(theResult);
	}
else
	{
	BOOL theResult = [self.fileManager fileExistsAtPath:thePath isDirectory:outIsDirectory];
	return(theResult);
	}
}

- (BOOL)createDirectoryAtPath:(NSString *)inPath withIntermediateDirectories:(BOOL)inCreateIntermediates attributes:(NSDictionary *)inAttributes error:(NSError **)outError
{
NSString *thePath = [self absolutePathForRelativePath:inPath];
if (self.supportAppleDouble == YES && [thePath pathIsAppleDouble] == YES)
	{
	if (outError)
		*outError = [NSError errorWithDomain:kTouchHTTPErrorDomain code:-1 userInfo:NULL];
	return(NO);
	}
else
	{
	return([self.fileManager createDirectoryAtPath:thePath withIntermediateDirectories:inCreateIntermediates attributes:inAttributes error:outError]);
	}
}

- (BOOL)copyItemAtPath:(NSString *)inSourcePath toPath:(NSString *)inDestinationPath error:(NSError **)outError
{
NSString *theSourcePath = [self absolutePathForRelativePath:inSourcePath];
NSString *theDestinationPath = [self absolutePathForRelativePath:inDestinationPath];

BOOL theResult = [self.fileManager copyItemAtPath:theSourcePath toPath:theDestinationPath error:outError];
return(theResult);
}

- (BOOL)moveItemAtPath:(NSString *)inSourcePath toPath:(NSString *)inDestinationPath error:(NSError **)outError
{
NSString *theSourcePath = [self absolutePathForRelativePath:inSourcePath];
NSString *theDestinationPath = [self absolutePathForRelativePath:inDestinationPath];

BOOL theResult = [self.fileManager moveItemAtPath:theSourcePath toPath:theDestinationPath error:outError];
return(theResult);
}

- (BOOL)removeItemAtPath:(NSString *)inPath error:(NSError **)outError
{
NSString *thePath = [self absolutePathForRelativePath:inPath];
return([self.fileManager removeItemAtPath:thePath error:outError]);
}

#pragma mark -

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)inPath maximumDepth:(NSInteger)inMaximumDepth error:(NSError **)outError
{
NSString *thePath = [self absolutePathForRelativePath:inPath];
BOOL theIsDirectoryFlag;
BOOL theFileExistFlag = [self.fileManager fileExistsAtPath:thePath isDirectory:&theIsDirectoryFlag];
if (theFileExistFlag == NO && theIsDirectoryFlag == NO)
	{
	if (outError)
		*outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:NULL];
	return(NULL);
	}

NSMutableArray *theFilenames = [NSMutableArray array];
for (NSString *theFilename in [self.fileManager enumeratorAtPath:thePath])
	{
	if (inMaximumDepth != -1)
		{
		NSInteger theDepth = [[theFilename pathComponents] count];
		if (theDepth > inMaximumDepth)
			continue;
		}

	if (self.showDotFiles == NO && [theFilename characterAtIndex:0] == '.')
		continue;
		

	[theFilenames addObject:theFilename];
	}
return(theFilenames);
}

- (NSData *)contentsOfFileAtPath:(NSString *)inPath error:(NSError **)outError
{
#pragma unused (outError)

NSString *thePath = [self absolutePathForRelativePath:inPath];

if (self.supportAppleDouble == YES && [thePath pathIsAppleDouble] == YES)
	{
	thePath = [thePath pathByRemovingAppleDoublePrefix];

	NSData *theData = [self.fileManager appleDoubleDataForPath:thePath error:outError];
	return(theData);
	}
else
	{
	NSData *theData = [NSData dataWithContentsOfMappedFile:thePath];
	return(theData);
	}
}

- (BOOL)writeContentsOfFileAtPath:(NSString *)inPath data:(NSData *)inData error:(NSError **)outError
{
NSString *thePath = [self absolutePathForRelativePath:inPath];
BOOL theResult = [inData writeToFile:thePath options:NSAtomicWrite error:outError];
return(theResult);
}

- (NSInputStream *)inputStreamForFileAtPath:(NSString *)inPath error:(NSError **)outError;
{
NSString *thePath = [self absolutePathForRelativePath:inPath];
if (self.supportAppleDouble == YES && [thePath pathIsAppleDouble] == YES)
	{	
	NSInputStream *theStream = [NSInputStream inputStreamWithData:[self.fileManager appleDoubleDataForPath:thePath error:outError]];
	return(theStream);	
	}
else
	{
	NSInputStream *theStream = [NSInputStream inputStreamWithFileAtPath:thePath];
	return(theStream);
	}
}

- (NSDictionary *)fileAttributesAtPath:(NSString *)inPath error:(NSError **)outError
{
NSString *thePath = [self absolutePathForRelativePath:inPath];
if (self.supportAppleDouble == YES && [thePath pathIsAppleDouble] == YES)
	{
	thePath = [thePath pathByRemovingAppleDoublePrefix];
	NSData *theAppleDoubleData = [self.fileManager appleDoubleDataForPath:thePath error:outError];
	if (theAppleDoubleData == NULL)
		return(NULL);
	NSDictionary *theDataForkAttributes = [self.fileManager fileAttributesAtPath:thePath traverseLink:NO];
	NSDictionary *theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		NSFileTypeRegular, NSFileType,
		[NSNumber numberWithInteger:theAppleDoubleData.length], NSFileSize,
		[theDataForkAttributes objectForKey:NSFileModificationDate], NSFileModificationDate,
		[theDataForkAttributes objectForKey:NSFileCreationDate], NSFileCreationDate,
		NULL];
	return(theAttributes);
	}
else
	{
	return([self.fileManager fileAttributesAtPath:thePath traverseLink:NO]);
	}
}

- (BOOL)moveLocalFileSystemItemAtPath:(NSString *)inSourcePath toPath:(NSString *)inDestinationPath error:(NSError **)outError
{
NSString *theDestinationPath = [self absolutePathForRelativePath:inDestinationPath];
if (self.supportAppleDouble == YES && [theDestinationPath pathIsAppleDouble] == YES)
	{
	theDestinationPath = [theDestinationPath pathByRemovingAppleDoublePrefix];
	NSData *theData = [NSData dataWithContentsOfMappedFile:inSourcePath];
	BOOL theResult = [self.fileManager setAppleDoubleData:theData forPath:theDestinationPath error:outError];
	return(theResult);	
	}
else
	{
	BOOL theResult = [[NSFileManager defaultManager] moveItemAtPath:inSourcePath toPath:theDestinationPath error:outError];
	return(theResult);
	}
}

#pragma mark -

@end
