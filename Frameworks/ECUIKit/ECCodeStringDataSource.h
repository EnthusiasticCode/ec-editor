//
//  ECCodeStringDataSource.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 23/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECCodeView.h"
#import "ECTextStyle.h"

typedef void (^ECCodeStringDataSourceStylingBlock)(NSMutableAttributedString *string, NSRange stringRange);

@interface ECCodeStringDataSource : NSObject <ECCodeViewDataSource>

/// The string to be managed by the dataSource
@property (nonatomic, strong) NSString *string;

/// Default style applied to the entire string.
@property (nonatomic, strong) ECTextStyle *defaultTextStyle;

/// Add a styling block that will be called when the dataSource will have to return
/// a string. Styling blocks are applyed in unknown order and should not remove
/// any attributes from the provided string but only add them. The string will
/// initially only have the defaultTextStyle applied to it.
- (void)addStylingBlock:(ECCodeStringDataSourceStylingBlock)stylingBlock forKey:(NSString *)stylingKey;

/// Removes a styling block from the collection of those applied to the string.
- (void)removeStylingBlockForKey:(NSString *)stylingKey;

@end
