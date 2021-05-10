//
//  AnnualReport.m
//  Budget
//
//  Created by Nikolay Spassov on 22.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "AnnualReport.h"
#import "BudgetAppDelegate.h"
#import "Amounts.h"
#import "Balance.h"
#import "TrackedAmounts.h"

@interface AnnualReport() {
    Balance* _savingsBalance;
    BOOL _expensesEnabled;
    NSMutableArray* _numberStack;
}

@end

@implementation AnnualReport
@synthesize nav = _nav;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize editSavingsButton = _editSavingsButton;
@synthesize chartCanvas = _chartCanvas;

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


- (void)updateChart
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMinimumFractionDigits:2];
    [formatter setLocale:[NSLocale currentLocale]];
    NSString* mainCurrency = [formatter currencyCode];
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if([lastState valueForKey:@"mainCurrency"]) {
        mainCurrency = [lastState valueForKey:@"mainCurrency"];
    }
    
    NSError *error;
    NSArray* buf;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    [df setDateFormat:@"yyyyMM"];
    
    double savings = 0;
    double lowest_savings = 0;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Balance" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    //    NSPredicate* filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"date < '%@'", [df stringFromDate:[cal dateFromComponents:components]]]];
    NSPredicate* filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"name == 'Savings'"]];
    [fetchRequest setPredicate:filter];
    buf = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if(error) {
        NSLog(@"%@", error);
    }
    if(buf.count == 1) {
        //        savings = [[buf valueForKeyPath:@"@sum.balance"] doubleValue];
        _savingsBalance = [buf lastObject];
        NSDecimalNumber* s = [[buf lastObject] valueForKey:@"balance"];
        self.navigationItem.title = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:s], mainCurrency];
        savings = [[[buf lastObject] valueForKey:@"balance"] doubleValue];

        if(![[lastState valueForKey:@"currMonth"] isEqualToString:[df stringFromDate:[cal dateFromComponents:components]]]) {
            if([lastState valueForKey:@"currMonth"]) {
                entity = [NSEntityDescription entityForName:@"Amounts" inManagedObjectContext:self.managedObjectContext];
                [fetchRequest setEntity:entity];
                filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount > 0 AND (dateOccurs == '' OR dateOccurs MATCHES '%@')", [lastState valueForKey:@"currMonth"]]];
                [fetchRequest setPredicate:filter];
                NSArray* buf1 = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
                [_savingsBalance setBalance:[[_savingsBalance balance] decimalNumberByAdding:[buf1 valueForKeyPath:@"@sum.amount"]]];
                if (![_managedObjectContext save:&error]) {
                    NSLog(@"%@", error);
                }
                savings = [[_savingsBalance balance] doubleValue];
            }

            [lastState setValue:[df stringFromDate:[cal dateFromComponents:components]] forKey:@"currMonth"];
        }
    }
    else {
        _savingsBalance = (Balance*)[NSEntityDescription insertNewObjectForEntityForName:@"Balance" inManagedObjectContext:_managedObjectContext];
        [_savingsBalance setBalance:[NSDecimalNumber zero]];
        [_savingsBalance setCurrency:mainCurrency];
        [_savingsBalance setName:[NSString stringWithFormat:@"Savings"]];
    }
    
    [(UITextField*)self.navigationItem.titleView setText:[NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:_savingsBalance.balance], mainCurrency]];
    
    entity = [NSEntityDescription entityForName:@"TrackedAmounts" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount < 0 AND year == %d AND month == %d", [components year], [components month]]];
    [fetchRequest setPredicate:filter];
    buf = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    const NSDecimalNumber* spent = [buf valueForKeyPath:@"@sum.amount"];
    
    [df setDateFormat:@"yyyyMM"];
    entity = [NSEntityDescription entityForName:@"Amounts" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(dateOccurs == '' OR dateOccurs MATCHES '%@') AND amount < 0", [df stringFromDate:[cal dateFromComponents:components]]]];
    [fetchRequest setPredicate:filter];
    buf = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    const NSDecimalNumber* planned = [buf valueForKeyPath:@"@sum.amount"];
    filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(dateOccurs == '' OR dateOccurs MATCHES '%@') AND amount > 0", [df stringFromDate:[cal dateFromComponents:components]]]];
    [fetchRequest setPredicate:filter];
    buf = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    const NSDecimalNumber* income = [buf valueForKeyPath:@"@sum.amount"];
//    NSLog(@"%.2f %@ %@ %@", savings, planned, spent, income);
    if([planned doubleValue] < [spent doubleValue]) {
        savings += (-[spent doubleValue] + [income doubleValue] + [planned doubleValue]);
    }
    else {
        savings += [income doubleValue];
//        filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(dateOccurs == '' OR dateOccurs MATCHES '%@') AND amount > 0", [df stringFromDate:[cal dateFromComponents:components]]]];
//        [fetchRequest setPredicate:filter];
//        buf = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
//        savings += [[buf valueForKeyPath:@"@sum.amount"] doubleValue];
    }
    
    //    NSLog(@"monthlybalances %@", buf);
    
    //    NSLog(@"%.2f ...", savings);
    
    //    entity = [NSEntityDescription entityForName:@"Amounts" inManagedObjectContext:self.managedObjectContext];
    //    [fetchRequest setEntity:entity];
    NSString* fpath = nil;
    if(_expensesEnabled) {
        fpath = [[NSBundle mainBundle] pathForResource:@"chart/annualexp" ofType: @"html"];
    }
    else {
        fpath = [[NSBundle mainBundle] pathForResource:@"chart/annual" ofType: @"html"];
    }
    NSString* s = [NSString stringWithContentsOfFile:fpath encoding:NSUTF8StringEncoding error:&error];
    s = [s stringByReplacingOccurrencesOfString:@"CUSTOM_HEIGHT" withString:[NSString stringWithFormat:@"%.0f", self.chartCanvas.frame.size.height+((_expensesEnabled)?18:18)]];
    
    s = [s stringByAppendingFormat:@"tooltip: {formatter: function() { return '<b>'+ this.series.name +'</b> '+ this.y.formatMoney(0, '.', ' ') +' %@';}},", mainCurrency];
    s = [s stringByAppendingString:@"xAxis: { categories: ["];
    NSMutableArray* annual = [[NSMutableArray alloc] init];
    NSMutableArray* plannedExpenses = [NSMutableArray array];
    for (int i = 0; i != 12; i++) {
        components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
        [components setYear:[components year]+(([components month]+i)/12)];
        [components setMonth:([components month]+i)%12];
        [components setDay:1];
        
        if(i != 0) {
            [df setDateFormat:@"yyyyMM"];
            filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"dateOccurs == '' OR dateOccurs MATCHES '%@'", [df stringFromDate:[cal dateFromComponents:components]]]];
            [fetchRequest setPredicate:filter];
            buf = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
            
            savings += [[buf valueForKeyPath:@"@sum.amount"] doubleValue];
        }
        NSDecimalNumber* exp = [[buf filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"amount < 0"]] valueForKeyPath:@"@sum.amount"];
        if(savings < lowest_savings) {
            s = [s stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"min: %.2f", lowest_savings] withString:[NSString stringWithFormat:@"min: %.2f", savings]];
            lowest_savings = savings;
        }
        if(_expensesEnabled) {
            if([exp doubleValue] < lowest_savings) {
                s = [s stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"min: %.2f", lowest_savings] withString:[NSString stringWithFormat:@"min: %.2f", [exp doubleValue]]];
                lowest_savings = [exp doubleValue];
            }
        }
        [plannedExpenses addObject:exp];
        [annual addObject:[NSNumber numberWithDouble:savings]];
        
        [df setDateFormat:@"MMM ’yy"];
        s = [s stringByAppendingFormat:@"'%@',", [[NSString stringWithFormat:@"%@", [df stringFromDate:[cal dateFromComponents:components]]] capitalizedString]];
    }
    s = [s stringByAppendingString:@"],	}, series: [{name:'Savings', data: ["];
    for (NSDecimalNumber* a in annual) {
        s = [s stringByAppendingFormat:@"%.f,", [a doubleValue]];
    }
    s = [s stringByAppendingString:@"] },"];

    if(_expensesEnabled) {
        s = [s stringByAppendingString:@"{name:'Expenses', data: ["];
        for (NSDecimalNumber* a in plannedExpenses) {
            s = [s stringByAppendingFormat:@"%.f,", [a doubleValue]];
        }
        s = [s stringByAppendingString:@"]}"];
    }

    s = [s stringByAppendingString:@"] }); });</script></body>"];
    //    NSLog(@"%f ...", lowest_savings);
    
    [self.chartCanvas loadHTMLString:s baseURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/chart", [[NSBundle mainBundle] bundlePath]]]];
}

