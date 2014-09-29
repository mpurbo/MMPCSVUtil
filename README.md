MMPCSVUtil
==========

Utility for parsing comma-separated values (CSV) files with blocks and functional programming idioms. 

Features:
* Supports CSV or other user specified delimiter.
* Blocks for interacting with the parser.
* Functional programming idioms (filter, map, etc.)

## Installation

The recommended way to install is by using [CocoaPods](http://cocoapods.org/). Once you have CocoaPods installed, add the following line to your project's Podfile:
```
pod "MMPCSVUtil"
```

## Usage

Include the header file in your code:
```objectivec
#import <MMPCSVUtil/MMPCSVUtil.h>
```

The easiest way to read CSV is simply to read all records as NSArray. Each of the records would be NSArray so the result of the following example is an NSArray of NSArrays:
```objectivec
NSArray *allRecords = [[MMPCSV readURL:[[NSBundle mainBundle] URLForResource: @"test1" withExtension:@"csv"]] 
                               all];
NSLog(@"CSV has %lu records", [allRecords count]);
```

To save memory for larger CSV files, it's better to interact with the parser directly while it's parsing the file by specifying `each` block that will be called on each of the record produced by the parser. Following example shows how to get notified when the parser has just been finished parsing a field and a record:
```objectivec
[[[MMPCSV readURL:[[NSBundle mainBundle] URLForResource: @"test1" withExtension:@"csv"]]
          field:^(id field, NSInteger index) {
              NSLog(@"%ld, %@", index, field);
          }]
          each:^(NSArray *record, NSUInteger index) {
              NSLog(@"%ld: %@", index, record);
          }];
```

If the first line on the CSV file is a header, the values of the header can be used as keys for the record. When `useFirstLineAsKeys` is used to customize format as shown in the following example, the record passed to `each` block will be an NSDictionary.
```objectivec
[[[MMPCSV readURL:[[NSBundle mainBundle] URLForResource: @"test2" withExtension:@"csv"]]
          format:[[MMPCSVFormat defaultFormat] useFirstLineAsKeys]]
          each:^(NSDictionary *record, NSUInteger index) {
              NSLog(@"%ld: title: %@", index, [record objectForKey:@"title"]);
          }];
```

Following example shows how to:
- use `error` to handle errors;
- use `begin` to get notified when the parser starts, and optionally process the header;
- use `map` to get map parser record output into any object;
- use `filter` to filter records produced by the parser.
```objectivec
[[[[[[[MMPCSV readURL:[[NSBundle mainBundle] URLForResource: @"test2" withExtension:@"csv"]]
              format:[[[MMPCSVFormat defaultFormat]
                                     useFirstLineAsKeys]
                                     sanitizeFields]]
              error:^(NSError *error) {
                  NSLog(@"error: %@", error);
              }]
              begin:^(NSArray *header) {
                  NSLog(@"header: %@", header);
              }]
              map:^NSString *(NSDictionary *record) {
                  return [record objectForKey:@"title"];
              }]
              filter:^BOOL(NSString *title) {
                  return [title length] > 10;
              }]
              each:^(NSString *longTitle, NSUInteger index) {
                  NSLog(@"%ld: %@", index, longTitle);
              }];
```
Note that `map` will be performed *before* `filter`, thus object type passed into `filter` will be the type returned by `map`.

## Documentation

Not currently available, but I'll write documentation as I update the library.

## Contact

MMPCSVUtil is maintained by [Mamad Purbo](https://twitter.com/purubo)

## Copyright and License

MMPCSVUtil is available under the MIT license. See the LICENSE file for more info.

This library uses code adapted from CHCSVParser (https://github.com/davedelong/CHCSVParser). Copyright (c) 2014 Dave DeLong
