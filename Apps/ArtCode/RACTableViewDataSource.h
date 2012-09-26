//
//  RACTableViewDataSource.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import <Foundation/Foundation.h>

@interface RACTableViewDataSource : NSObject

@property (nonatomic, copy, readonly) NSArray *items;

- (instancetype)initWithSubscribable:(id<RACSubscribable>)subscribable;

@end
