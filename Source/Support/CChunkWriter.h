//
//  CChunkWriter.h
//  TouchCode
//
//  Created by Jonathan Wight on 12/30/08.
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

@protocol CChunkWriterDelegate;

// JIWTODO - to clear this up - it really _ought_ to be made into an NSOutputStream subclass. But right now quick & easy > best.
@interface CChunkWriter : NSObject {
	NSFileHandle *outputFile;
	BOOL moreChunksComing;
	NSInteger remainingChunkLength;
	NSMutableData *buffer;
	id <CChunkWriterDelegate> delegate;
}

@property (readwrite, retain) NSFileHandle *outputFile;
@property (readonly, assign) BOOL moreChunksComing;
@property (readonly, assign) NSInteger remainingChunkLength;
@property (readonly, retain) NSMutableData *buffer; // JIWTODO not currently used
@property (readwrite, assign) id <CChunkWriterDelegate> delegate;

- (void)writeData:(NSData *)inData;

@end

#pragma mark -

@protocol CChunkWriterDelegate <NSObject>
- (void)chunkWriterDidReachEOF:(CChunkWriter *)inChunkWriter;
@end
