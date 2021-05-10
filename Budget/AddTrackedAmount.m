//
//  AddTrackedAmount.m
//  Budget
//
//  Created by Nikolay Spassov on 30.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AddTrackedAmount.h"
#import "BudgetAppDelegate.h"
#import "Amounts.h"
#import "TrackedAmounts.h"
#import "Foursquare2.h"

@interface AddTrackedAmount() {
    NSMutableArray *_pickerData;
    NSMutableArray* _currencies;
    NSMutableArray* _numberStack;
    UITextField* _currentField;
    CLLocation* _bestEffortAtLocation;
}
@end

@implementation AddTrackedAmount

@synthesize note;
@synthesize amount;
@synthesize currency;
@synthesize dateOccurs;
@synthesize amountLabel;
@synthesize categoryLabel;
@synthesize delegate;

@synthesize nav;
@synthesize amountType;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize venueLabel;
@synthesize lat;
@synthesize lng;
@synthesize venueName;

- (IBAction)cancel:(id)sender
{
	[self.delegate addTrackedAmountDidCancel:self];
}
- (IBAction)done:(id)sender
{
    [self.delegate addTrackedAmountDidSave:self];
}

-(void) goToNextField {
    NSInteger nextTag = _currentField.tag + 1;
    UIResponder* nextResponder = [_currentField.superview viewWithTag:nextTag];
    if (nextResponder) {
        [nextResponder becomeFirstResponder];
    } else {
        [_currentField resignFirstResponder];
    }
}


- (void) loadCategoryAmounts {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMinimumFractionDigits:2];
    [formatter setLocale:[NSLocale currentLocale]];
    NSString* mainCurrency = [formatter currencyCode];
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if([lastState valueForKey:@"mainCurrency"]) {
        mainCurrency = [lastState valueForKey:@"mainCurrency"];
    }
    self.managedObjectContext = ((BudgetAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    NSError *error;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Amounts" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate* filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"note == '%@'", self.expenseCategory]];
    [fetchRequest setPredicate:filter];
    NSArray* buf = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSDecimalNumber* dBudgeted = [(Amounts*)[buf lastObject] amount];
    double budgeted = fabs([dBudgeted doubleValue]);
    self.budgetedAmount.text = [NSString stringWithFormat:@"(%@ %@)", [formatter stringFromNumber:[dBudgeted decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], [[buf lastObject] currency]];

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    [df setDateFormat:@"yyyyMM"];
    entity = [NSEntityDescription entityForName:@"TrackedAmounts" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"note == '%@' AND dateOccurs MATCHES '%@.{2}'", self.expenseCategory, [df stringFromDate:[cal dateFromComponents:components]]]];
    [fetchRequest setPredicate:filter];
    NSDecimalNumber* dSpent = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] valueForKeyPath:@"@sum.amount"];
    double spent = fabs([dSpent doubleValue]);
    if(spent > budgeted) {
        if(budgeted == 0) {
            self.budgetForCategoryLabel.text = @"Spent";
        }
        else {
            self.budgetForCategoryLabel.text = @"Overspent";
        }
        self.budgetForCategory.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[[dSpent decimalNumberBySubtracting:dBudgeted] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], mainCurrency];
    }
    else {
        self.budgetForCategoryLabel.text = @"Room to Spend";
        self.budgetForCategory.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[[dBudgeted decimalNumberBySubtracting:dSpent] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], mainCurrency];
    }
    if(budgeted == 0) {
        self.budgetedAmount.text = @"";
        self.budgetForCategoryLabel.text = @"Spent";
    }
    if(spent >= budgeted) {
        if(budgeted != 0) {
            [self.budgetForCategory setTextColor:[UIColor colorWithRed:0xaa/255.f green:0/255.f blue:0/255.f alpha:1]];
        }
    }
    else {
        [self.budgetForCategory setTextColor:[UIColor colorWithRed:0/255.f green:0xaa/255.f blue:0/255.f alpha:1]];
    }
    
    [self.budgetedAmount setHidden:NO];
    [self.note setBorderStyle:UITextBorderStyleNone];
    [self.budgetForCategoryLabel setHidden:NO];
    [self.budgetForCategory setHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
#ifndef DEBUG
//    [Flurry endTimedEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title}];
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:self.view.window];

    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#ifndef DEBUG
