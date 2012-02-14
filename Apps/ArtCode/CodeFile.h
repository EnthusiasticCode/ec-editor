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

/// Length of the file
- (NSUInteger)length;
/// Retrieves string made by a subrange of the file's character. The given range must be fully contained in the file's character range.
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
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit;

/// Line ranges and offsets
- (NSRange)lineRangeForRange:(NSRange)range;

/// Find and replace functionality
#warning TODO replace all these with methods based on OnigRegexp
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
- (void)codeFile:(CodeFile *)codeFile willReplaceCharactersInRange:(NSRange)range withString:(NSString *)string;
- (void)codeFile:(CodeFile *)codeFile didReplaceCharactersInRange:(NSRange)range withString:(NSString *)string;
- (void)codeFile:(CodeFile *)codeFile willReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)string;
- (void)codeFile:(CodeFile *)codeFile didReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)string;

- (void)codeFile:(CodeFile *)codeFile willAddAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)codeFile:(CodeFile *)codeFile didAddAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)codeFile:(CodeFile *)codeFile willRemoveAttributes:(NSArray *)attributes range:(NSRange)range;
- (void)codeFile:(CodeFile *)codeFile didRemoveAttributes:(NSArray *)attributes range:(NSRange)range;
@end


/// Represent a symbol returned by the symbolList method in CodeFile.
@interface CodeFileSymbol : NSObject

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) UIImage *icon;
@property (nonatomic, readonly) NSRange range;

@end