- (IBAction)editSavings:(UIBarButtonItem *)sender {
    if([self.navigationItem.titleView isFirstResponder]) {
        [self.navigationItem.titleView resignFirstResponder];
        [self.editSavingsButton setStyle:UIBarButtonItemStyleBordered];
    }
    else {
        [self.navigationItem.titleView becomeFirstResponder];
        [self.editSavingsButton setStyle:UIBarButtonItemStyleDone];
    }
}

- (IBAction)switchExpenses:(id)sender {
    [self.navigationItem.titleView resignFirstResponder];
    [self.editSavingsButton setStyle:UIBarButtonItemStyleBordered];
    _expensesEnabled = !_expensesEnabled;
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    [lastState setBool:_expensesEnabled forKey:@"savingsExpensesToggle"];
    if(![lastState synchronize]) {
        NSLog(@"error");
    }
    [self updateChart];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#ifndef DEBUG
//    [Flurry logEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title} timed:YES];
#endif

    self.managedObjectContext = ((BudgetAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    self.navigationItem.leftBarButtonItem = self.editSavingsButton;

    // drop shadow
    self.navigationItem.titleView.layer.shadowOpacity = 1.0;
    self.navigationItem.titleView.layer.shadowRadius = 0.0;
    self.navigationItem.titleView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.navigationItem.titleView.layer.shadowOffset = CGSizeMake(0.0, -1.0);
    
    [self updateChart];
}

-(void) viewWillDisappear:(BOOL)animated {
#ifndef DEBUG
//    [Flurry endTimedEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title}];
#endif
    [super viewWillDisappear:animated];
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    _expensesEnabled = [lastState boolForKey:@"savingsExpensesToggle"];
}


- (void)viewDidUnload
{
    [self setChartCanvas:nil];
    [self setChartLoading:nil];
    [self setEditSavingsButton:nil];
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



- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    UIToolbar* numpadToolbar = [[UIToolbar alloc] init];
    [numpadToolbar setBarStyle:UIBarStyleDefault];
    [numpadToolbar sizeToFit];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(editSavings:)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [numpadToolbar setItems:[NSArray arrayWithObjects:spacer, doneButton, nil]];
    textField.inputAccessoryView = numpadToolbar;
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    Balance* a = _savingsBalance;
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    
    textField.text = [formatter stringFromNumber:[a balance]];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    Balance* a = _savingsBalance;
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    
    [a setBalance:(NSDecimalNumber*)[formatter numberFromString:textField.text]];
    NSError *error = nil;
    if (![_managedObjectContext save:&error]) {
        NSLog(@"%@", error);
    }
    
    textField.text = [NSString stringWithFormat:@"%@ %@", textField.text, [a currency]];
    [self updateChart];
    [_numberStack removeAllObjects];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(_numberStack == nil) {
        _numberStack = [NSMutableArray arrayWithObject:@"0"];
    }
    if(string.length == 0 && _numberStack.count != 0) {
        [_numberStack removeObjectAtIndex:0];
    }
    if(string.length == 1) {
        [_numberStack insertObject:string atIndex:0];
    }
    double r = 0.00;
    double k = 0.01;
    int i = 0;
    for(i = 0, k = .01; i != [_numberStack count]; i++, k *= 10) {
        r += ([[_numberStack objectAtIndex:i] doubleValue] * k);
    }
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    textField.text = [formatter stringFromNumber:[NSNumber numberWithDouble:r]];
    
    return NO;
}

@end
