//
//  OPMLVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 05/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "OPMLVC.h"
#import "FeedsManager.h"
#import "YTNavigationController.h"
#import "FeedsManager.h"
#import "StoreVC.h"

#import "ImportVC.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import <DZNetworking/DZUploadSession.h>
#import <DZKit/AlertManager.h>
#import "DZLoggingJSONResponseParser.h"

@interface OPMLVC () <UIDocumentPickerDelegate> {
    BOOL _hasSetup;
    
    // When we present the document picker, the view of the navigation controller
    // is removed from the window
    // when it is added back, it is assigned the frame of the presenting view
    // and therefore breaks the deck transition.
    CGRect _navigationControllerFrame;
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
    
    self.navigationController.navigationBarHidden = YES;
    
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    
    self.detailsTitleLabel.textColor = UIColor.labelColor;
    self.detailsSubtitleLabel.textColor = UIColor.secondaryLabelColor;
    
    self.detailsView.backgroundColor = UIColor.systemBackgroundColor;
    self.detailsView.hidden = YES;

    self.ioTitleLabel.textColor = UIColor.labelColor;
    self.ioSubtitleLabel.textColor = UIColor.secondaryLabelColor;
    
    self.ioView.backgroundColor = UIColor.systemBackgroundColor;
    self.ioView.hidden = YES;
    
