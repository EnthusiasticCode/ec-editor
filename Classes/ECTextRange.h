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

- (id)initWithStart:(ECTextPosition*)aStart end:(ECTextPosition*)aEnd;
- (id)initWithRange:(NSRange)characterRange;
- (NSRange)range;
- (ECTextRange*)rangeIncludingPosition:(ECTextPosition*)aPosition;
- (BOOL)includesPosition:(ECTextPosition*)aPosition;

@end