//    [Flurry logEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title} timed:YES];
#endif

    self.nav.title = [NSString stringWithFormat:@"New %@", self.amountType];
    self.amountLabel.text = @"Amount Spent";
//    self.categoryLabel.text = @"Expense Category";
    self.note.text = self.expenseCategory;
    
    _locationManager = [[CLLocationManager alloc]init];
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.delegate = self;
    [_locationManager startUpdatingLocation];
    
    if (self.expenseCategory) {
        [self loadCategoryAmounts];
    }

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:[NSLocale currentLocale]];
    self.currency.text = [formatter currencyCode];
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if([lastState valueForKey:@"mainCurrency"]) {
        self.currency.text = [lastState valueForKey:@"mainCurrency"];
    }

    UIPickerView* categoryPicker = [[UIPickerView alloc] init];
    categoryPicker.dataSource = self;
    categoryPicker.delegate = self;
    categoryPicker.showsSelectionIndicator = YES;
    self.note.inputView = categoryPicker;
    
    UIPickerView* currencyPicker = [[UIPickerView alloc] init];
    currencyPicker.dataSource = self;
    currencyPicker.delegate = self;
    currencyPicker.showsSelectionIndicator = YES;
    self.currency.inputView = currencyPicker;

    UIToolbar* formNavigationView = [[UIToolbar alloc] init];
    [formNavigationView setBarStyle:UIBarStyleBlackTranslucent];
    [formNavigationView setTintColor:[UIColor colorWithRed:0xbd/255.f green:0x55/255.f blue:0x00/255.f alpha:1]];
    [formNavigationView sizeToFit];
    UIBarButtonItem* nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(goToNextField)];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    if (self.expenseCategory) {
        [formNavigationView setItems:[NSArray arrayWithObjects:spacer, doneButton, nil]];
    }
    else {
        [formNavigationView setItems:[NSArray arrayWithObjects:nextButton, spacer, doneButton, nil]];
    }
    self.amount.keyboardAppearance = UIKeyboardAppearanceAlert;
    self.note.inputAccessoryView = formNavigationView;
    self.amount.inputAccessoryView = formNavigationView;
    self.currency.inputAccessoryView = formNavigationView;
    
    self.managedObjectContext = ((BudgetAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Amounts" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate *filter;
    NSError *error;
    
    filter = [NSPredicate predicateWithFormat:@"amount <= 0"];
    [fetchRequest setPredicate:filter];
    NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey:@"note" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    _pickerData = [NSMutableArray arrayWithObject:@""];
    [_pickerData addObjectsFromArray:[[[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy] valueForKey:@"note"]];

    if([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized
       && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined) {
        [self.venueLabel setText:@""];
        [[self.view viewWithTag:100] setHidden:YES];
    }
}

- (void)getVenuesForLocation:(CLLocation*)location
{
    [Foursquare2 searchVenuesNearByLatitude:@(location.coordinate.latitude)
								  longitude:@(location.coordinate.longitude)
								 accuracyLL:nil
								   altitude:@(location.altitude)
								accuracyAlt:nil
									  query:nil
									  limit:@1
									 intent:intentCheckin
                                     radius:nil
								   callback:^(BOOL success, id result) {
									   if(success) {
										   NSDictionary *dic = result;
										   NSArray* venues = [dic valueForKeyPath:@"response.venues"];
//                                           NSLog(@"%@", venues);
                                           if(venues.count > 0) {
                                               [self.venueLabel setText:[venues objectAtIndex:0][@"name"]];
                                               [self setVenueName:[venues objectAtIndex:0][@"name"]];
                                               self.lat = [venues objectAtIndex:0][@"location"][@"lat"];
                                               self.lng = [venues objectAtIndex:0][@"location"][@"lng"];
                                           }
                                           else {
                                               [self.venueLabel setText:@"(unknown venue)"];
                                           }
//                                           FSConverter *converter = [[FSConverter alloc]init];
//                                           self.nearbyVenues = [converter convertToObjects:venues];
//                                           [self proccessAnnotations];
//                                           [self.tableView reloadData];
									   }
								   }];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    
    if (locationAge > 5.0) return;
    
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;
    
    // test the measurement to see if it is more accurate than the previous measurement
    if (_bestEffortAtLocation == nil || _bestEffortAtLocation.horizontalAccuracy > newLocation.horizontalAccuracy) {
        // store the location as the "best effort"
        _bestEffortAtLocation = newLocation;
        
        // test the measurement to see if it meets the desired accuracy
        //
        // IMPORTANT!!! kCLLocationAccuracyBest should not be used for comparison with location coordinate or altitidue
        // accuracy because it is a negative value. Instead, compare against some predetermined "real" measure of
        // acceptable accuracy, or depend on the timeout to stop updating. This sample depends on the timeout.
        //
//        if (newLocation.horizontalAccuracy <= manager.desiredAccuracy) {
            // we have a measurement that meets our requirements, so we can stop updating the location
            //
            // IMPORTANT!!! Minimize power usage by stopping the location manager as soon as possible.
            //
            [_locationManager stopUpdatingLocation];
            
            // we can also cancel our previous performSelector:withObject:afterDelay: - it's no longer necessary
//            [NSObject cancelPreviousPerformRequestsWithTarget:_locationManager selector:@selector(stopUpdatingLocation:) object:nil];

        [self setLat:(NSDecimalNumber*)[NSNumber numberWithDouble:_bestEffortAtLocation.coordinate.latitude]];
        [self setLng:(NSDecimalNumber*)[NSNumber numberWithDouble:_bestEffortAtLocation.coordinate.longitude]];
            [self getVenuesForLocation:_bestEffortAtLocation];
//        }
    }
}

//- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
//{
//    NSLog(@"%@", locations);
//    [manager stopUpdatingLocation];
//}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if([pickerView isEqual:self.note.inputView]) {
        self.note.text = [_pickerData objectAtIndex:row];
    }
    if([pickerView isEqual:self.currency.inputView]) {
        self.currency.text = [[_currencies objectAtIndex:row] valueForKey:@"code"];
        NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
        [lastState setObject:[[_currencies objectAtIndex:row] valueForKey:@"code"] forKey:@"mainCurrency"];
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if([pickerView isEqual:self.note.inputView]) {
        return [_pickerData objectAtIndex:row];
    }
    if([pickerView isEqual:self.currency.inputView]) {
        return [[_currencies objectAtIndex:row] valueForKey:@"name"];
    }
    return @"";
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if([pickerView isEqual:self.note.inputView]) {
        return _pickerData.count;
    }
    if([pickerView isEqual:self.currency.inputView]) {
        return _currencies.count;
    }
    return 0;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}


-(void)textFieldDidBeginEditing:(UITextField *)textField{
    _currentField = textField;
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
    formatter.currencyCode = self.currency.text;
    NSString * formattedAmount = [formatter stringFromNumber: [NSNumber numberWithDouble:r]];
    textField.text = formattedAmount;
    if(r == 0) {
        [self.keypad00button setTitle:@"" forState:UIControlStateNormal];
    }
    else {
        [self.keypad00button setTitle:[formatter stringFromNumber:[NSNumber numberWithDouble:r*100]] forState:UIControlStateNormal];
    }
    
    return NO;
}


-(void) viewDidLoad {
    [super viewDidLoad];
    [[self.view viewWithTag:1] becomeFirstResponder];
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    self.amount.text = [formatter stringFromNumber:[NSNumber numberWithDouble:0]];
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0xbd/255.f green:0x55/255.f blue:0x00/255.f alpha:1]];

    _currencies = [NSMutableArray array];
    for(NSString* lc in [NSLocale ISOCurrencyCodes]) {
        NSLocale* loc = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale currentLocale] localeIdentifier]];
        NSString* s = [loc displayNameForKey:NSLocaleCurrencyCode value:lc];
        if(s != nil) {
            NSMutableDictionary* item = [NSMutableDictionary dictionary];
            [item setObject:lc forKey:@"code"];
            [item setObject:s forKey:@"name"];
            [_currencies addObject:item];
        }
    }
    _currencies = [[_currencies sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b) {
        return [[a valueForKey:@"name"] compare:[b valueForKey:@"name"]];
    }] mutableCopy];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:self.view.window];
}

