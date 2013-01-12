//
//  QuickFileHighlightTableController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 29/08/12.
//
//

#import "QuickFileHighlightTableController.h"

#import "CodeFileController.h"
#import "TMUnit.h"
#import "TMSyntaxNode.h"
#import "FileSystemFile+TextFile.h"

@interface QuickFileHighlightTableController ()

@property (nonatomic, strong) NSArray *syntaxes;
@property (nonatomic, strong) TMSyntaxNode *currentSyntax;

@end

@implementation QuickFileHighlightTableController

#pragma mark - View lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (!self) {
    return nil;
  }
  
  NSArray *allSyntaxes = [@[[NSNull null]] arrayByAddingObjectsFromArray:[TMSyntaxNode.allSyntaxes.allValues sortedArrayUsingComparator:^NSComparisonResult(TMSyntaxNode *obj1, TMSyntaxNode *obj2) {
    return [obj1.name compare:obj2.name];
  }]];
  
  @weakify(self);
  
  // Setup the syntax list and the bindings with the explicit syntax identifier every time the file changes
  __block RACDisposable *sourceDisposable = nil;
  __block RACDisposable *sinkDisposable = nil;
  [RACAble(self.codeFileController.textFile) subscribeNext:^(FileSystemFile *x) {
    @strongify(self);
    [sourceDisposable dispose];
    [sinkDisposable dispose];
    // Set syntaxes to nil to clear out the table while the explicit syntax identifier is being retrieved
    self.syntaxes = nil;
    self.currentSyntax = nil;
    sourceDisposable = [[[x.explicitSyntaxIdentifierSubject doNext:^(id _) {
      @strongify(self);
      // If this is the first time the explicit syntax identifier is sent, the syntaxes will still be nil, in that case set the syntaxes back
      if (!self.syntaxes) {
        self.syntaxes = allSyntaxes;
      }
    }] map:^TMSyntaxNode *(NSString *x) {
      return [TMSyntaxNode syntaxWithScopeIdentifier:x];
    }] toProperty:@keypath(self.currentSyntax) onObject:self];
    sinkDisposable = [[RACAble(self.currentSyntax) map:^NSString *(TMSyntaxNode *x) {
      return x.identifier;
    }] subscribe:x.explicitSyntaxIdentifierSubject];
  }];
  
  // Reload the table when the current syntax or the syntaxes change
  [[RACSignal combineLatest:@[RACAbleWithStart(self.currentSyntax), RACAbleWithStart(self.syntaxes), RACAble(self.tableView)]] subscribeNext:^(RACTuple *xs) {
    [xs.third reloadData];
  }];
  
  return self;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.syntaxes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (indexPath.row == 0) {
    cell.textLabel.text = @"Automatic";
  } else {
    cell.textLabel.text = [(TMSyntaxNode *)(self.syntaxes)[indexPath.row] name];
  }
  if ((indexPath.row == 0 && self.currentSyntax == nil) || [cell.textLabel.text isEqualToString:self.currentSyntax.name]) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
    
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == 0) {
    self.currentSyntax = nil;
  } else {
    self.currentSyntax = (self.syntaxes)[indexPath.row];
  }
}

@end
