//
//  ECAttributedFileBuffer.h
//  ECFoundation
//
//  Created by Uri Baghin on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECFileBuffer.h"

/// In addition to the notifications inherited by ECFileBuffer, ECAttributedFileBuffer will post:
/// Names of the notifications posted when the buffer's attributes are modified
extern NSString * const ECAttributedFileBufferWillChangeAttributesNotificationName;
extern NSString * const ECAttributedFileBufferDidChangeAttributesNotificationName;

/// Keys of the notification userinfo dictionary
extern NSString * const ECAttributedFileBufferAttributedStringKey;
extern NSString * const ECAttributedFileBufferAttributeNameKey;
typedef enum {
    ECAttributedFileBufferAttributesChangeSet,
    ECAttributedFileBufferAttributesChangeAdd,
    ECAttributedFileBufferAttributesChangeRemove,
} ECAttributedFileBufferAttributesChange;
extern NSString * const ECAttributedFileBufferAttributesChangeKey;
extern NSString * const ECAttributedFileBufferAttributesKey;

/// A buffer containing the contents of a file and attributes associated to them
/// Contents are only read from the file during initialization, no file coordination support at the moment
/// Only the contents are persisted to disk on a save, not the attributes
@interface ECAttributedFileBuffer : ECFileBuffer

- (NSAttributedString *)attributedStringInRange:(NSRange)range;
- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attributedString;

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)removeAttribute:(NSString *)attributeName range:(NSRange)range;

@end
