//
//  NSFileManager_AppleDoubleExtensions.m
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

#import "NSFileManager_AppleDoubleExtensions.h"

#import "GMAppleDouble.h"
#include <sys/xattr.h>

@implementation NSFileManager (NSFileManager_AppleDoubleExtensions)

- (NSData *)appleDoubleDataForPath:(NSString *)inPath error:(NSError **)outError
{
#pragma unused (outError)
const char *thePath = [inPath UTF8String];

GMAppleDouble *theAppleDouble = [GMAppleDouble appleDouble];
ssize_t theSize = getxattr(thePath, "com.apple.FinderInfo", NULL, 0, 0, XATTR_NOFOLLOW);
if (theSize > 0)
	{
	NSMutableData *theData = [NSMutableData dataWithLength:theSize];
	if (getxattr(thePath, "com.apple.FinderInfo", [theData mutableBytes], theSize, 0, XATTR_NOFOLLOW) < 0)
		{
		if (outError)
			*outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:NULL];
		return(NULL);
		}
	[theAppleDouble addEntryWithID:DoubleEntryFinderInfo data:theData];
	}

theSize = getxattr(thePath, "com.apple.ResourceFork", NULL, 0, 0, XATTR_NOFOLLOW);
if (theSize > 0)
	{
	NSMutableData *theData = [NSMutableData dataWithLength:theSize];
	if (getxattr(thePath, "com.apple.ResourceFork", [theData mutableBytes], theSize, 0, XATTR_NOFOLLOW) < 0)
		{
		if (outError)
			*outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:NULL];
		return(NULL);
		}
	[theAppleDouble addEntryWithID:DoubleEntryResourceFork data:theData];
	}

return([theAppleDouble data]);
}

- (BOOL)setAppleDoubleData:(NSData *)inData forPath:(NSString *)inPath error:(NSError **)outError
{
const char *thePath = [inPath UTF8String];

GMAppleDouble *theAppleDouble = [GMAppleDouble appleDoubleWithData:inData];
for (GMAppleDoubleEntry *theEntry in [theAppleDouble entries])
	{
	NSString *theAttributeName = NULL;
	switch ([theEntry entryID])
		{
		case DoubleEntryFinderInfo:
			theAttributeName = @"com.apple.FinderInfo";
			break;
		case DoubleEntryResourceFork:
			theAttributeName = @"com.apple.ResourceFork";
			break;
		}
		
	if (theAttributeName != NULL)
		{
		NSData *theEntryData = [theEntry data];
		int theResult = setxattr(thePath, [theAttributeName UTF8String], [theEntryData bytes], [theEntryData length], 0, XATTR_NOFOLLOW);
		if (theResult != 0)
			{
			if (outError)
				*outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:NULL];
			return(NO);
			}
		}
	}

return(YES);
}

@end
