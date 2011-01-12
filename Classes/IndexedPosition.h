//
//  IndexedPosition.h
//  edit
//
//  Created by Uri Baghin on 1/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface IndexedPosition : UITextPosition {
    NSUInteger _index;
}

@property (nonatomic) NSUInteger index;
+ (IndexedPosition *)positionWithIndex:(NSUInteger)index;

@end
