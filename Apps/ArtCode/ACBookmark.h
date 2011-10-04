//
//  ACBookmark.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACURLWrapper.h"

@class ACApplication;

@interface ACBookmark : ACURLWrapper

@property (nonatomic, strong) NSString * note;
@property (nonatomic, strong) ACApplication *application;

@end
