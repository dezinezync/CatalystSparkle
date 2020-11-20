//
//  RecommendationsVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 29/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecommendationsVC : UICollectionViewController <UIViewControllerRestoration>

@property (nonatomic, assign, getter=isOnboarding) BOOL onboarding;

@property (nonatomic, assign) BOOL noAuth;

@property (atomic, assign) BOOL isFromAddFeed;

@end
