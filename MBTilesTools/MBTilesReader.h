//
//  MBTilesReader.h
//  MBTilesTools
//
//  Created by Romain Quidet on 26/04/2017.
//  Copyright © 2017 XDAppfactory. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MBTilesFormat) {
    MBTilesFormatUnknown,
    MBTilesFormatPNG,
    MBTilesFormatJPG,
    MBTilesFormatPBF
};

@interface MBTilesReader : NSObject

- (instancetype)initWithFilePath:(NSString *)path;
- (BOOL)open;
- (void)close;

- (nullable NSString *)databaseVersion;
- (nullable NSString *)name;
- (MBTilesFormat)format;
- (MKCoordinateRegion)region;
- (CLLocationCoordinate2D)center;
- (NSUInteger)minZoom;
- (NSUInteger)maxZoom;

- (nullable NSData *)tileForX:(NSUInteger)x Y:(NSUInteger)y Z:(NSUInteger)zoom;

@end

NS_ASSUME_NONNULL_END
