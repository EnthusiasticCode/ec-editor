//
//  ECFileBuffer.h
//  ECFoundation
//
//  Created by Uri Baghin on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Names of the notifications posted when the buffer is modified
extern NSString * const ECFileBufferWillReplaceCharactersNotificationName;
extern NSString * const ECFileBufferDidReplaceCharactersNotificationName;
extern NSString * const ECFileBufferWillChangeAttributesNotificationName;
extern NSString * const ECFileBufferDidChangeAttributesNotificationName;

/// Keys of the notification userinfo dictionary
extern NSString * const ECFileBufferRangeKey;
extern NSString * const ECFileBufferStringKey;
extern NSString * const ECFileBufferAttributedStringKey;
extern NSString * const ECFileBufferAttributeNameKey;
typedef enum {
    ECFileBufferAttributesChangeSet,
    ECFileBufferAttributesChangeAdd,
    ECFileBufferAttributesChangeRemove,
} ECFileBufferAttributesChange;
extern NSString * const ECFileBufferAttributesChangeKey;
extern NSString * const ECFileBufferAttributesKey;

/// A buffer containing the contents of a file
/// Contents are only read from the file during initialization, no file coordination support at the moment
/// Only the contents are persisted to disk on a save, not the attributes
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

/// Attributed methods
- (NSAttributedString *)attributedStringInRange:(NSRange)range;
- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attributedString;

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)removeAttribute:(NSString *)attributeName range:(NSRange)range;

@end
