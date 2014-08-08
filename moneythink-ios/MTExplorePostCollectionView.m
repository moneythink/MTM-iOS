//
//  MTExplorePostCollectionView.m
//  moneythink-ios
//
//  Created by jdburgie on 8/7/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTExplorePostCollectionView.h"

@implementation MTExplorePostCollectionView

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (PFQuery *)queryForCollection
{
    PFQuery *query = [PFQuery queryWithClassName:@"Foo"];
//    MTPostsTabBarViewController *postTabBarViewController = (MTPostsTabBarViewController *)self.parentViewController;
//    self.challengeNumber = postTabBarViewController.challengeNumber;
//    
//    NSPredicate *challengeNumber = [NSPredicate predicateWithFormat:@"challenge_number = %d",
//                                    [self.challengeNumber intValue]];
//    
//    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName predicate:challengeNumber];
//    
//    // If no objects are loaded in memory, we look to the cache first to fill the table
//    // and then subsequently do a query against the network.
//    if ([self.objects count] == 0) {
//        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
//    }
//    
//    [query includeKey:@"user"];
//    [query includeKey:@"reference_post"];
//    
    return query;
}

# pragma mark - Collection View data source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Foo" forIndexPath:indexPath];
    
    cell.backgroundColor = [UIColor colorWithRed:[object[@"color"][@"red"] floatValue]
                                           green:[object[@"color"][@"green"] floatValue]
                                            blue:[object[@"color"][@"blue"] floatValue]
                                           alpha:1];
    
    [(UILabel *)[cell viewWithTag:1] setText:object[@"name"]];
    
    return cell;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
