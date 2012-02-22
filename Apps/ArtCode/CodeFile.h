//
//  CodeFile.h
//  ArtCode
//
//  Created by Uri Baghin on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CodeView.h"

@protocol CodeFilePresenter;

@class TMTheme, CodeFileSymbol, TMUnit;

@interface CodeFile : UIDocument <CodeViewDataSource>

+ (void)codeFileWithFileURL:(NSURL *)fileURL completionHandler:(void (^)(CodeFile *codeFile))completionHandler;

- (void)addPresenter:(id<CodeFilePresenter>)presenter;
- (void)removePresenter:(id<CodeFilePresenter>)presenter;
- (NSArray *)presenters;

@property (nonatomic, strong) TMTheme *theme;
@property (nonatomic, strong, readonly) TMUnit *codeUnit;

#pragma mark - String content reading methods
- (NSUInteger)length;
- (NSString *)string;
- (NSString *)stringInRange:(NSRange)range;
- (NSRange)lineRangeForRange:(NSRange)range;

#pragma mark - Attributed string content reading methods
- (NSAttributedString *)attributedString;
- (NSAttributedString *)attributedStringInRange:(NSRange)range;
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange;
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit;

#pragma mark - String content writing methods
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string;

#pragma mark - Attributed string content writing methods
- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)removeAttributes:(NSArray *)attributeNames range:(NSRange)range;

#pragma mark - Find and replace functionality
- (NSUInteger)numberOfMatchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range;

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range;

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options;

/// Returns the replacement string for the given template. See NSRegularExpression method for more informations.
- (NSString *)replacementStringForResult:(NSTextCheckingResult *)result offset:(NSInteger)offset template:(NSString *)replacementTemplate;

/// Replaces the given match with the given template
/// The match must be valid and returns from one of the file file find methods
/// After the replacement occurs, the file file could be changed in a way that invalidates matches found before the replacement took place. For this reason, the offset paramenter can be used to specify that the match location should be offsetted by the given amount.
/// Returns the range of the replaced text after the replacement.
- (NSRange)replaceMatch:(NSTextCheckingResult *)match withTemplate:(NSString *)replacementTemplate offset:(NSInteger)offset;

/// Returns an array of CodeFileSymbol objects representing all the symbols in the file.
- (NSArray *)symbolList;

@end

@protocol CodeFilePresenter <NSObject>
@optional
/// Both regular and attributed versions of these methods are called regardless of whether the change was triggered by a call to the regular or attributed version of the replace methods
- (void)codeFile:(CodeFile *)codeFile didReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)string;

- (void)codeFile:(CodeFile *)codeFile didAddAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)codeFile:(CodeFile *)codeFile didRemoveAttributes:(NSArray *)attributes range:(NSRange)range;
@end


/// Represent a symbol returned by the symbolList method in CodeFile.
@interface CodeFileSymbol : NSObject

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) UIImage *icon;
@property (nonatomic, readonly) NSRange range;
@property (nonatomic, readonly) NSUInteger indentation;
@property (nonatomic, readonly, getter = isSeparator) BOOL separator;

@end