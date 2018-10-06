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
#import "YTNavigationController.h"
#import "FeedsManager.h"
#import "StoreVC.h"

#import "ImportVC.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <DZNetworking/DZUploadSession.h>
#import <DZKit/AlertManager.h>

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
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.layer.cornerRadius = 20.f;
    
    self.navigationController.navigationBarHidden = YES;
    
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
            view.alpha = 0;
        }];
        
    }
    else if (state == OPMLStateDefault) {
        
        for (UIButton *button in @[self.importButton, self.exportButton]) {
            button.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.3f];
        }
        
        self.detailsView.alpha = 0.f;
        self.detailsView.hidden = NO;
        
        weakify(self);
        
        [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            
            strongify(self);
            
            self.detailsView.alpha = 1.f;
            
        } completion:nil];
    }
    else {
        // Import/Export State
        self.ioProgressView.progress = 0.0f;

        self.ioView.alpha = 0.f;
        self.ioView.hidden = NO;
        
        if (state == OPMLStateImport) {
            self.ioTitleLabel.text = @"Importing OPML";
            self.ioSubtitleLabel.text = @"Uploading your file";
        }
        else {
            self.ioTitleLabel.text = @"Exporting OPML";
            self.ioSubtitleLabel.text = @"Preparing your file";
        }
        
        if (current == OPMLStateDefault) {
            
            weakify(self);
            
            [UIView animateWithDuration:(duration/2) delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                
                strongify(self);
                
                self.detailsView.alpha = 0.f;
                self.ioView.alpha = 1.f;
                
            } completion:^(BOOL finished) { if (finished) {
                
                strongify(self);
                
                self.detailsView.hidden = YES;
                
            } }];
            
        }
    }
}

#pragma mark - Actions

- (IBAction)didTapImport:(UIButton *)sender {
    
#if TESTFLIGHT == 0
    if (MyFeedsManager.subscription == nil || [MyFeedsManager.subscription hasExpired]) {
        // A subscription is required to import Feeds from an OPML file.
        if (MyFeedsManager.subscription == nil) {
            [MyFeedsManager setValue:[Subscription new] forKey:@"subscription"];
        }
        
        NSString * const error = @"An active subscription is required to import OPML files in to Elytra.";
        
        MyFeedsManager.subscription.error = [NSError errorWithDomain:@"Yeti" code:402 userInfo:@{NSLocalizedDescriptionKey: error}];
        
        UIViewController *presenting = self.presentingViewController;
        
        StoreVC *storeVC = [[StoreVC alloc] initWithStyle:UITableViewStylePlain];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:storeVC];
//        storeVC.checkAndShowError = YES;
        
        weakify(presenting);
        
        [self dismissViewControllerAnimated:YES completion:^{
           
            strongify(presenting);
            
            if ([presenting isKindOfClass:UINavigationController.class] == NO) {
                presenting = presenting.navigationController;
            }
            
            if (presenting == nil) {
                [AlertManager showGenericAlertWithTitle:@"No Subscription" message:error];
            }
            else {
                [(UINavigationController *)presenting pushViewController:nav animated:YES];
            }
            
        }];
        return;
    }
#endif
    // get the UTI for an extension
    NSString *typeForExt = (__bridge NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, CFSTR("opml"), NULL);
    
    NSArray <NSString *> *documentTypes = @[(__bridge NSString *)kUTTypeXML, typeForExt];
    
    UIDocumentPickerViewController *importVC = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:documentTypes inMode:UIDocumentPickerModeImport];
    
    importVC.delegate = self;
    
    [self presentViewController:importVC animated:YES completion:nil];
    
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
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    });
}

