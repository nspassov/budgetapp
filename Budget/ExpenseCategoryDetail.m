//
//  ExpenseCategoryDetail.m
//  Budget
//
//  Created by Nikolay Spassov on 05.10.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ExpenseCategoryDetail.h"
#import "BudgetAppDelegate.h"
#import "TrackedAmounts.h"

@implementation ExpenseCategoryDetail
@synthesize chartCanvas = _chartCanvas;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize expenseCategoryName = _expenseCategoryName;
@synthesize amountBudgetedForCategory = _amountBudgetedForCategory;
@synthesize amountSpentThisMonth = _amountSpentThisMonth;
@synthesize amountSpentLabel = _amountSpentLabel;



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
#ifndef DEBUG
//    [Flurry logEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title} timed:YES];
#endif
    self.title = self.expenseCategoryName;
    self.managedObjectContext = ((BudgetAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    NSError *error;
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMinimumFractionDigits:2];
    [formatter setLocale:[NSLocale currentLocale]];
    NSString* mainCurrency = [formatter currencyCode];
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if([lastState valueForKey:@"mainCurrency"]) {
        mainCurrency = [lastState valueForKey:@"mainCurrency"];
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Amounts" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate* filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"note == '%@'", self.expenseCategoryName]];
    [fetchRequest setPredicate:filter];
    NSArray* buf = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSDecimalNumber* dBudgeted = [[buf lastObject] amount];
    double budgeted = fabs([dBudgeted doubleValue]);
    self.amountBudgetedForCategory.text = [NSString stringWithFormat:@"(%@ %@)", [formatter stringFromNumber:[dBudgeted decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], [[buf lastObject] currency]];
    
    NSMutableArray* monthlySums = [NSMutableArray array];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    

    NSString* fpath = [[NSBundle mainBundle] pathForResource:@"chart/category" ofType: @"html"];
    NSString* s = [NSString stringWithContentsOfFile:fpath encoding:NSUTF8StringEncoding error:&error];
    s = [s stringByReplacingOccurrencesOfString:@"CUSTOM_HEIGHT" withString:[NSString stringWithFormat:@"%.0f", self.chartCanvas.frame.size.height+32]];
    
    s = [s stringByAppendingFormat:@"tooltip: {formatter: function() { return '<b>%@</b> '+ this.y.formatMoney(0, '.', ' ') +' %@';}},", self.expenseCategoryName, mainCurrency];
    s = [s stringByAppendingString:@"xAxis: { categories: ["];


    for (int i = 0; i != -6; i--) {
        
        components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
        [components setYear:[components year]+(([components month]+i)/12)];
        [components setMonth:([components month]+i)%12];
        [components setDay:1];
        
        [df setDateFormat:@"yyyyMM"];    
    entity = [NSEntityDescription entityForName:@"TrackedAmounts" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"note == '%@' AND dateOccurs MATCHES '%@.{2}'", self.expenseCategoryName, [df stringFromDate:[cal dateFromComponents:components]]]];
    [fetchRequest setPredicate:filter];
//    NSExpressionDescription* ed = [[NSExpressionDescription alloc] init];
//    NSExpression* exx = [NSExpression expressionWithFormat:@"@sum.amount"];
//    [ed setExpression:exx];
//    [ed setExpressionResultType:NSDecimalAttributeType];
//    [ed setName:@"summedamounts"];
//    [fetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"note", ed, nil]];
//    [fetchRequest setPropertiesToGroupBy:[NSArray arrayWithObject:@"note"]];
//    [fetchRequest setResultType:NSDictionaryResultType ];
    //    @try {
       [monthlySums addObject:[[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] valueForKeyPath:@"@sum.amount"]];
        
        [df setDateFormat:@"MMMM ’yy"];
        s = [s stringByAppendingFormat:@"'%@',", [NSString stringWithFormat:@"%@", [[df stringFromDate:[cal dateFromComponents:components]] capitalizedString]]];
    //    } @catch (NSException* e) {
    //        NSLog(@": eho? %@ %@", e, error);
    //    }
//    for(NSDictionary* t in d) {
//        NSLog(@": %@ %@", [t objectForKey:@"note"], [t objectForKey:@"summedamounts"]);
//    }
        if(i == 0) {
            NSDecimalNumber* dSpent = [monthlySums lastObject];
            double spent = fabs([dSpent doubleValue]);

            if(spent > budgeted) {
                if(budgeted == 0) {
                    self.amountSpentLabel.text = @"Spent";
                    self.amountSpentThisMonth.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[dSpent decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], mainCurrency];
                }
                else {
                    self.amountSpentLabel.text = @"Overspent";
                    self.amountSpentThisMonth.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[[dSpent decimalNumberBySubtracting:dBudgeted] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], mainCurrency];
                }
            }
            else {
                self.amountSpentLabel.text = @"Room to Spend";
                self.amountSpentThisMonth.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[dSpent decimalNumberBySubtracting:dBudgeted]], mainCurrency];
            }
            if(budgeted == 0) {
                self.amountBudgetedForCategory.text = @"";
                self.amountBudgetedLabel.text = @"Not Budgeted";
                [self.amountBudgetedLabel setTextColor:[UIColor colorWithRed:0xaa/255.f green:0/255.f blue:0/255.f alpha:1]];
                self.amountSpentLabel.text = @"Spent";
            }
            else {
                self.amountBudgetedLabel.text = @"Budgeted";
            }
            if(spent >= budgeted) {
                if(budgeted != 0) {
                    [self.amountSpentThisMonth setTextColor:[UIColor colorWithRed:0xaa/255.f green:0/255.f blue:0/255.f alpha:1]];
                }
            }
            else {
                [self.amountSpentThisMonth setTextColor:[UIColor colorWithRed:0/255.f green:0xaa/255.f blue:0/255.f alpha:1]];
            }
        }
    }
    

    
    
