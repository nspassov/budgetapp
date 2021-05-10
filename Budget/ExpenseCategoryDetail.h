//
//  ExpenseCategoryDetail.h
//  Budget
//
//  Created by Nikolay Spassov on 05.10.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExpenseCategoryDetail : UIViewController
@property (weak, nonatomic) IBOutlet UIWebView *chartCanvas;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *chartLoading;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) NSString* expenseCategoryName;
@property (weak, nonatomic) IBOutlet UILabel *amountBudgetedForCategory;
@property (weak, nonatomic) IBOutlet UILabel *amountSpentThisMonth;
@property (weak, nonatomic) IBOutlet UILabel *amountSpentLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountBudgetedLabel;

@end
