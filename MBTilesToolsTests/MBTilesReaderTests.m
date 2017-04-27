//
//  MBTilesReaderTests.m
//  MBTilesReaderTests
//
//  Created by Romain Quidet on 27/04/2017.
//  Copyright © 2017 XDAppfactory. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MBTilesReader.h"

@interface MBTilesReaderTests : XCTestCase

@property (nonatomic, strong) MBTilesReader *reader;

@end

@implementation MBTilesReaderTests

- (void)setUp {
    [super setUp];
    NSString *testFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"paris_france" ofType:@"mbtiles"];
    XCTAssertNotNil(testFilePath, @"You need to download the test file paris_france.mbtiles to testFiles directory");
    self.reader = [[MBTilesReader alloc] initWithFilePath:testFilePath];
}

- (void)tearDown {

    [super tearDown];
}

- (void)testOpen {
    BOOL result = [self.reader open];
    XCTAssertTrue(result, @"reader must be able to open the file database");
}

- (void)testMetadata {
    BOOL result = [self.reader open];
    XCTAssertTrue(result, @"reader must be able to open the file database");

    NSString *res = [self.reader databaseVersion];
    XCTAssertNotNil(res, @"database version should return a string like 3.3");
    XCTAssertTrue([res isEqualToString:@"3.3"], @"set it to your test file version");

    res = [self.reader name];
    XCTAssertNotNil(res, @"name should return the database name");
    XCTAssertTrue([res isEqualToString:@"OpenMapTiles"], @"set it to your test file name");

    MBTilesFormat format = [self.reader format];
    XCTAssertTrue(format != MBTilesFormatUnknown, @"format should be found in the database");
    XCTAssertTrue(format == MBTilesFormatPBF, @"set it to your test file format");

    MBTilesType type = [self.reader type];
    XCTAssertTrue(type == MBTilesTypeBaseLayer, @"set it to your test file type");
}

- (void)testTilesData {
    BOOL result = [self.reader open];
    XCTAssertTrue(result, @"reader must be able to open the file database");

    NSData *tile = [self.reader tileForX:0 Y:0 Z:1];
    XCTAssertNotNil(tile, @"reader must be able to fetch the tile");
    XCTAssertTrue(tile.length == 4259, @"set it to your tile bytes count");

    tile = [self.reader tileForX:0 Y:0 Z:2];
    XCTAssertNotNil(tile, @"reader must be able to fetch the tile");
    XCTAssertTrue(tile.length == 3301, @"set it to your tile bytes count");

    tile = [self.reader tileForX:0 Y:0 Z:3];
    XCTAssertNotNil(tile, @"reader must be able to fetch the tile");
    XCTAssertTrue(tile.length == 1228, @"set it to your tile bytes count");
}

- (void)testMissingTile {
    BOOL result = [self.reader open];
    XCTAssertTrue(result, @"reader must be able to open the file database");

    NSData *tile = [self.reader tileForX:5 Y:5 Z:1];
    XCTAssertNil(tile, @"reader must not be able to fetch the tile");
}


@end
