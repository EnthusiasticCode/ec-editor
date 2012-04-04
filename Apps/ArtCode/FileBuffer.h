//
//  FileBuffer.h
//  ArtCode
//
//  Created by Uri Baghin on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FileBuffer;

@protocol FileBufferPresenter <NSObject>

@optional
- (void)fileBuffer:(FileBuffer *)fileBuffer didReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)string;
- (void)fileBuffer:(FileBuffer *)fileBuffer didChangeAttributesInRange:(NSRange)range;

@end

@interface FileBuffer : NSMutableAttributedString

@property (nonatomic, strong) NSDictionary *defaultAttributes;
@property (nonatomic, strong) NSURL *fileURL;

- (id)initWithFileURL:(NSURL *)fileURL;

/// Presenters are retained by the FileBuffer, so they must be removed to avoid retain cycles and leaks
- (void)addPresenter:(id<FileBufferPresenter>)presenter;
- (void)removePresenter:(id<FileBufferPresenter>)presenter;
- (NSArray *)presenters;

#pragma mark String content reading methods
- (NSUInteger)length;
- (NSString *)string;
- (NSString *)substringWithRange:(NSRange)range;
- (NSRange)lineRangeForRange:(NSRange)range;

#pragma mark Attributed string content reading methods
- (NSAttributedString *)attributedString;
- (NSAttributedString *)attributedSubstringFromRange:(NSRange)range;
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range;
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit;
- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range;
- (NSDictionary *)attributesAtIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit;

#pragma mark String content writing methods
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string;

#pragma mark Attributed string content writing methods
- (void)addAttribute:(NSString *)name value:(id)value range:(NSRange)range;
- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)removeAttribute:(NSString *)name range:(NSRange)range;
- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)range;

@end

