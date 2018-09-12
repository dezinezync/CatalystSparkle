#import <DZKit/DZObject.h>
#import "Range.h"

#import <DZKit/DZDatasourceModel.h>

#ifdef SHARE_EXTENSION
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#endif

@interface Content : DZObject <NSCoding, NSCopying, DZDatasourceModel> {

}

@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSArray <Range *> * ranges;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *alt;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSNumber *level;
@property (nonatomic, strong) NSArray <Content *> *items;
@property (nonatomic, strong) NSDictionary *attributes;
@property (nonatomic, copy) NSString *videoID;

// for images
@property (nonatomic, assign) CGSize size;
@property (nonatomic, strong) NSDictionary *srcset;

@property (nonatomic, strong) NSArray <Content *> *images;
// this property is used during <UICollectionViewDataSourcePrefetching> tasks inside the gallery
@property (nonatomic, weak) NSURLSessionTask *task;

+ (Content *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

#ifndef SHARE_EXTENSION
- (NSString *)urlCompliantWithUsersPreferenceForWidth:(CGFloat)width;
#endif

@end