#pragma mark - <UIDocumentPickerDelegate>

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    
    if (!urls.count) {
        self.state = OPMLStateDefault;
        return;
    }
    
    if (self.state == OPMLStateExport)
        return;
    
    self.state = OPMLStateImport;
    
    self.importURL = [urls firstObject];
    
    [self uploadFile];
    
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    
    if (!self.ioView.isHidden) {
        self.ioDoneButton.enabled = YES;
    }
    
    self.state = OPMLStateDefault;
    
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
        
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            strongify(self);
            
            self.ioProgressView.progress = 1.f;
            
            UIDocumentPickerViewController *exportVC = [[UIDocumentPickerViewController alloc] initWithURLs:@[fileURL] inMode:UIDocumentPickerModeMoveToService];
            
            [self presentViewController:exportVC animated:YES completion:nil];
            
            self.ioDoneButton.enabled = YES;
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        strongify(self);
        
        [AlertManager showGenericAlertWithTitle:@"An Error Occurred" message:error.localizedDescription fromVC:self];
        
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            self.ioDoneButton.enabled = YES;
        });
        
    }];
    
}

- (void)uploadFile {
    
    if (!self.importURL)
        return;
    
    self.ioDoneButton.enabled = NO;
    
    weakify(self);
    
//    [XMLConverter convertXMLURL:self.importURL completion:^(BOOL success, NSMutableDictionary * _Nonnull dictionary, NSError * _Nonnull error) {
//
//        strongify(self);
//
//        if (success == NO) {
//            if (error) {
//                [AlertManager showGenericAlertWithTitle:@"Invalid OPML File" message:error.localizedDescription fromVC:self];
//            }
//            else {
//                [AlertManager showGenericAlertWithTitle:@"Invalid OPML File" message:@"An unknown error occurred reading the OPML file." fromVC:self];
//            }
//
//            return;
//        }
//
//        DDLogDebug(@"%@ - %@", self, dictionary);
//
//    }];
    
    NSString *url = formattedString(@"http://192.168.1.15:3000/user/opml");
//    url = @"https://api.elytra.app/user/opml";
#ifndef DEBUG
    url = @"https://api.elytra.app/user/opml";
#endif

    url = [url stringByAppendingFormat:@"?userID=%@", MyFeedsManager.userID];
    
    __unused NSURLSessionTask *task = [[DZUploadSession shared] UPLOAD:self.importURL.path fieldName:@"file" URL:url parameters:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);

        [self handleOPMLData:responseObject];

    } progress:^(double completed, NSProgress *progress) {

        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            self.ioProgressView.progress = completed;
        });

    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {

        strongify(self);
        
        error = [MyFeedsManager errorFromResponse:error.userInfo];

        [AlertManager showGenericAlertWithTitle:@"An Error Occurred" message:error.localizedDescription fromVC:self];

        weakify(self);

        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            self.ioDoneButton.enabled = YES;
        });

    }];
    
}

- (void)handleOPMLData:(NSData *)response {
    NSError *error = nil;
    
    id obj = [NSJSONSerialization JSONObjectWithData:response options:kNilOptions error:&error];
    
    if (error != nil) {
        [AlertManager showGenericAlertWithTitle:@"Error Parsing OPML" message:error.localizedDescription fromVC:self];
        return;
    }
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        self.ioSubtitleLabel.text = @"Uploaded. The import process will begin shortly.";
        [self.ioSubtitleLabel sizeToFit];
        
        self.ioDoneButton.enabled = YES;
        self.ioProgressView.progress = 1.f;
    });
    
    NSArray *feeds = [obj valueForKey:@"feeds"];
    NSArray <NSString *> *folders = [obj valueForKey:@"folders"];
    NSArray <Folder *> *existingFolders = [obj valueForKey:@"userFolders"];
    
    ImportVC *importVC = [[ImportVC alloc] init];
    importVC.unmappedFeeds = feeds;
    importVC.unmappedFolders = folders;
    importVC.existingFolders = (existingFolders != nil && [existingFolders isKindOfClass:NSDictionary.class]) ? [existingFolders valueForKey:@"folders"] : @[];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        strongify(self);

        [self.navigationController setViewControllers:@[importVC]];

    });
}

@end
