//
//  CFileSystem.h
//  TouchCode
//
//  Created by Jonathan Wight on 11/5/08.
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

#import <Foundation/Foundation.h>

#import "TouchXML.h"

// JIWTODO -- work with URLs not path strings.

@protocol CFileSystem <NSObject>

- (NSString *)etagForItemAtPath:(NSString *)inPath;

- (BOOL)fileExistsAtPath:(NSString *)inPath isDirectory:(BOOL *)outIsDirectory;

- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes error:(NSError **)error;

- (BOOL)copyItemAtPath:(NSString *)inSourcePath toPath:(NSString *)inDestinationPath error:(NSError **)outError;
- (BOOL)moveItemAtPath:(NSString *)inSourcePath toPath:(NSString *)inDestinationPath error:(NSError **)outError;
- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error;

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)inPath maximumDepth:(NSInteger)inMaximumDepth error:(NSError **)outError;

- (NSData *)contentsOfFileAtPath:(NSString *)inPath error:(NSError **)outError;
- (BOOL)writeContentsOfFileAtPath:(NSString *)inPath data:(NSData *)inData error:(NSError **)outError;

- (NSInputStream *)inputStreamForFileAtPath:(NSString *)inPath error:(NSError **)outError;

- (NSDictionary *)fileAttributesAtPath:(NSString *)inPath error:(NSError **)outError;

- (BOOL)moveLocalFileSystemItemAtPath:(NSString *)inSourcePath toPath:(NSString *)inDestinationPath error:(NSError **)outError;

@end
