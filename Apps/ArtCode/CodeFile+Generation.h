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

/// String content reading methods
- (NSUInteger)lengthWithGeneration:(CodeFileGeneration *)generation;
- (BOOL)length:(NSUInteger *)length withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;
- (NSString *)stringWithGeneration:(CodeFileGeneration *)generation;
- (BOOL)string:(NSString **)string withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;
- (NSString *)stringInRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation;
- (BOOL)string:(NSString **)string inRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;
- (NSRange)lineRangeForRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation;
- (BOOL)lineRange:(NSRangePointer)lineRange forRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;

/// Attributed string content reading methods
- (NSAttributedString *)attributedStringWithGeneration:(CodeFileGeneration *)generation;
- (BOOL)attributedString:(NSAttributedString **)attributedString withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;
- (NSAttributedString *)attributedStringInRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation;
- (BOOL)attributedString:(NSAttributedString **)attributedString inRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange withGeneration:(CodeFileGeneration *)generation;
- (BOOL)attribute:(id *)attribute withName:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit withGeneration:(CodeFileGeneration *)generation;
- (BOOL)attribute:(id *)attribute withName:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;

/// String content writing methods
- (BOOL)replaceCharactersInRange:(NSRange)range withString:(NSString *)string withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;

/// Attributed string content writing methods
- (BOOL)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attributedString withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;
- (BOOL)addAttributes:(NSDictionary *)attributes range:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;
- (BOOL)removeAttributes:(NSArray *)attributeNames range:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;

@end
