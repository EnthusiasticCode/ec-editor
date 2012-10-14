//
//  ProgressTableViewCell.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 11/10/12.
//
//

#import <UIKit/UIKit.h>

@interface ProgressTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

/// Set a subscribable that yields NSNumbers with the percentage of progress, this will be reflected in the progress view.
- (void)setProgressSubscribable:(RACSubscribable *)progressSubscribable;

@end