- (void)viewDidUnload {
    [self setNote:nil];
    [self setAmount:nil];
    [self setCurrency:nil];
    [self setAmountLabel:nil];
    [self setNav:nil];
//    [self setDateOccurs:nil];
    [self setCategoryLabel:nil];
    [self setBudgetForCategoryLabel:nil];
    [self setBudgetForCategory:nil];
    [self setBudgetedAmount:nil];
    [super viewDidUnload];
}

- (void)keyboardDidShow:(NSNotification*)notification
{
    if([self.amount isFirstResponder]) {
        [self add00buttonToKeypad];
    }
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    [self.keypad00button removeFromSuperview];
}

- (void)add00buttonToKeypad
{
    self.keypad00button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.keypad00button setFrame:CGRectMake(0, 207, 106, 53)];
    [self.keypad00button setTitle:@"" forState:UIControlStateNormal];
    [self.keypad00button.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:26]];
    [self.keypad00button.titleLabel setAdjustsFontSizeToFitWidth:YES];
    [self.keypad00button addTarget:self action:@selector(roundAmount:) forControlEvents:UIControlEventTouchUpInside];
//    self.keypad00button.adjustsImageWhenHighlighted = NO;
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.0) {
//        [self.keypad00button setImage:[UIImage imageNamed:NSLocalizedString(@"Comma", @"")] forState:UIControlStateNormal];
//        [self.keypad00button setImage:[UIImage imageNamed:NSLocalizedString(@"Comma_Pressed", @"")] forState:UIControlStateHighlighted];
//    } else {
//        [self.keypad00button setImage:[UIImage imageNamed:NSLocalizedString(@"Comma", @"")] forState:UIControlStateNormal];
//        [self.keypad00button setImage:[UIImage imageNamed:NSLocalizedString(@"Comma_Pressed", @"")] forState:UIControlStateHighlighted];
//    }
    // locate keyboard view
    UIWindow* tempWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:1];
    UIView* keyboard;
    for(int i=0; i<[tempWindow.subviews count]; i++) {
        keyboard = [tempWindow.subviews objectAtIndex:i];
        // keyboard found, add the button
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2) {
            if([[keyboard description] hasPrefix:@"<UIPeripheralHost"] == YES)
                [keyboard addSubview:self.keypad00button];
        }
//        else {
//            if([[keyboard description] hasPrefix:@"<UIKeyboard"] == YES)
//                [keyboard addSubview:self.keypad00button];
//        }
    }
}

-(void)roundAmount:(id)sender
{
    [self textField:self.amount shouldChangeCharactersInRange:NSMakeRange(self.amount.text.length, 0) replacementString:@"0"];
    [self textField:self.amount shouldChangeCharactersInRange:NSMakeRange(self.amount.text.length, 1) replacementString:@"0"];
    if(self.keypad00button.titleLabel.text) {
        [self done:self.keypad00button];
    }
}

@end
