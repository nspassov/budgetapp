//
//  BudgetSecondViewController.m
//  Budget
//
//  Created by Nikolay Spassov on 15.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BudgetSecondViewController.h"
#import "BudgetAppDelegate.h"
#import "Balance.h"
#import "CurrencyUtil.h"

@interface BudgetSecondViewController() {
    NSMutableArray *_objects;
    NSMutableArray* _others;
    NSMutableArray* _sections;
    NSString* _mainCurrency;
}
@end

@implementation BudgetSecondViewController

@synthesize table = _table;
@synthesize nav = _nav;
//@synthesize addButton = _addButton;
@synthesize managedObjectContext = _managedObjectContext;

//-(void) addAmount:(id)sender {
//    Amounts* amount = (Amounts*)[NSEntityDescription  insertNewObjectForEntityForName:@"Amounts" inManagedObjectContext:_managedObjectContext];
//   
//    [amount setCurrency:[[sender currency] text]];
//    [amount setAmount:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"-%@", [[sender amount] text]]]];
//    [amount setNote:[[sender note] text]];
//    [amount setDateOccurs:[[sender dateOccurs] text]];
//    
//    NSError *error = nil;
//    if (![_managedObjectContext save:&error]) {
//        NSLog(@"%@", error);
//    }
//    int section = [amount.dateOccurs isEqualToString:@""] ? 0 : 1;
//    [[_objects objectAtIndex:section] insertObject:amount atIndex:0];
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
//    [self.table insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//    [self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:YES];
//}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Balance *info = [[_objects objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

    NSString *CellIdentifier = @"Account Balance";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    UILabel* title = (UILabel*)[cell viewWithTag:1];
    title.text = [info name];
//
//    NSPredicate *f = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"note == '%@'", [info objectForKey:@"note"]]];
//    UIProgressView* subtitle = (UIProgressView*)[cell viewWithTag:2];
//    subtitle.progress = fabs([[info objectForKey:@"summedamounts"] doubleValue] / [[(Amounts*)[[_others filteredArrayUsingPredicate:f] lastObject] amount] doubleValue]);
//
    UITextField* detail = (UITextField*)[cell viewWithTag:2];
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    NSString * formattedAmount = [formatter stringFromNumber:[info balance]];
    detail.text = [NSString stringWithFormat:@"%@ %@", formattedAmount, [info currency]];
    
