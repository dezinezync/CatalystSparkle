//
//  OPMLVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 05/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "OPMLVC.h"
#import "YetiThemeKit.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface OPMLVC () <UIDocumentPickerDelegate> {
    BOOL _hasSetup;
}

@property (weak, nonatomic) IBOutlet UIButton *importButton;
@property (weak, nonatomic) IBOutlet UIButton *exportButton;

@property (copy, nonatomic) NSURL *importURL;

@end

@implementation OPMLVC

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.state = OPMLStateNone;
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.detailsView.layer.cornerRadius = 18.f;
    self.detailsView.clipsToBounds = YES;
    self.detailsView.hidden = YES;
    
    self.ioView.layer.cornerRadius = 18.f;
    self.ioView.clipsToBounds = YES;
    self.ioView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_hasSetup) {
        self.state = OPMLStateDefault;
        _hasSetup = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    return theme.isDark ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

#pragma mark - State

- (void)setState:(OPMLState)state {
    
    OPMLState current = _state;
    
    _state = state;
    
    if (state == current)
        return;
    
    NSTimeInterval duration = 0.6;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    if (state == OPMLStateNone) {
        
        UIView *view = self.detailsView.isHidden ? self.ioView : self.detailsView;
        
        [UIView animateWithDuration:(duration * 0.75) animations:^{
            view.transform = CGAffineTransformMakeTranslation(0, view.bounds.size.height + 24.f);
        }];
        
    }
    else if (state == OPMLStateDefault) {
        
        for (UIButton *button in @[self.importButton, self.exportButton]) {
            button.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.3f];
        }
        
        self.detailsTitleLabel.textColor = theme.titleColor;
        self.detailsSubtitleLabel.textColor = theme.captionColor;
        
        CGAffineTransform base = self.detailsView.transform;
        
        self.detailsView.transform = CGAffineTransformTranslate(base, 0, self.detailsView.bounds.size.height);
        self.detailsView.hidden = NO;
        self.detailsView.effect = [UIBlurEffect effectWithStyle:(theme.isDark ? UIBlurEffectStyleDark : UIBlurEffectStyleLight)];
        
        weakify(self);
        
        [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            
            strongify(self);
            
            self.detailsView.transform = base;
            
        } completion:nil];
    }
    else {
        // Import/Export State
        self.ioProgressView.progress = 0.0f;
        
        CGAffineTransform base = self.ioView.transform;
        self.ioView.transform = CGAffineTransformTranslate(base, 0, self.ioView.bounds.size.height + 24.f);
        self.ioView.hidden = NO;
        
        self.ioView.effect = [UIBlurEffect effectWithStyle:(theme.isDark ? UIBlurEffectStyleDark : UIBlurEffectStyleLight)];
        
        if (state == OPMLStateImport) {
            self.ioTitleLabel.text = @"Importing OPML";
            self.ioSubtitleLabel.text = @"Uploading your file";
        }
        else {
            self.ioTitleLabel.text = @"Exporting OPML";
            self.ioSubtitleLabel.text = @"Preparing your file";
        }
        
        self.ioTitleLabel.textColor = theme.titleColor;
        self.ioSubtitleLabel.textColor = theme.captionColor;
        
        if (current == OPMLStateDefault) {
            
            weakify(self);
            
            [UIView animateWithDuration:(duration/2) delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                
                strongify(self);
                
                self.detailsView.transform = CGAffineTransformMakeTranslation(0, self.detailsView.bounds.size.height + 24.f);
                
            } completion:^(BOOL finished) { if (finished) {
                
                strongify(self);
                
                self.detailsView.hidden = YES;
                
                [UIView animateWithDuration:(duration/2) delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                    
                    self.ioView.transform = base;
                    
                } completion:nil];
                
            } }];
            
        }
    }
}

#pragma mark - Actions

- (IBAction)didTapImport:(UIButton *)sender {
    
    UIDocumentPickerViewController *importVC = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[(__bridge NSString *)kUTTypeXML] inMode:UIDocumentPickerModeImport];
    
    importVC.delegate = self;
    
    [self presentViewController:importVC animated:YES completion:nil];
    
}

- (IBAction)didTapExport:(UIButton *)sender {
}

- (IBAction)didTapCancel:(UIButton *)sender {
    self.state = OPMLStateNone;
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        strongify(self);
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

#pragma mark - <UIDocumentPickerDelegate>

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    
    if (!urls.count)
        return;
    
    self.importURL = [urls firstObject];
    self.state = OPMLStateImport;
    
}

@end
