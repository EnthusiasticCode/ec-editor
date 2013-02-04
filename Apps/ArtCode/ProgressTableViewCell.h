//
//  ProgressTableViewCell.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 11/10/12.
//
//

#import <UIKit/UIKit.h>

@interface ProgressTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIProgressView *progressView;

// Set a signal that yields NSNumbers with the percentage of progress, this will be reflected in the progress view.
- (void)setProgressSignal:(RACSignal *)progressSignal;

@end
