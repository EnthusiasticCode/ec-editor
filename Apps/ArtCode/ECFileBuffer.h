//
//  ECFileBuffer.h
//  ECFoundation
//
//  Created by Uri Baghin on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECFileBuffer;

typedef enum {
    ECFileBufferAttributesChangeSet,
    ECFileBufferAttributesChangeAdd,
    ECFileBufferAttributesChangeRemove,
} ECFileBufferAttributesChange;

@protocol ECFileBufferConsumer <NSObject>

@required
/// This method can be called from any queue, at any time.
/// All other consumer methods will be called on the returned queue.
- (NSOperationQueue *)consumerOperationQueue;

/// All the "will" methods are blocking, so return from them as soon as possible. There's also a high chance they will cause a deadlock if they're not implemented with care.
/// All the "did" methods are asynchronous and aren't coalesced, so they may be called multiple times in succession, and not immediately after the change has gone through.

@optional
- (void)accommodateFileDeletionForFileBuffer:(ECFileBuffer *)fileBuffer;
- (void)fileBuffer:(ECFileBuffer *)fileBuffer fileDidMoveToURL:(NSURL *)dstURL;

/// Both regular and attributed versions of these methods are called regardless of whether the change was triggered by a call to the regular or attributed version of the replace methods
- (void)fileBuffer:(ECFileBuffer *)fileBuffer willReplaceCharactersInRange:(NSRange)range withString:(NSString *)string;
- (void)fileBuffer:(ECFileBuffer *)fileBuffer didReplaceCharactersInRange:(NSRange)range withString:(NSString *)string;
- (void)fileBuffer:(ECFileBuffer *)fileBuffer willReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)string;
- (void)fileBuffer:(ECFileBuffer *)fileBuffer didReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)string;

- (void)fileBuffer:(ECFileBuffer *)fileBuffer willAddAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)fileBuffer:(ECFileBuffer *)fileBuffer didAddAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)fileBuffer:(ECFileBuffer *)fileBuffer willRemoveAttributes:(NSArray *)attributes range:(NSRange)range;
- (void)fileBuffer:(ECFileBuffer *)fileBuffer didRemoveAttributes:(NSArray *)attributes range:(NSRange)range;

@end

/// A buffer containing the contents of a file
/// Contents are only read from the file during initialization, no file coordination support at the moment
/// Only the contents are persisted to disk on a save, not the attributes
@interface ECFileBuffer : NSObject <NSFilePresenter>

/// Initializes a file buffer with a given file
- (id)initWithFileURL:(NSURL *)fileURL;

- (NSURL *)fileURL;

- (void)addConsumer:(id<ECFileBufferConsumer>)consumer;
- (void)removeConsumer:(id<ECFileBufferConsumer>)consumer;
- (NSArray *)consumers;

/// Length of the buffer
- (NSUInteger)length;
/// Retrieves string made by a subrange of the buffer's character. The given range must be fully contained in the buffer's character range.
- (NSString *)stringInRange:(NSRange)range;
- (NSString *)string;

/// Replace the characters in a given range with a given string.
/// Pass a range of length 0 to insert characters, pass a string of length 0 to delete characters.
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string;

/// Attributed methods
- (NSAttributedString *)attributedStringInRange:(NSRange)range;
- (NSAttributedString *)attributedString;
- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attributedString;

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)removeAttributes:(NSArray *)attributeNames range:(NSRange)range;
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
