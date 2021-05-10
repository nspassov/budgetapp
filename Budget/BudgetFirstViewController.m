//
//  BudgetFirstViewController.m
//  Budget
//
//  Created by Nikolay Spassov on 15.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BudgetFirstViewController.h"
#import "BudgetAppDelegate.h"
#import "Amounts.h"
#import "MonthlyBalances.h"

#define INCOME 0
#define EXPENSES 1
#define TAG_DATE 4
#define TAG_AMOUNT 2

@interface BudgetFirstViewController() <AddAmountDelegate> {
    NSMutableArray *_objects;
    UIPickerView* _datePicker;
    NSMutableArray *_pickerData;
    UITextField* _textFieldBeingEdited;
    NSMutableDictionary* _tooltips;
    UITextField* _activeField;
    NSMutableArray* _numberStack;
}
@end

@implementation BudgetFirstViewController

@synthesize table = _table;
@synthesize nav = _nav;
@synthesize addButton = _addButton;
@synthesize incomeExpensesToggle = _incomeExpensesToggle;
@synthesize managedObjectContext = _managedObjectContext;


- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView
{
    
}

-(void) recalculateMonthlyBalance {
//    NSError* error;
//    
//    NSDateFormatter *df = [[NSDateFormatter alloc] init];
//    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
//    [df setDateFormat:@"yyyyMM"];
//    
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TrackedAmounts" inManagedObjectContext:_managedObjectContext];
//    [fetchRequest setEntity:entity];
//    NSPredicate *filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"dateOccurs MATCHES '%@.{0,2}'", [df stringFromDate:[cal dateFromComponents:components]]]];
//    [fetchRequest setPredicate:filter];
//    double monthlyexpenses = [[[_managedObjectContext executeFetchRequest:fetchRequest error:&error] valueForKeyPath:@"@sum.amount"] doubleValue];
//    
//    entity = [NSEntityDescription entityForName:@"Amounts" inManagedObjectContext:_managedObjectContext];
//    [fetchRequest setEntity:entity];
//    filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount > 0 AND (dateOccurs == '' OR dateOccurs MATCHES '%@.{0,2}')", [df stringFromDate:[cal dateFromComponents:components]]]];
//    [fetchRequest setPredicate:filter];
//    double monthlyincome = [[[_managedObjectContext executeFetchRequest:fetchRequest error:&error] valueForKeyPath:@"@sum.amount"] doubleValue];
//    fetchRequest = [[NSFetchRequest alloc] init];
//    entity = [NSEntityDescription entityForName:@"MonthlyBalances" inManagedObjectContext:_managedObjectContext];
//    [fetchRequest setEntity:entity];
//    filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"date == '%@'", [df stringFromDate:[cal dateFromComponents:components]]]];
//    [fetchRequest setPredicate:filter];
//    NSArray* buf = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
//    if(buf.count == 1) {
//        [[buf objectAtIndex:0] setValue:[NSDecimalNumber numberWithDouble:(monthlyincome-monthlyexpenses)] forKey:@"balance"];
//    }
//    if(buf.count == 0) {
//        MonthlyBalances* b = (MonthlyBalances*)[NSEntityDescription insertNewObjectForEntityForName:@"MonthlyBalances" inManagedObjectContext:_managedObjectContext];
//        [b setDate:[df stringFromDate:[cal dateFromComponents:components]]];
//        [b setBalance:(NSDecimalNumber*)[NSDecimalNumber numberWithDouble:(monthlyincome+monthlyexpenses)]];
//        if (![_managedObjectContext save:&error]) {
//            NSLog(@"%@", error);
//        }
//    }
//    NSLog(@"%.2f ...", monthlyincome+monthlyexpenses);
}

-(void) determineColor {
    if(self.incomeExpensesToggle.selectedSegmentIndex == INCOME) {
        [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0x00/255.f green:0xaa/255.f blue:0x00/255.f alpha:1]];
    }
    if(self.incomeExpensesToggle.selectedSegmentIndex == EXPENSES) {
        [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0xaa/255.f green:0x00/255.f blue:0x00/255.f alpha:1]];
    }
}

