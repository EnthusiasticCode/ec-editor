//
//  UIBarButtonItem+BlockAction.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 16/12/12.
//
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (BlockAction)

- (void)setActionBlock:(void (^)(id sender))block;

@end
