//
//  FolderCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 19/09/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Folder.h"
#import <DZTextKit/Image.h>
#import "FolderDrop.h"
#import <DZTextKit/PaddedLabel.h>

@class FolderCell;

@protocol FolderInteractionDelegate <NSObject>

- (void)didTapFolderIcon:(Folder * _Nonnull)folder cell:(FolderCell * _Nonnull)cell;

@end

extern NSString *const _Nonnull kFolderCell;

NS_ASSUME_NONNULL_BEGIN

@interface FolderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet SizedImage *faviconView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel *countLabel;

@property (weak, nonatomic) Folder * folder;

@property (weak, nonatomic) id <FolderInteractionDelegate> interactionDelegate;

- (void)configureFolder:(Folder *_Nonnull)folder;

- (void)configureFolder:(Folder * _Nonnull)folder dropDelegate:(id <FolderDrop> _Nullable)dropDelegate;

- (void)didTapIcon:(id)sender;

@end

NS_ASSUME_NONNULL_END