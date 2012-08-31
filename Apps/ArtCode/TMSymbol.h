//
//  TMSymbol.h
//  ArtCode
//
//  Created by Uri Baghin on 4/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UIImage, TMScope;


/// Represent a symbol returned by the symbolList method in TMUnit.
@interface TMSymbol : NSObject

@property (nonatomic, strong, readonly) NSString *qualifiedIdentifier;
@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) UIImage *icon;
@property (nonatomic, readonly) NSRange range;
@property (nonatomic, readonly) NSUInteger indentation;
@property (nonatomic, readonly, getter = isSeparator) BOOL separator;

- (id)initWithScope:(TMScope *)scope;

@end