//    detail.text = [[NSString alloc] initWithFormat:@"(%.2f %@)", fabs([[info objectForKey:@"summedamounts"] doubleValue]), [(Amounts*)[[_others filteredArrayUsingPredicate:f] lastObject] currency]];
//    NSLog(@"%f", subtitle.progress);
//    [subtitle setProgressTintColor:[UIColor blueColor]];
//    if (subtitle.progress > .5) {
//        [subtitle setProgressTintColor:[UIColor orangeColor]];
//    }
//    if (subtitle.progress >= 1) {
//        [subtitle setProgressTintColor:[UIColor redColor]];
//    }
    return cell;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    UIToolbar* numpadToolbar = [[UIToolbar alloc] init];
    [numpadToolbar setBarStyle:UIBarStyleDefault];
    [numpadToolbar sizeToFit];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self.view action:@selector(endEditing:)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [numpadToolbar setItems:[NSArray arrayWithObjects:spacer, doneButton, nil]];
    textField.inputAccessoryView = numpadToolbar;
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSIndexPath* indexPath = [self.table indexPathForCell:(UITableViewCell*)[[textField superview] superview]];
    if(IS_GT_IOS71) {
        indexPath = [self.table indexPathForCell:(UITableViewCell*)[[textField superview] superview]];
    }
    Balance* a = (Balance*)[[_objects objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    
    textField.text = [formatter stringFromNumber:[a balance]];
    CGRect frame = [self.table frame];
    [self.table setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height-210)];
    [self.table scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSIndexPath* indexPath = [self.table indexPathForCell:(UITableViewCell*)[[textField superview] superview]];
    if(IS_GT_IOS71) {
        indexPath = [self.table indexPathForCell:(UITableViewCell*)[[textField superview] superview]];
    }
    Balance* a = (Balance*)[[_objects objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    
    [a setBalance:(NSDecimalNumber*)[formatter numberFromString:textField.text]];
    NSError *error = nil;
    if (![_managedObjectContext save:&error]) {
        NSLog(@"%@", error);
    }
    
    textField.text = [NSString stringWithFormat:@"%@ %@", textField.text, [a currency]];
    CGRect frame = [self.table frame];
    [self.table setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height+210)];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSMutableArray* numberStack = [NSMutableArray array];
    int diff = (string.length == 0) ? ((textField.text.length == 0) ? 0 : -1) : 1;
    const char* s = [[NSString stringWithFormat:@"%@%@", textField.text, string] UTF8String];
    int n = textField.text.length + diff;
    for (int i = 0; i != n; i++) {
        if ((int)s[i] > 47 && (int)s[i] < 58) {
            [numberStack insertObject:[NSString stringWithFormat:@"%c", s[i]] atIndex:0];
        }
    }
    double r = 0.00;
    double k = 0.01;
    int i = 0;
    for (i = 0, k = .01; i != [numberStack count]; i++, k *= 10) {
        r += ([[numberStack objectAtIndex:i] doubleValue] * k);
    }
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    textField.text = [formatter stringFromNumber:[NSNumber numberWithDouble:r]];
    
    return NO;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[_objects objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_objects count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [_sections objectAtIndex:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"";//[NSString stringWithFormat:@"Total %.2f %@", fabs([[[_objects objectAtIndex:0] valueForKeyPath:@"@sum.summedamounts"] doubleValue]),  _mainCurrency];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
//	if ([segue.identifier isEqualToString:@"Add Amount"]) {
//		UINavigationController *navigationController = segue.destinationViewController;
//		AddAmount *AddAmount = [[navigationController viewControllers] objectAtIndex:0];
//		AddAmount.delegate = self;
//        AddAmount.amountType = @"Expense";
//	}
}

//- (void)addAmountDidCancel:(AddAmount *)controller
//{
//	[self dismissViewControllerAnimated:YES completion:nil];
//}
//
//- (void)addAmountDidSave:(AddAmount *)controller
//{
////    [self addAmount:controller];
//	[self dismissViewControllerAnimated:YES completion:nil];
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Balance* todelete = [[_objects objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        [self.managedObjectContext deleteObject:todelete];
        NSError* error;
        if(![self.managedObjectContext save:&error]) {
            NSLog(@"%@", error);
        }
        [[_objects objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]  withRowAnimation:YES];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
//    NSLog(@": %@", [CurrencyUtil convertAmount:[NSDecimalNumber decimalNumberWithString:@"100"] ofCurrency:@"CAD" toCurrency:@"BGN"]);
//    [CurrencyUtil av];
//    NSLocale *lala = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale currentLocale] localeIdentifier]];
//    for( NSString* s in [NSLocale ISOCurrencyCodes]) {
//        NSLog(@"%@ %@", s, [lala displayNameForKey:NSLocaleCurrencyCode value:s]);
//    }
//    self.navigationItem.leftBarButtonItem = self.editButtonItem;
//    self.navigationItem.rightBarButtonItem = self.addButton;
//    [self.nav pushNavigationItem:self.navigationItem animated:YES];
    self.managedObjectContext = ((BudgetAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:[NSLocale currentLocale]];
    _mainCurrency = [formatter currencyCode];
    //    self.table.dataSource = self.managedObjectContext;
 	// Do any additional setup after loading the view, typically from a nib.
}

-(void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.table setEditing:editing animated:animated];
}

- (void)viewDidUnload
{
    [self setNav:nil];
//    [self setAddButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Balance" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    NSError *error;
    _objects = [NSMutableArray array];
//    NSPredicate *filter = [NSPredicate predicateWithFormat:@"amount <= 0"];
    //    [fetchRequest setPredicate:filter];
    [_objects  addObject:[[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy]];
    if (error) {
        NSLog(@"fdsfdsfdsfdsfdsdfs");// Handle the error.
    }
    
//    NSDateFormatter *df = [[NSDateFormatter alloc] init];
//    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
//    [df setDateFormat:@"yyyyMM"];
    
//    entity = [NSEntityDescription entityForName:@"TrackedAmounts" inManagedObjectContext:self.managedObjectContext];
//    [fetchRequest setEntity:entity];
//    filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount <= 0 AND dateOccurs MATCHES '%@.{2}'", [df stringFromDate:[cal dateFromComponents:components]]]];
//    [fetchRequest setPredicate:filter];
//    NSExpressionDescription* ed = [[NSExpressionDescription alloc] init];
//    NSExpression* exx = [NSExpression expressionWithFormat:@"@sum.amount"];
//    [ed setExpression:exx];
//    [ed setExpressionResultType:NSDecimalAttributeType];
//    [ed setName:@"summedamounts"];
//    [fetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"note", ed, nil]];
//    [fetchRequest setPropertiesToGroupBy:[NSArray arrayWithObject:@"note"]];
//    [fetchRequest setResultType:NSDictionaryResultType ];
    //    @try {
//    NSArray* d = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    //    } @catch (NSException* e) {
    //        NSLog(@": eho? %@ %@", e, error);
    //    }
//    for(NSDictionary* t in d) {
//        NSLog(@": %@ %@", [t objectForKey:@"note"], [t objectForKey:@"summedamounts"]);
//    }
//    [_objects insertObject:d atIndex:0];
//    NSLog(@"ob: %@", _objects);
//    
//    NSLog(@": %@", _others);
    //    for(NSString* s in _others) {
    //        entity = [NSEntityDescription entityForName:@"TrackedAmounts" inManagedObjectContext:self.managedObjectContext];
    //        [fetchRequest setEntity:entity];
    //        filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"note == '%@'", s]];
    //        [fetchRequest setPredicate:filter];
    //        NSLog(@"%@",[[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] valueForKeyPath:@"@sum.amount"]);
    //    }
    //    }
    //    @catch (NSException* e) {
    //        NSLog(@": %@", error);
    //    }
    //    _others = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy];
    //    NSLog(@": %@", _objects);
    if (error) {
        NSLog(@"fdsfdsfdsfdsfdsdfs");// Handle the error.
    }
    _sections = [NSMutableArray array];
    
//    [components setYear:[components year]];
//    [components setMonth:[components month]];
//    [components setDay:[components day]];
//    [df setDateFormat:@"MMMM ’yy"];
//    [_sections addObject:[df stringFromDate:[cal dateFromComponents:components]]];
    [_sections addObject:@""];
    
    [self.table reloadData];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    [super setEditing:NO animated:NO];
    [self.table setEditing:NO animated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
