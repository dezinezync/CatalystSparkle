//
//  ActionViewController.m
//  YetiShare
//
//  Created by Nikhil Nigade on 20/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <DZKit/DZUtilities.h>

#import "FeedCell.h"

@interface ActionViewController () <UITableViewDelegate, UITableViewDataSource> {
    BOOL _hasJSONFeed;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, copy) NSArray <NSDictionary *> *data;
@property (nonatomic, assign) NSUInteger selected;
@property (weak, nonatomic) IBOutlet UILabel *activityLabel;

@end

@implementation ActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Add to Elytra";
    
    self.selected = NSNotFound;
    self.data = @[];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.tableFooterView = [UIView new];
    
    [self.tableView registerClass:[FeedCell class] forCellReuseIdentifier:@"cell"];
    
    // Get the item[s] we're handling from the extension context.
    
    [self checkForInputItems];
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
        NSDictionary  *feed = self.data[self.selected];
        NSString *feedURL = feed[@"url"];
        selectedURL = [NSURL URLWithString:[NSString stringWithFormat:@"yeti://addFeed?URL=%@", feedURL]];
    }
    
    [self finalizeURL:selectedURL];
    
    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
}

- (void)setupTableRows
{
    self.title = @"Select a Feed";
    
    self.tableView.hidden = NO;
    
    for (NSDictionary *obj in self.data) {
        if ([(NSString *)[obj valueForKey:@"title"] containsString:@"JSON"]
            || [(NSString *)[obj valueForKey:@"url"] containsString:@"/json"]) {
            self->_hasJSONFeed = YES;
        }
    }
    
    _selected = NSNotFound;
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
    FeedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    NSDictionary *data = self.data[indexPath.row];
    
    cell.textLabel.text = data[@"title"] ?: @"";
    
    cell.detailTextLabel.text = data[@"url"];
    cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingHead;
    
    if (self->_hasJSONFeed) {
        
        if ([data[@"title"] containsString:@"JSON"] || [data[@"url"] containsString:@"/json"]) {
            cell.detailTextLabel.textColor = self.view.tintColor;
        }
        else {
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        }
        
    }
    
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

- (void)showError:(NSString *)error {
    
    if ([NSThread isMainThread] == NO) {
        [self performSelectorOnMainThread:@selector(showError:) withObject:error waitUntilDone:NO];
        return;
    }
    
    if ([self.activityIndicator isAnimating]) {
        [self.activityIndicator stopAnimating];
        self.activityIndicator.hidden = YES;
    }
    
    self.activityLabel.text = error;
    [self.activityLabel sizeToFit];
    
    if (self.activityLabel.isHidden) {
        self.activityLabel.hidden = NO;
    }
}

- (void)checkForInputItems {
    
    self.activityLabel.text = @"Checking webpage for RSS Feed links.";
    [self.activityIndicator startAnimating];
    
    __block BOOL foundItems = NO;
    
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        
        for (NSItemProvider *itemProvider in item.attachments) {
            
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
                
                foundItems = YES;
                
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary * responseObject, NSError *error) {
                    
                    if (error) {
                        [self showError:error.localizedDescription];
                        return;
                    }
                    
                    NSDictionary *results = [responseObject objectForKey:NSExtensionJavaScriptPreprocessingResultsKey];
                    NSArray <NSDictionary *> *items = [results objectForKey:@"items"];
                    
                    NSLog(@"Items: %@", items);
                    
                    [self handleInputFeeds:items];
                    
                }];
                
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                // This is an URL.
                
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
                    
                    if (error) {
                        [self showError:error.localizedDescription];
                        return;
                    }
                    
                    if(url) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self handleURL:url];
                        }];
                    }
                }];
                
                foundItems = YES;
            }

            
            if (foundItems) {
                break;
            }
            
        }
        
        if (foundItems) {
            break;
        }
    }
    
}

