//
//  TextPosition.h
//  edit
//
//  Created by Nicola Peduzzi on 02/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TextPosition : UITextPosition <NSCopying> {
@private
  NSUInteger index;
}

@property (nonatomic, readonly) NSUInteger index;

- (id)initWithIndex:(NSUInteger)idx;
- (NSComparisonResult)compare:other;

@end
