//
//  ECTextStyle.h
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ECTextStyle : NSObject {
@private
    NSMutableDictionary *CTAttributes;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) UIFont *font;
@property (nonatomic, retain) UIColor *foregroundColor;
@property (nonatomic, readonly, copy) NSDictionary *CTAttributes;

- (id)initWithName:(NSString *)aName;

+ (id)textStyleWithName:(NSString *)aName font:(UIFont *)aFont color:(UIColor *)aColor;

@end
