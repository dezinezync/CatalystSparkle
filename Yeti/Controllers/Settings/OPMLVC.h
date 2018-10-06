//
//  OPMLVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 05/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DZKit/DeckController.h>

typedef NS_ENUM(NSInteger, OPMLState) {
    OPMLStateNone = -1,
    OPMLStateDefault,
    OPMLStateImport,
    OPMLStateExport
};

@interface OPMLVC : UIViewController

@property (nonatomic, assign) OPMLState state;

@property (weak, nonatomic) IBOutlet UIView *ioView;
@property (weak, nonatomic) IBOutlet UILabel *ioTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *ioDoneButton;
@property (weak, nonatomic) IBOutlet UIProgressView *ioProgressView;
@property (weak, nonatomic) IBOutlet UILabel *ioSubtitleLabel;

@property (weak, nonatomic) IBOutlet UIView *detailsView;
@property (weak, nonatomic) IBOutlet UILabel *detailsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailsSubtitleLabel;

@end
