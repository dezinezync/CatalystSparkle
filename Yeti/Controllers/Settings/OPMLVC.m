//
//  OPMLVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 05/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "OPMLVC.h"
#import "FeedsManager.h"
#import "YetiThemeKit.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <DZNetworking/DZUploadSession.h>

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
    
    [self.ioDoneButton addTarget:self action:@selector(didTapCancel:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_hasSetup) {
        self.state = OPMLStateDefault;
        _hasSetup = YES;
    }
    else if (self.state == OPMLStateExport) {
        [self didTapCancel:nil];
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
        
        [UIView animateWithDuration:(duration/2) animations:^{
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
    
    self.state = OPMLStateImport;
    
}

- (IBAction)didTapExport:(UIButton *)sender {
    
    self.state = OPMLStateExport;
    
    [self downloadFile];
    
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
    
    if (self.state == OPMLStateExport)
        return;
    
    self.importURL = [urls firstObject];
    
    [self uploadFile];
    
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    
    if (!self.ioView.isHidden) {
        self.ioDoneButton.enabled = YES;
    }
    
}

#pragma mark - Network File IO

- (void)downloadFile {
    
    weakify(self);
    
    [MyFeedsManager getOPMLWithSuccess:^(NSString *responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        asyncMain(^{
            self.ioProgressView.progress = 0.5f;
        });
        
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"elytra-opml.xml"];
        
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        
        NSError *error = nil;
        
        if (![responseObject writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            [AlertManager showGenericAlertWithTitle:@"Write Error" message:error.localizedDescription fromVC:self];
            return;
        }
        
        asyncMain(^{
            self.ioProgressView.progress = 0.75f;
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.ioProgressView.progress = 1.f;
            
            UIDocumentPickerViewController *exportVC = [[UIDocumentPickerViewController alloc] initWithURLs:@[fileURL] inMode:UIDocumentPickerModeMoveToService];
            
            [self presentViewController:exportVC animated:YES completion:nil];
            
            self.ioDoneButton.enabled = YES;
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        strongify(self);
        
        [AlertManager showGenericAlertWithTitle:@"An error occurred" message:error.localizedDescription fromVC:self];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.ioDoneButton.enabled = YES;
        });
        
    }];
    
}

- (void)uploadFile {
    
    if (!self.importURL)
        return;
    
    self.ioDoneButton.enabled = NO;
    
    NSString *url = formattedString(@"http://192.168.1.15:3000/user/opml");
    url = @"https://api.elytra.app/user/opml";
#ifndef DEBUG
    url = @"https://api.elytra.app/user/opml";
#endif
    
    url = [url stringByAppendingFormat:@"?userID=%@", MyFeedsManager.userID];
    
    weakify(self);
    
    __unused NSURLSessionTask *task = [[DZUploadSession shared] UPLOAD:self.importURL.path fieldName:@"file" URL:url parameters:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.ioSubtitleLabel.text = @"Uploaded. Please refresh your feeds to update your subscriptions on this device.";
            [self.ioSubtitleLabel sizeToFit];
            
            self.ioDoneButton.enabled = YES;
            self.ioProgressView.progress = 1.f;
        });
        
    } progress:^(double completed, NSProgress *progress) {
        
        strongify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.ioProgressView.progress = completed;
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        [AlertManager showGenericAlertWithTitle:@"An error occurred" message:error.localizedDescription fromVC:self];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.ioDoneButton.enabled = YES;
        });
        
    }];
    
}

@end
