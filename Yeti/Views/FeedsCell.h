//
//  FeedsCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Image.h"
#import "FolderDrop.h"

extern NSString *const _Nonnull kFeedsCell;

@interface FeedsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet SizedImage * _Nullable faviconView;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable titleLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable countLabel;

- (void)configure:(Feed * _Nonnull)feed;

- (void)configureFolder:(Folder *_Nonnull)folder;

- (void)configureFolder:(Folder *)folder dropDelegate:(id <FolderDrop>)dropDelegate;

- (void)updateFolderCount;

@end
