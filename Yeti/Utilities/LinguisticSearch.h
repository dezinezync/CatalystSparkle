//
//  LinguisticSearch.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSDictionary <NSLinguisticTag, NSString *> *LinguisticTagPair;
typedef NSString *LinguisticPairType;

FOUNDATION_EXPORT LinguisticPairType const LinguisticPairTypeDates;
FOUNDATION_EXPORT LinguisticPairType const LinguisticPairTypeContext;
FOUNDATION_EXPORT LinguisticPairType const LinguisticPairTypeOthers;

@interface LinguisticSearch : NSObject

@property (nonatomic, copy, class) NSArray <NSString *> *knownDateTags;

+ (NSDictionary <LinguisticPairType, NSArray <LinguisticTagPair> *> *)processText:(NSString *)text;

@end