-(void) showPlannedAmounts {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Amounts" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey:@"note" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    NSError *error;
    _objects = [NSMutableArray array];
    NSPredicate *filter;
    if([self.incomeExpensesToggle selectedSegmentIndex] == INCOME) {
        filter = [NSPredicate predicateWithFormat:@"amount > 0 AND dateOccurs = ''"];
    }
    if([self.incomeExpensesToggle selectedSegmentIndex] == EXPENSES) {
        filter = [NSPredicate predicateWithFormat:@"amount <= 0 AND dateOccurs = ''"];
    }
    [fetchRequest setPredicate:filter];
    if (error) {
        NSLog(@"fdsfdsfdsfdsfdsdfs");// Handle the error.
    }
    [_objects addObject:[[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy]];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    [df setDateFormat:@"yyyyMM"];
    
    sort = [[NSSortDescriptor alloc] initWithKey:@"dateOccurs" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    if([self.incomeExpensesToggle selectedSegmentIndex] == INCOME) {
        filter = [NSPredicate predicateWithFormat:@"amount > 0 AND dateOccurs <> '' AND dateOccurs >= '%@'", [df stringFromDate:[cal dateFromComponents:components]]];
    }
    if([self.incomeExpensesToggle selectedSegmentIndex] == EXPENSES) {
        filter = [NSPredicate predicateWithFormat:@"amount <= 0 AND dateOccurs <> '' AND dateOccurs >= '%@'", [df stringFromDate:[cal dateFromComponents:components]]];
    }
    [fetchRequest setPredicate:filter];
    if (error) {
        NSLog(@"fdsfdsfdsfdsfdsdfs");// Handle the error.
    }
    [_objects addObject:[[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy]];
    [self.table reloadData];

}


-(void) addAmount:(id)sender {
    Amounts* amount = (Amounts*)[NSEntityDescription insertNewObjectForEntityForName:@"Amounts" inManagedObjectContext:_managedObjectContext];

    [amount setCurrency:[[sender currency] text]];
    if([self.incomeExpensesToggle selectedSegmentIndex] == INCOME) {
        NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        [formatter setMinimumFractionDigits:2];
        NSDecimalNumber* income = (NSDecimalNumber*)[formatter numberFromString:[[sender amount] text]];
        if([income isEqualToNumber:@0]) {
            income = (NSDecimalNumber*)@.01;
        }
        [amount setAmount:income];
    }
    if([self.incomeExpensesToggle selectedSegmentIndex] == EXPENSES) {
        NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        [formatter setMinimumFractionDigits:2];
        [amount setAmount:(NSDecimalNumber*)[formatter numberFromString:[NSString stringWithFormat:@"-%@", [[sender amount] text]]]];
    }
    [amount setNote:[[[sender note] text] stringByReplacingOccurrencesOfString:@"'" withString:@""]];
    [amount setDateOccurs:[[sender dateOccurs] text]];
    
    NSError* error;

    if (![_managedObjectContext save:&error]) {
        NSLog(@"%@", error);
    }

    [self recalculateMonthlyBalance];
    
    int section = [amount.dateOccurs isEqualToString:@""] ? 0 : 1;
    [[_objects objectAtIndex:section] insertObject:amount atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    [self.table insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    Amounts *info = [[_objects objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

    NSString *CellIdentifier;
    if([self.incomeExpensesToggle selectedSegmentIndex] == INCOME) {
        CellIdentifier = @"Editable Income Amount";
        if(![info.dateOccurs isEqualToString:@""]) {
            CellIdentifier = @"Editable Expected Income Amount";
        }
    }
    if([self.incomeExpensesToggle selectedSegmentIndex] == EXPENSES) {
        CellIdentifier = @"Editable Expense Amount";
        if(![info.dateOccurs isEqualToString:@""]) {
            CellIdentifier = @"Editable Planned Expense Amount";
        }
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];

    if(![info.dateOccurs isEqualToString:@""]) {
        UILabel* title = (UILabel*)[cell viewWithTag:1];
        title.text = info.note;
        
        NSDateFormatter* df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyyMM"];
        NSDate* d = [df dateFromString:info.dateOccurs];
        [df setDateFormat:@"MMMM ’yy"];
        UILabel* subtitle = (UILabel*)[cell viewWithTag:3];
        subtitle.text = [[df stringFromDate:d] capitalizedString];
        UITextField* date = (UITextField*)[cell viewWithTag:4];
        date.text = [[df stringFromDate:d] capitalizedString];
        
        UITextField* detail = (UITextField*)[cell viewWithTag:2];
        if([self.incomeExpensesToggle selectedSegmentIndex] == INCOME) {
            detail.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:info.amount], info.currency];
        }
        if([self.incomeExpensesToggle selectedSegmentIndex] == EXPENSES) {
            detail.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:info.amount], info.currency];
            if([info.amount doubleValue] == 0) {
                [detail setTextColor:[UIColor colorWithRed:0xaa/255.f green:0xaa/255.f blue:0xaa/255.f alpha:1]];
            }
            else {
                [detail setTextColor:[UIColor colorWithRed:0x66/255.f green:0x00/255.f blue:0x00/255.f alpha:1]];
            }
        }
    }
    else {
        UILabel* title = (UILabel*)[cell viewWithTag:1];
        title.text = info.note;
        UITextField* detailTextLabel = (UITextField*)[cell viewWithTag:2];
        if([self.incomeExpensesToggle selectedSegmentIndex] == INCOME) {
            detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:info.amount], info.currency];
        }
        if([self.incomeExpensesToggle selectedSegmentIndex] == EXPENSES) {
            detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:info.amount], info.currency];
            if([info.amount doubleValue] == 0) {
                [detailTextLabel setTextColor:[UIColor colorWithRed:0xaa/255.f green:0xaa/255.f blue:0xaa/255.f alpha:1]];
            }
            else {
                [detailTextLabel setTextColor:[UIColor colorWithRed:0x66/255.f green:0x00/255.f blue:0x00/255.f alpha:1]];
            }
        }
    }
    return cell;
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
    NSArray* sections = [NSArray arrayWithObjects:[NSArray arrayWithObjects:@"Regular Income", @"Additional Income", nil], [NSArray arrayWithObjects:@"Recurring Expenses", @"Other Expenses", nil], nil];
	return [[sections objectAtIndex:[self.incomeExpensesToggle selectedSegmentIndex]] objectAtIndex:section];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [_activeField resignFirstResponder];
	if ([segue.identifier isEqualToString:@"Add Amount"]) {
		UINavigationController *navigationController = segue.destinationViewController;
		AddAmount *AddAmount = [[navigationController viewControllers] objectAtIndex:0];
		AddAmount.delegate = self;
        if([self.incomeExpensesToggle selectedSegmentIndex] == INCOME) {
            AddAmount.amountType = @"Income";
        }
        if([self.incomeExpensesToggle selectedSegmentIndex] == EXPENSES) {
            AddAmount.amountType = @"Expense";
        }
	}
}

