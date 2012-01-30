//
//  TextRange.h
//  edit
//
//  Created by Nicola Peduzzi on 02/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TextPosition;

@interface TextRange : UITextRange <NSCopying> {
@protected
    TextPosition *_start, *_end;
}

@property (nonatomic, readonly, weak) UITextPosition *start;
@property (nonatomic, readonly, weak) UITextPosition *end;

@property (nonatomic, readonly) NSRange range;
@property (nonatomic, readonly) CFRange CFRange;

- (id)initWithStart:(TextPosition*)aStart end:(TextPosition*)aEnd;
- (id)initWithRange:(NSRange)characterRange;
- (TextRange*)rangeIncludingPosition:(TextPosition*)aPosition;
- (BOOL)includesPosition:(TextPosition*)aPosition;

+ (id)textRangeWithRange:(NSRange)range;

@end
