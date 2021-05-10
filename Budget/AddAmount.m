//
//  AddAmount.m
//  Budget
//
//  Created by Nikolay Spassov on 15.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AddAmount.h"

@interface AddAmount() {
    NSMutableArray *_pickerData;
    NSMutableArray* _numberStack;
    NSMutableArray* _currencies;
    UITextField* _currentField;
}
@end

@implementation AddAmount

@synthesize note;
@synthesize amount;
@synthesize currency;
@synthesize dateOccurs;
@synthesize amountLabel;
@synthesize delegate;

@synthesize nav;
@synthesize amountType;

- (IBAction)cancel:(id)sender
{
	[self.delegate addAmountDidCancel:self];
}
- (IBAction)done:(id)sender
{
    [self.delegate addAmountDidSave:self];
}

-(void) goToNextField {
    NSInteger nextTag = _currentField.tag + 1;
    UIResponder* nextResponder = [_currentField.superview viewWithTag:nextTag];
    if (nextResponder) {
        [nextResponder becomeFirstResponder];
    } else {
        [[_currentField.superview viewWithTag:1] becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
#ifndef DEBUG
//    [Flurry endTimedEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title}];
#endif
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#ifndef DEBUG
//    [Flurry logEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title} timed:YES];
#endif

    self.nav.title = [NSString stringWithFormat:@"Add %@", self.amountType];
    self.amountLabel.text = [self.amountType isEqualToString:@"Income"] ? @"Income Amount" : @"Amount Budgeted";
    self.typeLabel.text = [self.amountType isEqualToString:@"Income"] ? @"Income Type / Name" : @"Expense Category Name" ;

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:[NSLocale currentLocale]];
    self.currency.text = [formatter currencyCode];
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if([lastState valueForKey:@"mainCurrency"]) {
        self.currency.text = [lastState valueForKey:@"mainCurrency"];
    }
    
    UIPickerView* datePicker = [[UIPickerView alloc] init];
    datePicker.dataSource = self;
    datePicker.delegate = self;
    datePicker.showsSelectionIndicator = YES;
    self.dateOccurs.inputView = datePicker;
    
    UIPickerView* currencyPicker = [[UIPickerView alloc] init];
    currencyPicker.dataSource = self;
    currencyPicker.delegate = self;
    currencyPicker.showsSelectionIndicator = YES;
    self.currency.inputView = currencyPicker;

    UIToolbar* formNavigationView = [[UIToolbar alloc] init];
    [formNavigationView setBarStyle:UIBarStyleBlackTranslucent];
    if([self.amountType isEqualToString:@"Income"]) {
        [formNavigationView setTintColor:[UIColor colorWithRed:0x00/255.f green:0xaa/255.f blue:0x00/255.f alpha:1]];
    }
    if([self.amountType isEqualToString:@"Expense"]) {
        [formNavigationView setTintColor:[UIColor colorWithRed:0xaa/255.f green:0x00/255.f blue:0x00/255.f alpha:1]];
    }
    [formNavigationView sizeToFit];
    UIBarButtonItem* nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(goToNextField)];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [formNavigationView setItems:[NSArray arrayWithObjects:nextButton, spacer, doneButton, nil]];
    self.note.inputAccessoryView = formNavigationView;
    self.amount.inputAccessoryView = formNavigationView;
    self.amount.keyboardAppearance = UIKeyboardAppearanceAlert;
    self.currency.inputAccessoryView = formNavigationView;
    self.dateOccurs.inputAccessoryView = formNavigationView;
    
    _pickerData = [NSMutableArray arrayWithObject:[NSDate date]];

    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    for (int i = 0; i != 12; i++) {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
        [components setYear:[components year]+(([components month]+i)/12)];
        [components setMonth:([components month]+i)%12];
        [components setDay:1];
        [_pickerData addObject:[cal dateFromComponents:components]];
    }

    self.dateOccurs.text = @"";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if([pickerView isEqual:self.dateOccurs.inputView]) {
        if(row == 0) {
            self.dateOccurs.text = @"";
        }
        else {
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyyMM"];
            self.dateOccurs.text = [df stringFromDate:[_pickerData objectAtIndex:row]];
        }
    }
    if([pickerView isEqual:self.currency.inputView]) {
        self.currency.text = [[_currencies objectAtIndex:row] valueForKey:@"code"];
        NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
        [lastState setObject:[[_currencies objectAtIndex:row] valueForKey:@"code"] forKey:@"mainCurrency"];
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if([pickerView isEqual:self.dateOccurs.inputView]) {
        if(row == 0) {
            return @"(every month)";
        }
        else {
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"MMMM ’yy"];
            return [[df stringFromDate:[_pickerData objectAtIndex:row]] capitalizedString];
        }
    }
    if([pickerView isEqual:self.currency.inputView]) {
        return [[_currencies objectAtIndex:row] valueForKey:@"name"];
    }
    return @"";
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if([pickerView isEqual:self.dateOccurs.inputView]) {
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if([textField isEqual:self.amount]) {
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
        return NO;
    }
    return YES;
}


-(void) viewDidLoad {
    [super viewDidLoad];
    [[self.view viewWithTag:1] becomeFirstResponder];
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    self.amount.text = [formatter stringFromNumber:[NSNumber numberWithDouble:0]];
    if([self.amountType isEqualToString:@"Income"]) {
        [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0x00/255.f green:0xaa/255.f blue:0x00/255.f alpha:1]];
    }
    if([self.amountType isEqualToString:@"Expense"]) {
        [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0xaa/255.f green:0x00/255.f blue:0x00/255.f alpha:1]];
    }
    
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
    _currencies = [[_currencies sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* _Nonnull a, NSDictionary* _Nonnull b) {
        return [[a valueForKey:@"name"] compare:[b valueForKey:@"name"]];
    }] mutableCopy];
}

- (void)viewDidUnload {
    [self setNote:nil];
    [self setAmount:nil];
    [self setCurrency:nil];
    [self setAmountLabel:nil];
    [self setNav:nil];
    [self setDateOccurs:nil];
    [self setTypeLabel:nil];
    [super viewDidUnload];
}

@end