//    NSMutableArray* annual = [[NSMutableArray alloc] init];
    int i = 0;
        components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
        [components setYear:[components year]+(([components month]+i)/12)];
        [components setMonth:([components month]+i)%12];
        [components setDay:1];
        
        [df setDateFormat:@"yyyyMM"];
//        filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"note == 'Commute' AND dateOccurs MATCHES '%@'", [df stringFromDate:[cal dateFromComponents:components]]]];
//        [fetchRequest setPredicate:filter];
//        buf = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
//        savings += [[buf valueForKeyPath:@"@sum.amount"] doubleValue];
//        if(savings < lowest_savings) {
//            s = [s stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"min: %.2f", lowest_savings] withString:[NSString stringWithFormat:@"min: %.2f", savings]];
//            lowest_savings = savings;
//        }
//        [annual addObject:[NSNumber numberWithDouble:savings]];
        
//        [df setDateFormat:@"MMMM ’yy"];
//    }
    s = [s stringByAppendingFormat:@"],	}, series: [{name:'%@', data: [", self.expenseCategoryName];
    for (NSDecimalNumber* n in monthlySums) {
        s = [s stringByAppendingFormat:@"%.f,", fabs([n doubleValue])];
    }
    s = [s stringByAppendingString:@"] }] }); });</script></body>"];
//    NSLog(@"%f ...", lowest_savings);
    
    [self.chartCanvas loadHTMLString:s baseURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/chart", [[NSBundle mainBundle] bundlePath]]]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController popViewControllerAnimated:animated];
#ifndef DEBUG
//    [Flurry endTimedEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title}];
#endif
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [self setChartCanvas:nil];
    [self setAmountBudgetedForCategory:nil];
    [self setAmountSpentThisMonth:nil];
    [self setAmountSpentLabel:nil];
    [self setAmountBudgetedLabel:nil];
    [self setChartLoading:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.chartLoading startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.chartLoading stopAnimating];
}

@end
