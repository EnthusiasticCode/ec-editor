//
//  ECRelationalTableViewItem.m
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECRelationalTableViewItem.h"
#import "ECRelationalTableViewItem(Private).h"

@interface ECRelationalTableViewItem ()
{
    @private
    struct {
        unsigned int showingDeleteConfirmation:1;
        unsigned int selectionStyle:3;
        unsigned int selected:1;
        unsigned int editing:1;
        unsigned int editingStyle:3;
        unsigned int accessoryType:3;
        unsigned int editingAccessoryType:3;
        unsigned int showsAccessoryWhenEditing:1;
        unsigned int showsReorderControl:1;
        unsigned int showDisclosure:1;
        unsigned int disclosureClickable:1;
        unsigned int disclosureStyle:1;
        unsigned int showingRemoveControl:1;
        unsigned int sectionLocation:3;
        unsigned int usingDefaultSelectedBackgroundView:1;
        unsigned int wasSwiped:1;
        unsigned int highlighted:1;
        unsigned int style:12;
        unsigned int clipsContents:1;
        unsigned int animatingSelection:1;
        unsigned int backgroundColorSet:1;
    } flags_;
}
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UILabel *textLabel;
@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) UIImageView *zoomedImageView;
@property (nonatomic, retain) UILabel *zoomedTextLabel;
@property (nonatomic, retain) UIView *zoomedContentView;
@end

@implementation ECRelationalTableViewItem

@synthesize imageView = imageView_;
@synthesize textLabel = textLabel_;
@synthesize contentView = contentView_;
@synthesize zoomedImageView = zoomedImageView_;
@synthesize zoomedTextLabel = zoomedTextLabel_;
@synthesize zoomedContentView = zoomedContentView_;
@synthesize backgroundView = backgroundView_;
@synthesize selectedBackgroundView = selectedBackgroundView_;
@synthesize selectionStyle = selectionStyle_;
@synthesize selected = selected_;
@synthesize highlighted = highlighted_;
@synthesize editingStyle = editingStyle_;
@synthesize showsReorderControl = showsReorderControl_;
@synthesize accessoryType = accessoryType_;
@synthesize accessoryView = accessoryView_;
@synthesize editingAccessoryType = editingAccessoryType_;
@synthesize editingAccessoryView = editingAccessoryView_;
@synthesize editing = editing_;
@synthesize showingDeleteConfirmation = showingDeleteConfirmation_;

- (void)dealloc
{
    self.imageView = nil;
    self.textLabel = nil;
    self.contentView = nil;
    self.zoomedImageView = nil;
    self.zoomedTextLabel = nil;
    self.zoomedContentView = nil;
    self.backgroundView = nil;
    self.selectedBackgroundView = nil;
    self.accessoryView = nil;
    self.editingAccessoryView = nil;
    [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    self.contentView = [[UIView alloc] init];
    self.imageView = [[UIImageView alloc] init];
    [self.contentView addSubview:self.imageView];
    self.imageView.frame = CGRectMake(0.0, 0.0, 100.0, 80.0);
    self.textLabel = [[UILabel alloc] init];
    [self.contentView addSubview:self.textLabel];
    self.textLabel.frame = CGRectMake(0.0, 0.0, 100.0, 20.0);
    [self.contentView sizeToFit];
    
    self.zoomedContentView = [[UIView alloc] init];
    self.zoomedImageView = [[UIImageView alloc] init];
    [self.zoomedContentView addSubview:self.zoomedImageView];
    self.zoomedImageView.frame = CGRectMake(0.0, 0.0, 200.0, 160.0);
    self.zoomedTextLabel = [[UILabel alloc] init];
    [self.zoomedContentView addSubview:self.zoomedTextLabel];
    self.zoomedTextLabel.frame = CGRectMake(0.0, 0.0, 200.0, 40.0);
    [self.zoomedContentView sizeToFit];
    return self;
}

- (void)setup
{
    
}

@end
