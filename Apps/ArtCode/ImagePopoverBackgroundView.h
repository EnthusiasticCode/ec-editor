//
//  ImagePopoverBackgroundView.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 11/08/12.
//
//

#import <UIKit/UIKit.h>

@interface ImagePopoverBackgroundView : UIPopoverBackgroundView

@property (nonatomic, strong) UIImage *upArrowImage;
@property (nonatomic) UIEdgeInsets arrowInsets;
@property (nonatomic) UIEdgeInsets arrowLimitsInsets;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic) UIEdgeInsets backgroundInsets;

@end
