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
    
    [[[MMPCSV readURL:[[NSBundle mainBundle] URLForResource: @"test1" withExtension:@"csv"]]
              field:^(id field, NSInteger index) {
                  NSLog(@"%ld, %@", index, field);
              }]
              each:^(NSArray *record) {
                  NSLog(@"%@", record);
              }];
    
    // with header, error handling, and other functional goodies
    
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
                  each:^(NSString *longTitle) {
                      NSLog(@"%@", longTitle);
                  }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
