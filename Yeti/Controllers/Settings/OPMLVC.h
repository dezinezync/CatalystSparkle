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

@property (weak, nonatomic) IBOutlet UIView * _Nullable ioView;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable ioTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton * _Nullable ioDoneButton;
@property (weak, nonatomic) IBOutlet UIProgressView * _Nullable ioProgressView;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable ioSubtitleLabel;

@property (weak, nonatomic) IBOutlet UIView * _Nullable detailsView;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable detailsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable detailsSubtitleLabel;

- (void)didTapExport:(UIButton * _Nullable)sender;

- (void)didTapImport:(UIButton * _Nullable)sender;

@end
