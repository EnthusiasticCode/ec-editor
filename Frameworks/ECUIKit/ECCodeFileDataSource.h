//
//  ECCodeFileDataSource.h
//  CodeView
//
//  Created by Nicola Peduzzi on 13/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECCodeViewDatasource.h"
#import "ECTextStyle.h"

@class ECCodeFileDataSource;

typedef void(^StylizeFilePartStringBlock)(ECCodeFileDataSource *dataSource, NSMutableAttributedString *string, NSRange rangeInFile);

@interface ECCodeFileDataSource : NSObject <ECCodeViewDataSource>

/// The file path that the datasource is reading from.
@property (nonatomic, retain) NSString *path;

/// Gets or set the line delimiter. Default is @"\n".
@property (nonatomic, copy) NSString *lineDelimiter;

/// Chunk of data bytes to read. Default is 10.
@property (nonatomic) NSUInteger chunkSize;

/// The default text style to apply to a read string
@property (nonatomic, retain) ECTextStyle *defaultTextStyle;

/// A block that will be used on every attributed string returned by the
/// datasource. The block should set some custom style on the given 
/// attributed string.
@property (nonatomic, copy) StylizeFilePartStringBlock stylizeBlock;

@end
