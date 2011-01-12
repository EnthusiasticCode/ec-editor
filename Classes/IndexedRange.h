//
//  IndexedRange.h
//  edit
//
//  Created by Uri Baghin on 1/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IndexedPosition.h"


@interface IndexedRange : UITextRange {
    NSRange _range;
}

@property (nonatomic) NSRange range;
+ (IndexedRange *)rangeWithNSRange:(NSRange)range;

@end
