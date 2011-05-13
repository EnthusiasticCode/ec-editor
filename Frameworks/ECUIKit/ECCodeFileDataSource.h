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


@interface ECCodeFileDataSource : NSObject <ECCodeViewDataSource>

/// The file path that the datasource is reading from.
@property (nonatomic, retain) NSString *path;

/// Gets or set the line delimiter. Default is @"\n".
@property (nonatomic, copy) NSString *lineDelimiter;

/// Chunk of data bytes to read. Default is 10.
@property (nonatomic) NSUInteger chunkSize;

@property (nonatomic, retain) ECTextStyle *defaultTextStyle;

@end
