//
//  ECCodeFileDataSource.h
//  CodeView
//
//  Created by Nicola Peduzzi on 13/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECCodeView.h"
#import "ECTextStyle.h"

@class ECCodeFileDataSource;

typedef void(^StylizeFilePartStringBlock)(ECCodeFileDataSource *dataSource, NSMutableAttributedString *string, NSRange rangeInFile);

@interface ECCodeFileDataSource : NSObject <ECCodeViewDataSource>

#pragma mark Providing Data Input

/// The file URL that the datasource is reading from.
@property (nonatomic, strong) NSURL *inputFileURL;

/// Gets or set the line delimiter. Default is @"\n".
@property (nonatomic, copy) NSString *lineDelimiter;

/// Chunk of data bytes to read. Default is 1024.
@property (nonatomic) NSUInteger chunkSize;

#pragma mark Styling Text

/// The default text style to apply to a read string
@property (nonatomic, strong) ECTextStyle *defaultTextStyle;

/// A block that will be used on every attributed string returned by the
/// datasource. The block should set some custom style on the given 
/// attributed string.
@property (nonatomic, copy) StylizeFilePartStringBlock stylizeBlock;

#pragma mark Managing File

/// Save any current changes to disk.
- (void)flush;

@end