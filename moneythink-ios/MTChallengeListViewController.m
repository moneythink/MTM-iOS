//
//  MTChallengeListViewController.m
//  moneythink-ios
//
//  Created by David Sica on 5/29/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTChallengeListViewController.h"
#import "MTChallengeListTableViewCell.h"

@interface MTChallengeListViewController ()

@end

@implementation MTChallengeListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource methods -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    return [self.challenges count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MTChallenge *challenge = [self.challenges objectAtIndex:indexPath.section];
    
    MTChallengeListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChallengeListTableViewCell" forIndexPath:indexPath];
    NSInteger challengeNumber = indexPath.section+1;
    cell.challengeNumber.text = [NSString stringWithFormat:@"%ld", (long)challengeNumber];
    cell.challengeTitle.text = challenge.title;
    
    return cell;
}


#pragma mark - UITableViewDelegate Methods -
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if ([self.delegate respondsToSelector:@selector(didSelectChallenge:withIndex:)]) {
        [self.delegate didSelectChallenge:[self.challenges objectAtIndex:indexPath.section] withIndex:indexPath.section];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Actions -
- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Public -
- (void)setCurrentChallenge:(MTChallenge *)currentChallenge
{
    if (_currentChallenge != currentChallenge) {
        _currentChallenge = currentChallenge;
        
        [self.tableView reloadData];
        NSInteger indexOfCurrentChallenge = [self.challenges indexOfObject:currentChallenge];
        if (indexOfCurrentChallenge > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexOfCurrentChallenge] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    }
}


@end
