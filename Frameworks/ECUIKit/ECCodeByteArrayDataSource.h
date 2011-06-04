//
//  ECCodeByteArrayDataSource.h
//  CodeView
//
//  Created by Nicola Peduzzi on 22/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECCodeView.h"

@class ECTextStyle;
@class ECCodeByteArrayDataSource;

typedef void(^StylizeFilePartStringBlock)(ECCodeByteArrayDataSource *dataSource, NSMutableAttributedString *string, NSRange stringRange);

@interface ECCodeByteArrayDataSource : NSObject <ECCodeViewDataSource>

#pragma mark Providing Data Input

/// The file URL that the datasource is reading from.
@property (nonatomic, retain) NSURL *fileURL;

/// Gets or set the line delimiter. Default is @"\n".
@property (nonatomic, copy) NSString *lineDelimiter;

/// Chunk of data bytes to read. Default is 1024.
@property (nonatomic) NSUInteger chunkSize;

#pragma mark Styling Text

/// The default text style to apply to a read string
@property (nonatomic, retain) ECTextStyle *defaultTextStyle;

/// A block that will be used on every attributed string returned by the
/// datasource. The block should set some custom style on the given 
/// attributed string.
@property (nonatomic, copy) StylizeFilePartStringBlock stylizeBlock;

#pragma mark Managing File

/// Save any current changes to disk.
- (void)writeToFile;

@end
