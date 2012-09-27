//
//  DocSetDownloadController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocSetDownloadController.h"
#import "DocSetDownloadManager.h"
#import "BezelAlert.h"
#import "PopoverButton.h"
#import "NSNotificationCenter+RACSupport.h"

@interface DocSetDownloadController ()

@end

@implementation DocSetDownloadController

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (!self)
    return nil;
  
  // RAC
  __weak DocSetDownloadController *this = self;
  
  // Update available docset list
  [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:DocSetDownloadManagerAvailableDocSetsChangedNotification object:nil] merge:[[NSNotificationCenter defaultCenter] rac_addObserverForName:DocSetDownloadManagerUpdatedDocSetsNotification object:nil]] subscribeNext:^(NSNotification *note) {
    if (note.name == DocSetDownloadManagerAvailableDocSetsChangedNotification) {
      this.navigationItem.rightBarButtonItem.enabled = YES;
    }
    [this.tableView reloadData];
    [(UILabel *)this.tableView.tableFooterView setText:[NSString stringWithFormat:L(@"Last updated: %@"), [NSDateFormatter localizedStringFromDate:[[DocSetDownloadManager sharedDownloadManager] lastUpdated] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle]]];
  }];
    
  return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [[[DocSetDownloadManager sharedDownloadManager] availableDownloads] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"DownloadCell";
  DocSetDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (!cell) {
    cell = [[DocSetDownloadCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.detailTextLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
  }
  
  cell.downloadInfo = [[[DocSetDownloadManager sharedDownloadManager] availableDownloads] objectAtIndex:indexPath.row];
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSDictionary *downloadInfo = [[[DocSetDownloadManager sharedDownloadManager] availableDownloads] objectAtIndex:indexPath.row];
  NSString *name = [downloadInfo objectForKey:@"name"];
	BOOL downloaded = [[[DocSetDownloadManager sharedDownloadManager] downloadedDocSetNames] containsObject:name];
	if (downloaded) {
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Already Downloaded") imageNamed:BezelAlertForbiddenIcon displayImmediatly:YES];
	} else {
		NSString *docSetURL = [downloadInfo objectForKey:@"URL"];
		[[DocSetDownloadManager sharedDownloadManager] downloadDocSetAtURL:docSetURL];
	}
}

#pragma mark - Public Methods

- (IBAction)refreshDocSetList:(id)sender {
  [sender setEnabled:NO];
  [[DocSetDownloadManager sharedDownloadManager] updateAvailableDocSetsFromWeb];
}

@end

#pragma mark -

@implementation DocSetDownloadCell

@synthesize downloadInfo=_downloadInfo, download=_download, progressView=_progressView, cancelDownloadButton=_cancelDownloadButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadStarted:) name:DocSetDownloadManagerStartedDownloadNotification object:nil];
		[self setupDownloadInfoView];
		
	}
	return self;
}

