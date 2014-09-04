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
	
    [[MMPCSV readURL:[NSURL URLWithString:@""]] each:^(NSArray *record) {
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
