//
//  UnreadCountObservor.h
//  Elytra
//
//  Created by Nikhil Nigade on 08/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol UnreadCountObservor <NSObject>

- (void)unreadCountChangedFor:(id)item to:(NSNumber *)count;

@end

NS_ASSUME_NONNULL_END
