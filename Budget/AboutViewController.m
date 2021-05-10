//
//  AboutViewController.m
//  Budget
//
//  Created by Nikolay Spassov on 13.01.13.
//
//

#import "AboutViewController.h"
#import "RageIAPHelper.h"
#import <StoreKit/StoreKit.h>

@interface AboutViewController () {
    NSArray *_products;
    NSNumberFormatter * _priceFormatter;
}
@end

@implementation AboutViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setBought
{
    [self.thankYou setText:@"Thank you for buying One Budget"];
    [self.thankYou setFont:[UIFont boldSystemFontOfSize:16.0]];
    [self.trialInfoView setHidden:YES];

    int vcCount = [[(UITabBarController*)([[UIApplication sharedApplication] delegate].window.rootViewController) viewControllers] count];
    for(int i = 0; i != vcCount-1; i++) {
        UIView* vc = [[[(UITabBarController*)([[UIApplication sharedApplication] delegate].window.rootViewController) viewControllers] objectAtIndex:i] view];
        [vc setUserInteractionEnabled:YES];
        [[vc viewWithTag:999] removeFromSuperview];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
#ifndef DEBUG
//    [Flurry logEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title} timed:YES];
#endif

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
    
    if([[RageIAPHelper sharedInstance] productPurchased:@"net.colbis.Budget.full"]) {
        [self setBought];
    }
    else {
        [[RageIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
            if (success) {
                _products = products;
                for(SKProduct* p in _products) {
                    if([[p productIdentifier] isEqualToString:@"net.colbis.Budget.full"]) {
                        [_priceFormatter setLocale:p.priceLocale];
                        self.buyButton.tag = [_products indexOfObject:p];
                        [self.buyButton setTitle:[NSString stringWithFormat:@"Buy Full Version for %@", [_priceFormatter stringFromNumber:p.price]] forState:UIControlStateNormal];
                        break;
                    }
                }
            }
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

#ifndef DEBUG
//    [Flurry endTimedEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title}];
#endif
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    _priceFormatter = [[NSNumberFormatter alloc] init];
    [_priceFormatter setFormatterBehavior:NSNumberFormatterBehaviorDefault];
    [_priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setBuyButton:nil];
    [self setTrialInfoView:nil];
    [super viewDidUnload];
}

- (IBAction)buyButtonPressed:(id)sender {
    if([_products count] == 0) {
        [[RageIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
            if (success) {
                _products = products;
                for(SKProduct* p in _products) {
                    if([[p productIdentifier] isEqualToString:@"net.colbis.Budget.full"]) {
                        [_priceFormatter setLocale:p.priceLocale];
                        self.buyButton.tag = [_products indexOfObject:p];
                        [self.buyButton setTitle:[NSString stringWithFormat:@"Buy Full Version for %@", [_priceFormatter stringFromNumber:p.price]] forState:UIControlStateNormal];
                        [[RageIAPHelper sharedInstance] buyProduct:p];
                        break;
                    }
                }
            }
        }];
    }
    else {
        for(SKProduct* p in _products) {
            if([[p productIdentifier] isEqualToString:@"net.colbis.Budget.full"]) {
                [[RageIAPHelper sharedInstance] buyProduct:p];
                break;
            }
        }
    }
}

- (IBAction)restoreButtonPressed:(id)sender
{
    [[RageIAPHelper sharedInstance] restoreCompletedTransactions];
}

- (void)productPurchased:(NSNotification *)notification {
    NSString * productIdentifier = notification.object;
    [_products enumerateObjectsUsingBlock:^(SKProduct * product, NSUInteger idx, BOOL *stop) {
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
            [self setBought];
            *stop = YES;
        }
    }];
}

@end
