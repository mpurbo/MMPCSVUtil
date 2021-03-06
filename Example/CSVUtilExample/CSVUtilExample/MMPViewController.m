//
//  MMPViewController.m
//  CSVUtilExample
//
//  Created by Purbo Mohamad on 9/2/14.
//  Copyright (c) 2014 Purbo. All rights reserved.
//

#import "MMPViewController.h"
#import <MMPCSVUtil/MMPCSVUtil.h>

@interface MMPViewController ()

@end

@implementation MMPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // basic usage producing NSArray of NSArrays
    
    NSArray *allRecords = [[MMPCSV readURL:[[NSBundle mainBundle] URLForResource: @"test1" withExtension:@"csv"]] all];
    NSLog(@"CSV has %lu records", [allRecords count]);
    
    // with callback for each field & record
    // without header, producing NSArray
    
    [[[MMPCSV readURL:[[NSBundle mainBundle] URLForResource: @"test1" withExtension:@"csv"]]
              field:^(id field, NSUInteger index) {
                  NSLog(@"%ld, %@", index, field);
              }]
              each:^(NSArray *record, NSUInteger index) {
                  NSLog(@"%ld: %@", index, record);
              }];
    
    // with header, producing NSDictionary
    
    [[[MMPCSV readURL:[[NSBundle mainBundle] URLForResource: @"test2" withExtension:@"csv"]]
              format:[[MMPCSVFormat defaultFormat] useFirstLineAsKeys]]
              each:^(NSDictionary *record, NSUInteger index) {
                  NSLog(@"%ld: title: %@", index, [record objectForKey:@"title"]);
              }];
    
    // with header, error handling, and other functional goodies
    
    [[[[[[[MMPCSV readURL:[[NSBundle mainBundle] URLForResource: @"test2" withExtension:@"csv"]]
                  format:[[[MMPCSVFormat defaultFormat]
                                         useFirstLineAsKeys]
                                         sanitizeFields]]
                  error:^(NSError *error) {
                      NSLog(@"error: %@", error);
                  }]
                  begin:^(NSArray *header, NSUInteger index) {
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
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
