//
//  ECFileBuffer.h
//  ECFoundation
//
//  Created by Uri Baghin on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Name of the notifications posted when the buffer is modified
extern NSString * const ECFileBufferWillReplaceNotificationName;
extern NSString * const ECFileBufferDidReplaceNotificationName;
/// Keys of the notification userinfo dictionary
extern NSString * const ECFileBufferRangeKey;
extern NSString * const ECFileBufferStringKey;

/// A buffer containing the contents of a file
/// Contents are only read from the file during initialization, no file coordination support at the moment
@interface ECFileBuffer : NSObject

/// Initializes a file buffer with a given file
- (id)initWithFileURL:(NSURL *)fileURL;

- (NSURL *)fileURL;

/// Saves the contents of the buffer to it's file
- (void)save;

/// Saves the contents of the buffer to a given file
- (BOOL)saveToFileURL:(NSURL *)fileURL error:(NSError **)error;

/// Length of the buffer
- (NSUInteger)length;
/// Retrieves string made by a subrange of the buffer's character. The given range must be fully contained in the buffer's character range.
- (NSString *)stringInRange:(NSRange)range;

/// Replace the characters in a given range with a given string.
/// Pass a range of length 0 to insert characters, pass a string of length 0 to delete characters.
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string;

@end
