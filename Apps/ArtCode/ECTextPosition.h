//
//  ECTextPosition.h
//  edit
//
//  Created by Nicola Peduzzi on 02/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ECTextPosition : UITextPosition <NSCopying> {
@private
    NSUInteger index;
}

@property (readonly) NSUInteger index;

- (id)initWithIndex:(NSUInteger)idx;
- (NSComparisonResult)compare:other;

@end
