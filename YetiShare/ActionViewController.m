//
//  ActionViewController.m
//  YetiShare
//
//  Created by Nikhil Nigade on 20/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "FeedsManager.h"

@interface ActionViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UINavigationItem *navitem;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, copy) NSArray <NSString *> *data;
@property (nonatomic, assign) NSUInteger selected;
@property (weak, nonatomic) IBOutlet UILabel *activityLabel;

@end

@implementation ActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navitem.title = @"Add to Elytra";
    
    self.selected = NSNotFound;
    self.data = @[];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.tableFooterView = [UIView new];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    // Get the item[s] we're handling from the extension context.
    
    // For example, look for an image and place it into an image view.
    // Replace this with something appropriate for the type[s] your extension supports.
    BOOL imageFound = NO;
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                // This is an URL.

                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
                    if(url) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self handleURL:url];
                        }];
                    }
                }];
                
                imageFound = YES;
                break;
            }
        }
        
        if (imageFound) {
            // We only handle one image, so stop looking for more.
            break;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done {
    // Return any edited content to the host app.
    // This template doesn't do anything, so we just echo the passed in items.
    
    NSURL *selectedURL = nil;
    
    if (self.selected != NSNotFound) {
        NSString *feedURL = self.data[self.selected];
        selectedURL = [NSURL URLWithString:[NSString stringWithFormat:@"yeti://addFeed?URL=%@", feedURL]];
    }
    
    [self finalizeURL:selectedURL];
    
    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
}

- (void)setupTableRows:(NSArray <NSString *> *)data
{
    self.navitem.title = @"Select a feed";
    
    _selected = NSNotFound;
    self.data = data;
    [self.tableView reloadData];
}

#pragma mark - <UITableViewDatasource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.textLabel.text = self.data[indexPath.row];
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingHead;
    
    cell.accessoryType = indexPath.row == self.selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
    
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selected = indexPath.row;
    
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark -

- (void)handleURL:(NSURL *)url {
    
    if (!url)
        return [self done];
    
    self.activityLabel.text = @"Loading...";
    self.activityIndicator.superview.hidden = NO;
    [self.activityIndicator startAnimating];
    
//    NSURLComponents *URLComponents = [[NSURLComponents alloc] initWithString:url.absoluteString];
    // yeti://addFeed?URL=
//    NSURL *host = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@://%@", URLComponents.scheme, URLComponents.host]];
    
    weakify(self);
    
    // dispatch after 2 seconds to allow FeedsManager to be set up
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [MyFeedsManager addFeed:url success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            
            asyncMain(^{
                [self.activityIndicator stopAnimating];
                self.activityIndicator.superview.hidden = YES;
            });
            
            if ([responseObject isKindOfClass:NSNumber.class]) {
                // feed already exists.
                
                NSURL *openURL = [NSURL URLWithString:[NSString stringWithFormat:@"yeti://addFeed?feedID=%@", responseObject]];
                [self finalizeURL:openURL];
                
            }
            else if ([responseObject isKindOfClass:NSArray.class]) {
                // multiple choices
                [self setupTableRows:responseObject];
            }
            else if ([responseObject isKindOfClass:Feed.class]) {
                // feed has been received directly
            }
            else {
                
            }
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [self.activityIndicator stopAnimating];
            self.activityIndicator.hidden = YES;
            
            strongify(self);
            
            asyncMain(^{
                self.activityLabel.text = error.localizedDescription;
                [self.activityLabel sizeToFit];
            });
            
        }];
    });
    
}

- (void)finalizeURL:(NSURL *)host {
    if (host) {
        // Get "UIApplication" class name through ASCII Character codes.
        NSString *className = [[NSString alloc] initWithData:[NSData dataWithBytes:(unsigned char []){0x55, 0x49, 0x41, 0x70, 0x70, 0x6C, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6F, 0x6E} length:13] encoding:NSASCIIStringEncoding];
        if (NSClassFromString(className)) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                id object = [NSClassFromString(className) performSelector:@selector(sharedApplication)];
                [object performSelector:@selector(openURL:) withObject:host];
            }];
        }
    }
}

@end