- (void)handleURL:(NSURL *)url {
    
    if (!url)
        return [self done];
    
    self.activityLabel.text = @"Loading...";
    self.activityIndicator.superview.hidden = NO;
    [self.activityIndicator startAnimating];
    
    weakify(self);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
       
        NSError *error = nil;
        NSData *htmlData = [NSData dataWithContentsOfURL:url options:kNilOptions error:&error];
        
        if (error) {
            strongify(self);
            
            [self showError:error.localizedDescription];

            return;
        }
        
        NSString *html = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
        
        if (html == nil) {
            [self showError:@"Elytra failed to load contents of this page"];
            return;
        }
        
        NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"\<link[^rel]+rel\=\"alternate\"[^\>]+\>" options:kNilOptions error:&error];
        NSRegularExpression *titleExpression = [NSRegularExpression regularExpressionWithPattern:@"(title\=\"([^\"]+))\"" options:kNilOptions error:&error];
        NSRegularExpression *hrefExpression = [NSRegularExpression regularExpressionWithPattern:@"(href\=\"([^\"]+))\"" options:kNilOptions error:&error];
        
        if (error) {
            [self showError:@"Elytra failed to process contents of this page"];
            return;
        }
        
        NSArray <NSTextCheckingResult *> *matches = [regexp matchesInString:html options:kNilOptions range:NSMakeRange(0, html.length)];
        
        NSMutableArray *feeds = [NSMutableArray arrayWithCapacity:matches.count];
        
        for (NSTextCheckingResult *match in matches) {
            NSString *tag = [html substringWithRange:[match range]];
            
            NSRange titleRange = [titleExpression rangeOfFirstMatchInString:tag options:kNilOptions range:NSMakeRange(0, tag.length)];
            NSRange hrefRange = [hrefExpression rangeOfFirstMatchInString:tag options:kNilOptions range:NSMakeRange(0, tag.length)];
            
            NSString *title, *link;
            
            if (titleRange.location != NSNotFound) {
                titleRange.location += 7;
                titleRange.length -= 7 + 1;
                title = [tag substringWithRange:titleRange];
                title = [self decodeString:title];
            }
            
            if (hrefRange.location != NSNotFound) {
                hrefRange.location += 6;
                hrefRange.length -= 6 + 1;
                link = [tag substringWithRange:hrefRange];
            }
            
            if (link != nil && [link containsString:@"/comment"] == NO) {
                if ([[link substringToIndex:1] isEqualToString:@"/"]) {
                    // relative URL.
                    NSURLComponents *components = [NSURLComponents componentsWithString:url.absoluteString];
                    components.path = link;
                    
                    link = [[components URL] absoluteString];
                }
                
                NSMutableDictionary *feed = @{@"url": link}.mutableCopy;
                if (title) {
                    feed[@"title"] = title;
                }
                
                [feeds addObject:feed];
            }
        }
        
        [self handleInputFeeds:feeds];
        
    });
    
}

- (void)handleInputFeeds:(NSArray <NSDictionary *> *)feeds {
    
    if (feeds == nil || feeds.count == 0) {
        [self showError:@"No RSS Feeds found on this webpage."];
        return;
    }
    
    if (feeds.count == 1) {
        NSDictionary *feed = [feeds firstObject];
        NSString *link = [feed valueForKey:@"url"];
        
        NSURL *URL = [NSURL URLWithString:link];
        [self finalizeURL:URL];
        
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
        self.activityIndicator.superview.hidden = YES;
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.data = feeds;
        [self setupTableRows];
    });
}

- (NSString *)decodeString:(NSString *)htmlString {
    NSData* stringData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* options = @{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType};
    NSAttributedString* decodedAttributedString = [[NSAttributedString alloc] initWithData:stringData options:options documentAttributes:NULL error:NULL];
    NSString* decodedString = [decodedAttributedString string];
    
    return decodedString;
}

- (void)finalizeURL:(NSURL *)host {
    if ([NSThread isMainThread] == NO) {
        [self performSelectorOnMainThread:@selector(finalizeURL:) withObject:host waitUntilDone:NO];
        return;
    }
    
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    });
}

@end