- (void)setupDownloadInfoView
{
  CGFloat progressViewWidth = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 120 : 70;
  CGFloat cancelButtonWidth = 30;
  CGFloat cancelButtonHeight = 29;
  CGFloat margin = 10;
  
  _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	
  _cancelDownloadButton = [PopoverButton buttonWithType:UIButtonTypeCustom];
  _cancelDownloadButton.frame = CGRectMake(progressViewWidth + margin, 0, cancelButtonWidth, cancelButtonHeight);
  [_cancelDownloadButton addTarget:self action:@selector(cancelDownload:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	if (!self.download) {
		return;
	}
	DocSetDownloadStatus status = self.download.status;
	if (status == DocSetDownloadStatusWaiting || status == DocSetDownloadStatusDownloading || status == DocSetDownloadStatusExtracting) {	
		self.progressView.frame = CGRectMake(60, CGRectGetMidY(self.contentView.bounds) - self.progressView.bounds.size.height * 0.5, CGRectGetWidth(self.contentView.bounds) - 70, self.progressView.frame.size.height);
		CGRect textLabelFrame = self.textLabel.frame;
		self.textLabel.frame = CGRectMake(textLabelFrame.origin.x, 3, textLabelFrame.size.width, textLabelFrame.size.height);
		CGRect detailLabelFrame = self.detailTextLabel.frame;
		self.detailTextLabel.frame = CGRectMake(detailLabelFrame.origin.x, self.contentView.bounds.size.height - CGRectGetHeight(detailLabelFrame) - 3, detailLabelFrame.size.width, detailLabelFrame.size.height);
	}
}

- (void)downloadStarted:(NSNotification *)notification
{
	if (!self.download) {
		self.download = [[DocSetDownloadManager sharedDownloadManager] downloadForURL:[self.downloadInfo objectForKey:@"URL"]];
	}
}

- (void)downloadFinished:(NSNotification *)notification
{
	if (notification.object == self.download) {
		self.download = nil;
	}
}

- (void)setDownloadInfo:(NSDictionary *)downloadInfo
{
	_downloadInfo = downloadInfo;
	NSString *URL = [_downloadInfo objectForKey:@"URL"];
	NSString *name = [_downloadInfo objectForKey:@"name"];
	BOOL downloaded = [[[DocSetDownloadManager sharedDownloadManager] downloadedDocSetNames] containsObject:name];
	if (downloaded) {
		self.textLabel.textColor = [UIColor grayColor];
	} else {
		self.textLabel.textColor = [UIColor blackColor];
	}
	self.download = [[DocSetDownloadManager sharedDownloadManager] downloadForURL:URL];
	
	self.textLabel.text = [_downloadInfo objectForKey:@"title"];
	self.imageView.image = [UIImage imageNamed:@"DocSet.png"];
}

- (void)setDownload:(DocSetDownload *)download
{
	if (_download) {
		[_download removeObserver:self forKeyPath:@"progress"];
		[_download removeObserver:self forKeyPath:@"status"];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:DocSetDownloadFinishedNotification object:_download];
	}
	
	_download = download;
	[_download addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:nil];
	[_download addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadFinished:) name:DocSetDownloadFinishedNotification object:_download];
	
	if (_download) {
		self.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
		self.progressView.progress = self.download.progress;
		self.accessoryView = self.cancelDownloadButton;
		[self.contentView addSubview:self.progressView];
	} else {
		self.textLabel.font = [UIFont boldSystemFontOfSize:18.0];
		self.accessoryView = nil;
		[self.progressView removeFromSuperview];
	}
	[self updateStatusLabel];
}

- (void)updateStatusLabel
{
	if (!self.download) {
		self.detailTextLabel.text = nil;
	} else if (self.download.status == DocSetDownloadStatusWaiting) {
		self.detailTextLabel.text = NSLocalizedString(@"Waiting...", nil);
	} else if (self.download.status == DocSetDownloadStatusDownloading) {
		NSInteger downloadSize = self.download.downloadSize;
		NSUInteger bytesDownloaded = self.download.bytesDownloaded;
		if (downloadSize != 0) {
			NSString *totalMegabytes = [NSString stringWithFormat:@"%.01f", (float)(downloadSize / pow(2, 20))];
			NSString *downloadedMegabytes = [NSString stringWithFormat:@"%.01f", (float)(bytesDownloaded / pow(2, 20))];
			if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
				self.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Downloading... (%@ MB / %@ MB)", nil), downloadedMegabytes, totalMegabytes];
			} else {
				self.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ MB / %@ MB", nil), downloadedMegabytes, totalMegabytes];
			}
		} else {
			self.detailTextLabel.text = NSLocalizedString(@"Downloading...", nil);
		}
	} else if (self.download.status == DocSetDownloadStatusExtracting) {
		int extractedPercentage = (int)(self.download.progress * 100);
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
			self.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Extracting Download... (%i%%)", nil), extractedPercentage];
		} else {
			self.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Extracting (%i%%)", nil), extractedPercentage];
		}
	} else {
		self.detailTextLabel.text = nil;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"progress"]) {
		self.progressView.progress = self.download.progress;
		[self updateStatusLabel];
	} else if ([keyPath isEqualToString:@"status"]) {
		[self updateStatusLabel];
	}
}

- (void)cancelDownload:(id)sender
{
  [[DocSetDownloadManager sharedDownloadManager] stopDownload:self.download];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_download removeObserver:self forKeyPath:@"progress"];
	[_download removeObserver:self forKeyPath:@"status"];
}

@end