    [self.ioDoneButton addTarget:self action:@selector(didTapCancel:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (!_hasSetup) {
        self.state = OPMLStateDefault;
        _hasSetup = YES;
#if !TARGET_OS_MACCATALYST
        self.importButton.backgroundColor = [SharedPrefs.tintColor colorWithAlphaComponent:0.2f];
        self.exportButton.backgroundColor = [SharedPrefs.tintColor colorWithAlphaComponent:0.2f];
#endif
    }
    else if (self.state == OPMLStateExport) {
        [self didTapCancel:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - State

- (void)setState:(OPMLState)state {
    
    if ([NSThread isMainThread] == NO) {
        [self performSelectorOnMainThread:@selector(setState:) withObject:@(state) waitUntilDone:NO];
        return;
    }
    
    OPMLState current = _state;
    
    _state = state;
    
    if (state == current)
        return;
    
    NSTimeInterval duration = 0.35;
    
    if (state == OPMLStateNone) {
        
        UIView *view = self.detailsView.isHidden ? self.ioView : self.detailsView;
        
        [UIView animateWithDuration:(duration/2) animations:^{
            view.alpha = 0;
        }];
        
    }
    else if (state == OPMLStateDefault) {
        
        BOOL ioHidden = self.ioView.isHidden;
        
#if !TARGET_OS_MACCATALYST
        for (UIButton *button in @[self.importButton, self.exportButton]) {
            button.backgroundColor = [self.view.tintColor colorWithAlphaComponent:0.3f];
        }
#endif
        
        self.detailsView.alpha = 0.f;
        self.detailsView.hidden = NO;
        
        weakify(self);
        
        [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            
            strongify(self);
            
            self.detailsView.alpha = 1.f;
            
            if (ioHidden == NO) {
                self.ioView.alpha = 0.f;
            }
            
        } completion:^(BOOL finished) {
            
            if (ioHidden == NO) {
                self.ioView.hidden = YES;
            }
            
        }];
    }
    else {
        // Import/Export State
        self.ioProgressView.progress = 0.0f;

        self.ioView.alpha = 0.f;
        self.ioView.hidden = NO;
        
        if (state == OPMLStateImport) {
            self.ioTitleLabel.text = @"Importing Subscriptions";
            self.ioSubtitleLabel.text = @"Uploading your file";
        }
        else {
            self.ioTitleLabel.text = @"Exporting Subscriptions";
            self.ioSubtitleLabel.text = @"Preparing your file";
            
            self.ioDoneButton.enabled = NO;
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
    
    if (MyFeedsManager.subscription == nil || [MyFeedsManager.subscription hasExpired]) {
        // A subscription is required to import Feeds from an OPML file.
        if (MyFeedsManager.subscription == nil) {
            [MyFeedsManager setValue:[YTSubscription new] forKey:@"subscription"];
        }
        
        NSString * const error = @"An active subscription is required to import Subscriptions files in to Elytra.";
        
        MyFeedsManager.subscription.error = [NSError errorWithDomain:@"Yeti" code:402 userInfo:@{NSLocalizedDescriptionKey: error}];
        
        UIViewController *presenting = self.presentingViewController;
        
        StoreVC *storeVC = [[StoreVC alloc] initWithStyle:UITableViewStylePlain];
//        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:storeVC];
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
                [(UINavigationController *)presenting pushViewController:storeVC animated:YES];
            }
            
        }];
        return;
    }

    // get the UTI for an extension
    NSString *typeForExt = (__bridge NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, CFSTR("opml"), NULL);
    
    UTType *xmlTypeIdentifier = [UTType typeWithIdentifier:(__bridge NSString *)kUTTypeXML];
    UTType *opmlTypeIdentifier = [UTType typeWithIdentifier:typeForExt];
    
    NSMutableArray <UTType *> *documentTypes = @[].mutableCopy;
    
    if (xmlTypeIdentifier) {
        [documentTypes addObject:xmlTypeIdentifier];
    }
    
    if (opmlTypeIdentifier) {
        [documentTypes addObject:opmlTypeIdentifier];
    }
    
    /**
     * Proposed new method crashes on Beta 6
     */
//    UIDocumentPickerViewController *importVC = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:documentTypes inMode:UIDocumentPickerModeImport];
    
    UIDocumentPickerViewController *importVC = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:documentTypes asCopy:YES];
    
    importVC.delegate = self;
    
    _navigationControllerFrame = self.navigationController.view.frame;
    
    [self.navigationController presentViewController:importVC animated:YES completion:nil];
    
}

- (IBAction)didTapExport:(UIButton *)sender {
    
    self.state = OPMLStateExport;
    
    [self downloadFile];
    
}

- (IBAction)didTapCancel:(UIButton *)sender {
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - <UIDocumentPickerDelegate>

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    
    self.navigationController.view.frame = _navigationControllerFrame;
    
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
    
    self.navigationController.view.frame = _navigationControllerFrame;
    
    if (!self.ioView.isHidden) {
        self.ioDoneButton.enabled = YES;
    }
    
    if (self.state == OPMLStateExport) {
        self.ioSubtitleLabel.text = @"File export was cancelled.";
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
            self.ioSubtitleLabel.text = @"File exported successfully.";
            
            self->_navigationControllerFrame = self.navigationController.view.frame;
            
            UIDocumentPickerViewController *exportVC = [[UIDocumentPickerViewController alloc] initForExportingURLs:@[fileURL]];
            
            exportVC.delegate = (id <UIDocumentPickerDelegate>)self;
            
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
    self.state = OPMLStateImport;
    
    weakify(self);
    
    NSString *url = [MyFeedsManager.session.baseURL.absoluteString stringByAppendingString:@"/user/opml"];

    url = [url stringByAppendingFormat:@"?userID=%@", MyFeedsManager.userID];
    
    DZUploadSession *session = [DZUploadSession shared];
    session.session.responseParser = [DZLoggingJSONResponseParser new];
    
    __unused NSURLSessionTask *task = [session UPLOAD:self.importURL.path fieldName:@"file" URL:url parameters:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
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
            self.state = OPMLStateDefault;
            self.ioDoneButton.enabled = YES;
        });

    }];
    
}

- (void)handleOPMLData:(NSDictionary *)response {
    
    id obj = response;
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        self.ioSubtitleLabel.text = @"Uploaded. The import process will begin shortly.";
        [self.ioSubtitleLabel sizeToFit];
        
//        self.ioDoneButton.enabled = YES;
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

        [self.navigationController pushViewController:importVC animated:YES];
        
        self.ioDoneButton.enabled = YES;

    });
}

@end
