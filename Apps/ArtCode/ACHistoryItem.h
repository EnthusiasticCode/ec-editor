//
//  ACHistoryItem.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACURLWrapper.h"

@class ACTab, ACApplication;

@interface ACHistoryItem : ACURLWrapper

@property (nonatomic, strong) ACTab *tab;

@property (nonatomic, strong, readonly) ACApplication *application;

@end
