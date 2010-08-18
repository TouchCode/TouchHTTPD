// ================================================================
// Copyright (c) 2007, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
// * Redistributions of source code must retain the above copyright
//   notice, this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above
//   copyright notice, this list of conditions and the following disclaimer
//   in the documentation and/or other materials provided with the
//   distribution.
// * Neither the name of Google Inc. nor the names of its
//   contributors may be used to endorse or promote products derived from
//   this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ================================================================
//
//  GMAppleDouble.h
//  MacFUSE
//
//  Created by ted on 12/29/07.
//
#import <Foundation/Foundation.h>

// Based on "AppleSingle/AppleDouble Formats for Foreign Files Developer's Note"
//
// Notes:
//  DoubleEntryFileDatesInfo
//    File creation, modification, backup, and access times as number of seconds 
//    before or after 12:00 AM Jan 1 2000 GMT as SInt32.
//  DoubleEntryFinderInfo
//    16 bytes of FinderInfo followed by 16 bytes of extended FinderInfo.
//    New FinderInfo should be zero'd out. For a directory, when the Finder 
//    encounters an entry with the init'd bit cleared, it will initialize the 
//    frView field of the to a value indicating how the contents of the
//    directory should be shown. Recommend to set frView to value of 256.
//  DoubleEntryMacFileInfo
//    This is a 32 bit flag that stores locked (bit 0) and protected (bit 1).
//
typedef enum {
  DoubleEntryInvalid = 0,
  DoubleEntryDataFork = 1,
  DoubleEntryResourceFork = 2,
  DoubleEntryRealName = 3,
  DoubleEntryComment = 4,
  DoubleEntryBlackAndWhiteIcon = 5,
  DoubleEntryColorIcon = 6,
  DoubleEntryFileDatesInfo = 8,  // See notes
  DoubleEntryFinderInfo = 9,     // See notes
  DoubleEntryMacFileInfo = 10,   // See notes
  DoubleEntryProDosFileInfo = 11,
  DoubleEntryMSDosFileinfo = 12,
  DoubleEntryShortName = 13,
  DoubleEntryAFPFileInfo = 14,
  DoubleEntryDirectoryID = 15,
} GMAppleDoubleEntryID;

@interface GMAppleDoubleEntry : NSObject {
  GMAppleDoubleEntryID entryID_;
  NSData* data_;  // Format depends on entryID_
}
- (id)initWithEntryID:(GMAppleDoubleEntryID)entryID data:(NSData *)data;
- (GMAppleDoubleEntryID)entryID;
- (NSData *)data;
@end

@interface GMAppleDouble : NSObject {  
  NSMutableArray* entries_;
}

// An empty double file.
+ (GMAppleDouble *)appleDouble;

// A double file pre-filled with entries from raw AppleDouble file data.
+ (GMAppleDouble *)appleDoubleWithData:(NSData *)data;

// Adds an entry to the double file.
- (void)addEntry:(GMAppleDoubleEntry *)entry;

// Adds an entry to the double file. The given data is retained.
- (void)addEntryWithID:(GMAppleDoubleEntryID)entryID data:(NSData *)data;

// Parses raw AppleDouble file data and adds a GMAppleDoubleEntry for each entry
// that is present. Returns YES iff it parsed correctly.
- (BOOL)addEntriesFromAppleDoubleData:(NSData *)data;

// Returns the current set of GMAppleDoubleEntry objects for this AppleDouble.
- (NSArray *)entries;

// Constructs and returns raw data for the AppleDouble file.
- (NSData *)data;

@end
