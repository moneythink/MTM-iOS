//
//  MTWebViewController.m
//  moneythink-ios
//
//  Created by David Sica on 10/29/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTWebViewController.h"

@interface MTWebViewController ()

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UIButton *backButton;

@end

@implementation MTWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self resetWebView];
    
    [self.backButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
    [self.backButton setTitleColor:[UIColor primaryOrangeDark] forState:UIControlStateHighlighted];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [MTUtil GATrackScreen:@"Web View"];
}


#pragma mark - IBActions -
- (IBAction)goBack:(id)sender
{
    [self resetWebView];
}

#pragma mark - Private Methods -
- (void)resetWebView
{
    [MBProgressHUD hideAllHUDsForView:self.webView animated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:self.fileName ofType:@"html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:htmlString baseURL:nil];
}


#pragma mark -  UIWebViewDelegate delegate methods -
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.webView animated:YES];
    hud.labelText = @"Loading...";
    hud.dimBackground = YES;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [MBProgressHUD hideAllHUDsForView:self.webView animated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [MBProgressHUD hideAllHUDsForView:self.webView animated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
