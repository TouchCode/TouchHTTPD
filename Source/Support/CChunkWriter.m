//
//  CChunkWriter.m
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

#import "CChunkWriter.h"

@interface CChunkWriter ()
@property (readwrite, nonatomic, assign) BOOL moreChunksComing;
@property (readwrite, nonatomic, assign) NSInteger remainingChunkLength;
@property (readwrite, nonatomic, strong) NSMutableData *buffer;
@end

@implementation CChunkWriter

@synthesize outputFile;
@synthesize moreChunksComing;
@synthesize remainingChunkLength;
@synthesize buffer;
@synthesize delegate;

#if 0
+ (void)load
{
NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];

NSString *theBodyString = @"27\r\nThis is the data in the first chunk... \r\n1C\r\nand this is the second one.\r\r\n0\r\n";
NSData *theBody = [theBodyString dataUsingEncoding:NSASCIIStringEncoding];

CChunkWriter *theWriter = [[[CChunkWriter alloc] init] autorelease];

theWriter.outputFile = [NSFileHandle fileHandleWithStandardOutput];

[theWriter writeData:theBody];

[thePool release];
}
#endif

- (id)init
{
if ((self = [super init]) != NULL)
	{
	moreChunksComing = YES;
	remainingChunkLength = 0;
	}
return(self);
}


- (void)writeData:(NSData *)inData;
{
NSInteger theChunkLength = self.remainingChunkLength;
if (theChunkLength == -1)
	{
	// JIWTODO error!
	NSLog(@"CHUNKING ERROR #0");
	}

const char *START = inData.bytes, *END = START + inData.length, *P = START;

while (START < END)
	{
	if (self.remainingChunkLength == 0)
		{
		for (; P != END && *P != '\r'; ++P)
			{
			if (ishexnumber(*P) == NO)
				{
				// JIWTODO error!
				NSLog(@"CHUNKING ERROR #1");
				}		
			}
		theChunkLength = strtol(START, NULL, 16);

		if (*P++ != '\r')
			{
			// JIWTODO error!
			NSLog(@"CHUNKING ERROR #2");
			}		
			
		if (*P++ != '\n')
			{
			// JIWTODO error!
			NSLog(@"CHUNKING ERROR #2.5");
			}		

		if (theChunkLength == 0)
			{
			// We are done!
			self.remainingChunkLength = -1;
			[self.delegate chunkWriterDidReachEOF:self];
//			NSLog(@"CHUNK WRITER ENDED");
			return;
			}

			theChunkLength += 2;		// calculate \n\r suffix too
		}
		
	NSInteger theAvailableLength = MIN(END - P, theChunkLength);
	self.remainingChunkLength = theChunkLength - theAvailableLength;

	// do not write terminating \n\r if this is a tail of current chunk
	NSInteger writeLength = (0 == self.remainingChunkLength) ? theAvailableLength - 2 : theAvailableLength;
	if (writeLength > 0)
		{
		NSData *theChunk = [[NSData alloc] initWithBytesNoCopy:(void *)P length: writeLength freeWhenDone:NO];
		[self.outputFile writeData:theChunk];
		}

	P += theAvailableLength;
	START = P;
	}
}

@end
