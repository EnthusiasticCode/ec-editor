//
//  CodeFile.h
//  ArtCode
//
//  Created by Uri Baghin on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeFile.h"

typedef NSUInteger CodeFileGeneration;

@interface CodeFile (Generation)

/// Get the current generation
/// Because of the inherent race conditions of this method, it can only be called from main queue
- (CodeFileGeneration)currentGeneration;

/// These methods are meant to be called from non-main queues, although they work exactly the same from the main queue, however since the codefile can only be modified from main queue, and the generation will only change in main queue, there is no need to use them from the main queue
/// These getters and setters come in two variants: the generation and the expected generation
/// Methods with generation will return the codefile's generation by reference
/// Methods with expected generation will compare the generation you pass in with the codefile's generation before executing, and fail if the generations don't match

/// String content reading methods
- (NSUInteger)lengthWithGeneration:(CodeFileGeneration *)generation;
- (BOOL)length:(NSUInteger *)length expectedGeneration:(CodeFileGeneration)expectedGeneration;
- (NSString *)stringWithGeneration:(CodeFileGeneration *)generation;
- (BOOL)string:(NSString **)string expectedGeneration:(CodeFileGeneration)expectedGeneration;
- (NSString *)stringInRange:(NSRange)range generation:(CodeFileGeneration *)generation;
- (BOOL)string:(NSString **)string inRange:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration;
- (NSRange)lineRangeForRange:(NSRange)range generation:(CodeFileGeneration *)generation;
- (BOOL)lineRange:(NSRangePointer)lineRange forRange:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration;

/// Attributed string content reading methods
- (NSAttributedString *)attributedStringWithGeneration:(CodeFileGeneration *)generation;
- (BOOL)attributedString:(NSAttributedString **)attributedString expectedGeneration:(CodeFileGeneration)expectedGeneration;
- (NSAttributedString *)attributedStringInRange:(NSRange)range generation:(CodeFileGeneration *)generation;
- (BOOL)attributedString:(NSAttributedString **)attributedString inRange:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration;
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange generation:(CodeFileGeneration *)generation;
- (BOOL)attribute:(id *)attribute withName:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange expectedGeneration:(CodeFileGeneration)expectedGeneration;
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit generation:(CodeFileGeneration *)generation;
- (BOOL)attribute:(id *)attribute withName:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit expectedGeneration:(CodeFileGeneration)expectedGeneration;

/// Attributed string content writing methods
- (BOOL)addAttributes:(NSDictionary *)attributes range:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration;
- (BOOL)removeAttributes:(NSArray *)attributeNames range:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration;
- (BOOL)removeAllAttributesInRange:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration;

@end
