//
//  CatalystHeaders.h
//  Yeti
//
//  Created by Nikhil Nigade on 26/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

#ifndef CatalystHeaders_h
#define CatalystHeaders_h

#import <Foundation/Foundation.h>

@interface NSToolbarItem_Catalyst : NSToolbarItem

@property id view;

@property CGSize minSize;
@property CGSize maxSize;

+ (instancetype)searchItemWithItemIdentifier:(NSString *)itemIdentifier textDidChangeHandler:(void(^)(NSString *stringValue))textDidChangeHandler;

@property (nonatomic) NSString *searchFieldStringValue;
- (void)searchItemBecomeFirstResponder;

@end

@interface NSToolbar_Catalyst : NSToolbar

@property NSToolbarSizeMode sizeMode;

@end

@interface IPDFToolbarHelper : NSObject

@end

#endif /* CatalystHeaders_h */
