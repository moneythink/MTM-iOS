//
//  MTOrganizationSelectionViewController.m
//  moneythink-ios
//
//  Created by Colin Young on 12/18/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import "MTOrganizationSelectionViewController.h"
#import "MTClassSelectionViewController.h"

#define kSelectClassIdentifier @"selectClassImmediately"

@interface MTOrganizationSelectionViewController ()

@end

@implementation MTOrganizationSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    MTClassSelectionViewController *selectClassController = [sb instantiateViewControllerWithIdentifier:@"MTClassSelectionViewController"];
    [self.navigationController pushViewController:selectClassController animated:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [MTUtil GATrackScreen:@"Edit Profile: Select Organization"];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)loadLocalResults:(MTSuccessBlock)callback {
    
    RLMResults *results = nil;
    
    [self didLoadLocalResults:results withCallback:nil];
}

- (void)loadRemoteResultsForCurrentPage {
    [self didLoadRemoteResultsWithError:nil];
}

@end
