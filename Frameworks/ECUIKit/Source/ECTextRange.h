//
//  ECTextRange.h
//  edit
//
//  Created by Nicola Peduzzi on 02/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECTextPosition.h"

@interface ECTextRange : UITextRange <NSCopying> {
@protected
    ECTextPosition *start, *end;
}

@property (nonatomic, readonly) NSRange range;
@property (nonatomic, readonly) CFRange CFRange;

- (id)initWithStart:(ECTextPosition*)aStart end:(ECTextPosition*)aEnd;
- (id)initWithRange:(NSRange)characterRange;
- (ECTextRange*)rangeIncludingPosition:(ECTextPosition*)aPosition;
- (BOOL)includesPosition:(ECTextPosition*)aPosition;

+ (id)textRangeWithRange:(NSRange)range;

@end
