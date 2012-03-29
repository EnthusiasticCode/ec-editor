//
//  FileBuffer.h
//  ArtCode
//
//  Created by Uri Baghin on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FileBuffer;

@protocol CodeFilePresenter <NSObject>

@optional
- (void)fileBuffer:(FileBuffer *)fileBuffer didReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)string;
- (void)fileBuffer:(FileBuffer *)fileBuffer didChangeAttributesInRange:(NSRange)range;

@end

@interface FileBuffer : NSObject

@property (nonatomic, strong) NSDictionary *defaultAttributes;

- (void)addPresenter:(id<CodeFilePresenter>)presenter;
- (void)removePresenter:(id<CodeFilePresenter>)presenter;
- (NSArray *)presenters;

#pragma mark String content reading methods
- (NSUInteger)length;
- (NSString *)string;
- (NSString *)stringInRange:(NSRange)range;
- (NSRange)lineRangeForRange:(NSRange)range;

#pragma mark Attributed string content reading methods
- (NSAttributedString *)attributedString;
- (NSAttributedString *)attributedStringInRange:(NSRange)range;
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange;
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit;

#pragma mark String content writing methods
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string;

#pragma mark Attributed string content writing methods
- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)removeAttributes:(NSArray *)attributeNames range:(NSRange)range;
- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)removeAllAttributesInRange:(NSRange)range;

#pragma mark Find and replace functionality
- (NSUInteger)numberOfMatchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range DEPRECATED_ATTRIBUTE;
- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range DEPRECATED_ATTRIBUTE;
- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options DEPRECATED_ATTRIBUTE;

/// Returns the replacement string for the given template. See NSRegularExpression method for more informations.
- (NSString *)replacementStringForResult:(NSTextCheckingResult *)result offset:(NSInteger)offset template:(NSString *)replacementTemplate DEPRECATED_ATTRIBUTE;

/// Replaces the given match with the given template
/// The match must be valid and returns from one of the file file find methods
/// After the replacement occurs, the file file could be changed in a way that invalidates matches found before the replacement took place. For this reason, the offset paramenter can be used to specify that the match location should be offsetted by the given amount.
/// Returns the range of the replaced text after the replacement.
- (NSRange)replaceMatch:(NSTextCheckingResult *)match withTemplate:(NSString *)replacementTemplate offset:(NSInteger)offset DEPRECATED_ATTRIBUTE;

@end

