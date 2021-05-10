//
//  AddTrackedAmount.h
//  Budget
//
//  Created by Nikolay Spassov on 30.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class AddTrackedAmount;

@protocol AddTrackedAmountDelegate <NSObject>

-(void) addTrackedAmountDidCancel:(AddTrackedAmount*)controller;
-(void) addTrackedAmountDidSave:(AddTrackedAmount*)controller;
@end

@interface AddTrackedAmount : UIViewController <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, CLLocationManagerDelegate>
{
    CLLocationManager *_locationManager;
}

@property (weak, nonatomic) IBOutlet UINavigationItem *nav;
@property (strong, nonatomic) NSString* amountType;

@property (weak, nonatomic) IBOutlet UITextField *note;
@property (weak, nonatomic) IBOutlet UITextField *amount;
@property (weak, nonatomic) IBOutlet UITextField *currency;
@property (strong, nonatomic) NSString *dateOccurs;
@property (strong, nonatomic) NSString* expenseCategory;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *budgetForCategoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *budgetForCategory;
@property (weak, nonatomic) IBOutlet UILabel *budgetedAmount;
@property (weak, nonatomic) IBOutlet UILabel *venueLabel;
@property (strong, nonatomic) NSString *venueName;
@property (strong, nonatomic) NSDecimalNumber* lat;
@property (strong, nonatomic) NSDecimalNumber* lng;

@property (nonatomic, weak) id <AddTrackedAmountDelegate> delegate;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) UIButton* keypad00button;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end
