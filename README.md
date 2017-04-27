# MBTilesTools
MBTiles map files tools for iOS.

Small library to manipulate .mbtiles map file database. 
For example use the latests vector tiles from [OpenMapTiles](https://openmaptiles.org/downloads/).
This library supports all kind of tiles sets, jpg, png and pbf.

**Link requirements**
You need to link this library with sqlite3 and MapKit.

## Reader
MBTilesReader is the easiest way to access to the database content.

### Reader init
Init the reader with your .mbtiles path

```ObjC
NSString *filePath = @"my_file_path";
MBTilesReader *reader = [[MBTilesReader alloc] initWithFilePath:filePath];
```

### Reader open/close
The reader needs to be opened before any use. If the .mbtiles file is not correctely set, 
this methods will inform you about the problem

```ObjC
if ([reader open]) {
	NSLog(@"Good, use the reader");
}
else
{
	NSLog(@"Error, verify your file path and content");
}
```
### Reader metadata
Access to all your .mbtiles metadata

```ObjC
MBTilesFormat format = [reader format];
if (format == MBTilesFormatPBF) {
	NSLog(@"Good, got vector tiles");
}
else {
	NSLog(@"Error, not vector tiles DB");
}
```

### Reader tiles
Access to the tiles bytes by fetching them with x, y, z

```ObjC
NSData *tile = [reader tileForX:0 Y:0 Z:1];
NSLog(@"got tile 0/0/1, length %@ bytes", @(tile.length));
```
