//
//  AddAmount.h
//  Budget
//
//  Created by Nikolay Spassov on 15.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AddAmount;

@protocol AddAmountDelegate <NSObject>

-(void) addAmountDidCancel:(AddAmount*)controller;
-(void) addAmountDidSave:(AddAmount*)controller;
@end

@interface AddAmount : UIViewController <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UINavigationItem *nav;
@property (strong, nonatomic) NSString* amountType;

@property (weak, nonatomic) IBOutlet UITextField *note;
@property (weak, nonatomic) IBOutlet UITextField *amount;
@property (weak, nonatomic) IBOutlet UITextField *currency;
@property (weak, nonatomic) IBOutlet UITextField *dateOccurs;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;

@property (nonatomic, weak) id <AddAmountDelegate> delegate;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end
