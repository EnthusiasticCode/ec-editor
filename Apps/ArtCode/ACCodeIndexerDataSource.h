//
//  ACCodeIndexerDataSource.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 05/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <ECUIKit/ECCodeStringDataSource.h>

@class ECCodeUnit, ECTextStyle;


/// A code view data source that connect the code indexer with a string datasource.
@interface ACCodeIndexerDataSource : ECCodeStringDataSource

@property (nonatomic, strong) ECCodeUnit *codeUnit;

#pragma mark Defining Code Styles

@property (nonatomic, strong) ECTextStyle *keywordStyle;
@property (nonatomic, strong) ECTextStyle *commentStyle;
@property (nonatomic, strong) ECTextStyle *referenceStyle;
@property (nonatomic, strong) ECTextStyle *literalStyle;
@property (nonatomic, strong) ECTextStyle *declarationStyle;
@property (nonatomic, strong) ECTextStyle *preprocessingStyle;

@end
