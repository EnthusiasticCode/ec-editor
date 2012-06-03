//
//  DocSetDownloadController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DocSetDownloadController : UITableViewController

- (IBAction)refreshDocSetList:(id)sender;

@end


@class DocSetDownload;
@interface DocSetDownloadCell : UITableViewCell {
	NSDictionary *_downloadInfo;
	DocSetDownload *_download;
  UIView *_downloadInfoView;
	UIProgressView *_progressView;
  UIButton *_cancelDownloadButton;
}

@property (nonatomic, strong) NSDictionary *downloadInfo;
@property (nonatomic, strong) DocSetDownload *download;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIButton *cancelDownloadButton;

- (void)setupDownloadInfoView;
- (void)updateStatusLabel;
- (IBAction)cancelDownload:(id)sender;

@end
