//
//  MBTilesReader.m
//  MBTilesTools
//
//  Created by Romain Quidet on 26/04/2017.
//  Copyright © 2017 XDAppfactory. All rights reserved.
//

#import "MBTilesReader.h"
#import <sqlite3.h>
#import "DLog.h"
#import "NSString+Tokenize.h"
#import "NSMutableArray+TrimWhiteSpace.h"
#import "RegionBBoxConverter.h"

@interface MBTilesReader () {
    sqlite3* db;
    sqlite3_stmt *metaDataStatement;
    sqlite3_stmt *tilesStatement;
}

@property (nonatomic, strong) NSString *filePath;

@end

@implementation MBTilesReader

#pragma mark - Lifecycle

- (instancetype)initWithFilePath:(NSString *)path {
    self = [super init];
    if (self) {
        _filePath = [path copy];
    }
    return self;
}

- (void)dealloc {
    if (metaDataStatement != NULL
        || tilesStatement != NULL
        || db != NULL) {
        [self close];
    }
}

- (BOOL)open {
    if (db != NULL) {
        return NO;
    }
    int err = sqlite3_open_v2([self.filePath UTF8String], &db, SQLITE_OPEN_READONLY, NULL);
    if (err != SQLITE_OK) {
        DLog(@"Error: open %i", err);
        return NO;
    }
    return YES;
}

- (void)close {
    if (metaDataStatement) {
        sqlite3_finalize(metaDataStatement);
        metaDataStatement = NULL;
    }

    if (tilesStatement) {
        sqlite3_finalize(tilesStatement);
        tilesStatement = NULL;
    }

    if (db) {
        int  res;
        BOOL retry;
        int numberOfRetries = 0;
        do {
            retry = NO;
            res = sqlite3_close(db);
            if (SQLITE_BUSY == res) {
                retry = YES;
                usleep(20);
                if (numberOfRetries++ > 5) {
                    DLog(@"Error: database busy, unable to close");
                    return;
                }
            }
            else if (SQLITE_OK != res) {
                DLog(@"Error: close %d", res);
            }
        }
        while (retry);
        
        db = NULL;
    }
}

#pragma mark - Accessors for the database metadata

- (NSString *)name
{
    return [self metaDataValueForKey:@"name"];
}

- (NSString *)databaseVersion
{
    return [self metaDataValueForKey:@"version"];
}

- (MBTilesFormat)format {
    NSString *format = [self metaDataValueForKey:@"format"];
    MBTilesFormat result = MBTilesFormatUnknown;
    if ([format isEqualToString:@"png"]) {
        result = MBTilesFormatPNG;
    }
    else if ([format isEqualToString:@"jpg"]) {
        result = MBTilesFormatJPG;
    }
    else if ([format isEqualToString:@"pbf"]) {
        result = MBTilesFormatPBF;
    }

    return result;
}

- (MBTilesType)type {
    NSString *type = [self metaDataValueForKey:@"type"];
    MBTilesType result = MBTilesTypeBaseLayer;
    if ([type isEqualToString:@"overlay"]) {
        result = MBTilesTypeOverlay;
    }
    return result;
}

- (MKCoordinateRegion)region
{
    // bbox = min Longitude , min Latitude , max Longitude , max Latitude
    NSString *bbox = [self metaDataValueForKey:@"bounds"];
    return [self regionForBBoxInString:bbox];
}

- (CLLocationCoordinate2D)center
{
    return [self region].center;
}

- (NSUInteger)minZoom
{
    return (NSUInteger)[[self metaDataValueForKey:@"minzoom"] integerValue];
}

- (NSUInteger)maxZoom
{
    return (NSUInteger)[[self metaDataValueForKey:@"maxzoom"] integerValue];
}

#pragma mark - Interface

- (NSData *)tileForX:(NSUInteger)x Y:(NSUInteger)y Z:(NSUInteger)zoom
{
    NSData *result;
    int sqlRes;
    if (tilesStatement == NULL) {
        NSString *query = @"SELECT tile_data FROM tiles WHERE tile_column = ? AND tile_row = ? AND zoom_level = ?";
        sqlRes = sqlite3_prepare_v2(db, [query UTF8String], (int)query.length, &tilesStatement, NULL);
        if (sqlRes != SQLITE_OK) {
            DLog(@"Error: tileForXYZ prepare %s (%@)", sqlite3_errmsg(db), @(sqlRes));
            return result;
        }
    }
    else {
        sqlRes = sqlite3_reset(tilesStatement);
        if (sqlRes != SQLITE_OK) {
            DLog(@"Error: tileForXYZ reset %s (%@)", sqlite3_errmsg(db), @(sqlRes));
            return result;
        }
    }

    sqlite3_bind_int(tilesStatement, 1, (int)x);
    sqlite3_bind_int(tilesStatement, 2, (int)y);
    sqlite3_bind_int(tilesStatement, 3, (int)zoom);

    sqlRes = sqlite3_step(tilesStatement);
    if (sqlRes == SQLITE_ROW) {
        const void *value = sqlite3_column_blob(tilesStatement, 0);
        int length = sqlite3_column_bytes(tilesStatement, 0);
        result = [NSData dataWithBytes:value length:length];
    }
    else
    {
        DLog(@"Error: tileForXYZ step is not a row: %@", @(sqlRes));
    }

    return result;
}


#pragma mark - Internals

- (NSString *)metaDataValueForKey:(NSString *)key
{
    NSString *ret;
    int sqlRes;
    if (metaDataStatement == NULL) {
        NSString *query = @"SELECT value FROM metadata WHERE name = ?";
        sqlRes = sqlite3_prepare_v2(db, [query UTF8String], (int)query.length, &metaDataStatement, NULL);
        if (sqlRes != SQLITE_OK) {
            DLog(@"Error: metaDataValueForKey prepare %@ - %s (%@)", key, sqlite3_errmsg(db), @(sqlRes));
            return ret;
        }
    }
    else {
        sqlRes = sqlite3_reset(metaDataStatement);
        if (sqlRes != SQLITE_OK) {
            DLog(@"Error: metaDataValueForKey reset %@ - %s (%@)", key, sqlite3_errmsg(db), @(sqlRes));
            return ret;
        }
    }

    sqlRes = sqlite3_bind_text(metaDataStatement, 1, [key UTF8String], (int)key.length, NULL);
    if (sqlRes != SQLITE_OK) {
        DLog(@"Error: metaDataValueForKey bind %@ - %s (%@)", key, sqlite3_errmsg(db), @(sqlRes));
        return ret;
    }
    sqlRes = sqlite3_step(metaDataStatement);
    if (sqlRes == SQLITE_ROW) {
        const unsigned char *value = sqlite3_column_text(metaDataStatement, 0);
        ret = [NSString stringWithUTF8String:(char *)value];
    }
    else
    {
        DLog(@"Error: metaDataValueForKey step is not a row");
    }

    return ret;
}

- (MKCoordinateRegion)regionForBBoxInString:(NSString *)bboxInString
{
    NSMutableArray *arrayOfCoords = [bboxInString tokenizeByString:@","];
    OSMBoundingBox bbox =
    OSMBoundingBoxMake([arrayOfCoords[0] doubleValue],
                       [arrayOfCoords[1] doubleValue],
                       [arrayOfCoords[2] doubleValue],
                       [arrayOfCoords[3] doubleValue]);
    return [RegionBBoxConverter regionFromBBox:bbox];
}

@end