- (void)addAmountDidCancel:(AddAmount *)controller
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addAmountDidSave:(AddAmount *)controller
{
    [self addAmount:controller];
	[self dismissViewControllerAnimated:YES completion:nil];
}

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
        [_activeField resignFirstResponder];
        Amounts* todelete = [[_objects objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        [self.managedObjectContext deleteObject:todelete];
        NSError* error;
        if(![self.managedObjectContext save:&error]) {
            NSLog(@"%@", error);
        }

        [self recalculateMonthlyBalance];

        [[_objects objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]  withRowAnimation:YES];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (IBAction)segmentedControlValueChanged:(id)sender {
    [_activeField resignFirstResponder];
    [self determineColor];
    [self showPlannedAmounts];
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    [lastState setInteger:[self.incomeExpensesToggle selectedSegmentIndex] forKey:@"plannertogglestate"];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = self.addButton;
    [self.nav pushNavigationItem:self.navigationItem animated:YES];
    self.navigationItem.titleView = self.incomeExpensesToggle;
    self.managedObjectContext = ((BudgetAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;

    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if([lastState objectForKey:@"plannertogglestate"]) {
        [self.incomeExpensesToggle setSelectedSegmentIndex:[[lastState objectForKey:@"plannertogglestate"] integerValue]];
    }
    [self determineColor];
    [self showPlannedAmounts];

    _tooltips = [NSMutableDictionary dictionary];
	// Do any additional setup after loading the view, typically from a nib.
}



-(void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [_activeField resignFirstResponder];
    [super setEditing:editing animated:animated];
    [self.table setEditing:editing animated:animated];
}

- (void)viewDidUnload
{
    [self setNav:nil];
    [self setAddButton:nil];
    [self setIncomeExpensesToggle:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#ifndef DEBUG
//    [Flurry logEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title} timed:YES];
#endif

    _datePicker = [[UIPickerView alloc] init];
    _datePicker.dataSource = self;
    _datePicker.delegate = self;
    _datePicker.showsSelectionIndicator = YES;
    _pickerData = [NSMutableArray arrayWithObject:[NSDate date]];
    
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    for (int i = 0; i != 12; i++) {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
        [components setYear:[components year]+(([components month]+i)/12)];
        [components setMonth:([components month]+i)%12];
        [components setDay:1];
        [_pickerData addObject:[cal dateFromComponents:components]];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    
    if(![lastState objectForKey:@"tooltipAmountEditPossible"]) {
        CMPopTipView* tip1 = [[CMPopTipView alloc] initWithMessage:@"Tap to edit amount"];
        tip1.delegate = self;
        tip1.backgroundColor = [UIColor blackColor];
        tip1.textColor = [UIColor whiteColor];
        [tip1 setDismissTapAnywhere:YES];
        [tip1 presentPointingAtView:[[self.table cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] viewWithTag:2] inView:self.table animated:YES];
        [_tooltips setObject:tip1 forKey:@"tooltipAmountEditPossible"];
        [lastState setInteger:1 forKey:@"tooltipAmountEditPossible"];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[_tooltips valueForKey:@"tooltipAmountEditPossible"] dismissAnimated:YES];

#ifndef DEBUG
//    [Flurry endTimedEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title}];
#endif
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


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
        if(row == 0) {
            _textFieldBeingEdited.text = @"";
        }
        else {
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyyMM"];
            _textFieldBeingEdited.text = [df stringFromDate:[_pickerData objectAtIndex:row]];
        }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
        if(row == 0) {
            return @"(every month)";
        }
        else {
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"MMMM ’yy"];
            return [[df stringFromDate:[_pickerData objectAtIndex:row]] capitalizedString];
        }

    return @"";
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if([pickerView isEqual:_textFieldBeingEdited.inputView]) {
        return _pickerData.count;
    }
    return 0;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
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
 
    if(textField.tag == TAG_DATE) {
        textField.inputView = _datePicker;
    }
    _textFieldBeingEdited = textField;
    _activeField = textField;
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSIndexPath* indexPath = [self.table indexPathForCell:(UITableViewCell*)[[[textField superview] superview] superview]];
    if(IS_GT_IOS71) {
        indexPath = [self.table indexPathForCell:(UITableViewCell*)[[textField superview] superview]];
    }
    Amounts* a = (Amounts*)[[_objects objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];

    if(textField.tag == TAG_AMOUNT) {
        if(self.incomeExpensesToggle.selectedSegmentIndex == INCOME) {
            textField.text = [formatter stringFromNumber:[a amount]];
        }
        if(self.incomeExpensesToggle.selectedSegmentIndex == EXPENSES) {
            textField.text = [formatter stringFromNumber:[a amount]];
        }
    }
    if(textField.tag == TAG_DATE) {
        textField.text = a.dateOccurs;
    }

    CGRect frame = [self.table frame];
    [self.table setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height-210)];
    [self.table scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSIndexPath* indexPath = [self.table indexPathForCell:(UITableViewCell*)[[[textField superview] superview] superview]];
    if(IS_GT_IOS71) {
        indexPath = [self.table indexPathForCell:(UITableViewCell*)[[textField superview] superview]];
    }
    Amounts* a = (Amounts*)[[_objects objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];

    if(textField.tag == TAG_AMOUNT) {
        if(self.incomeExpensesToggle.selectedSegmentIndex == INCOME) {
            NSDecimalNumber* i = (NSDecimalNumber*)[formatter numberFromString:textField.text];
            i = ([i isEqualToNumber:@0]) ? (NSDecimalNumber*)@.01 : i;
            [a setAmount:i];
            textField.text = [NSString stringWithFormat:@"%@ %@", textField.text, [a currency]];
        }
        if(self.incomeExpensesToggle.selectedSegmentIndex == EXPENSES) {
            [a setAmount:(NSDecimalNumber*)[formatter numberFromString:textField.text]];
            textField.text = [NSString stringWithFormat:@"%@ %@", textField.text, [a currency]];
        }
    }
    if(textField.tag == TAG_DATE) {
        [a setDateOccurs:textField.text];
        if(![textField.text isEqualToString:@""]) {
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyyMM"];
            NSDate* d = [df dateFromString:textField.text];
            [df setDateFormat:@"MMMM ’yy"];
            textField.text = [df stringFromDate:d];
        }
        else {
            [self showPlannedAmounts];
        }
    }
    NSError *error = nil;
    if (![_managedObjectContext save:&error]) {
        NSLog(@"%@", error);
    }

    CGRect frame = [self.table frame];
    [self.table setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height+210)];
    [_numberStack removeAllObjects];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(textField.tag == TAG_DATE) {
        return YES;
    }
    if(textField.tag == TAG_AMOUNT) {
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
        if(self.incomeExpensesToggle.selectedSegmentIndex == INCOME) {
            textField.text = [formatter stringFromNumber:[NSNumber numberWithDouble:r]];
        }
        if(self.incomeExpensesToggle.selectedSegmentIndex == EXPENSES) {
            if(r == 0) {
                [textField setTextColor:[UIColor colorWithRed:0xaa/255.f green:0xaa/255.f blue:0xaa/255.f alpha:1]];
                [textField setText:[NSString stringWithFormat:@"%@", [formatter stringFromNumber:[NSNumber numberWithDouble:r]] ]];
            }
            else {
                [textField setText:[NSString stringWithFormat:@"-%@", [formatter stringFromNumber:[NSNumber numberWithDouble:r]] ]];
                [textField setTextColor:[UIColor colorWithRed:0x66/255.f green:0x00/255.f blue:0x00/255.f alpha:1]];
            }
        }
        
        return NO;
    }
    return YES;
}

@end
