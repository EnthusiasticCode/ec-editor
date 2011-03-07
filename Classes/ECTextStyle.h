//
//  ECTextStyle.h
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


/// A text style represent attributes to be applied to a string.
@interface ECTextStyle : NSObject {
@private
    NSMutableDictionary *CTAttributes;
}

/// The name of the style.
@property (nonatomic, copy) NSString *name;

/// The font to use for this style.
@property (nonatomic, retain) UIFont *font;

/// The font color to use for this style.
@property (nonatomic, retain) UIColor *foregroundColor;

/// Gets a dictionary of core text compatible attributed string's attributes.
@property (nonatomic, readonly, copy) NSDictionary *CTAttributes;

/// Initialize a new style with a name.
- (id)initWithName:(NSString *)aName;

/// Create a new style with name and common properties.
+ (id)textStyleWithName:(NSString *)aName font:(UIFont *)aFont color:(UIColor *)aColor;

@end
