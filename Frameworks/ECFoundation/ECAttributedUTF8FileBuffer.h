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
@interface ECAttributedUTF8FileBuffer : NSObject

/// Initializes a file buffer with a given file
- (id)initWithFileURL:(NSURL *)fileURL;

- (NSURL *)fileURL;

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
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange;

/// Find and replace functionality

- (NSUInteger)numberOfMatchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range;

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range;

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options;

/// Returns the replacement string for the given template. See NSRegularExpression method for more informations.
- (NSString *)replacementStringForResult:(NSTextCheckingResult *)result offset:(NSInteger)offset template:(NSString *)replacementTemplate;

/// Replaces the given match with the given template
/// The match must be valid and returns from one of the file buffer find methods
/// After the replacement occurs, the file buffer could be changed in a way that invalidates matches found before the replacement took place. For this reason, the offset paramenter can be used to specify that the match location should be offsetted by the given amount.
/// Returns the range of the replaced text after the replacement.
- (NSRange)replaceMatch:(NSTextCheckingResult *)match withTemplate:(NSString *)replacementTemplate offset:(NSInteger)offset;

@end
