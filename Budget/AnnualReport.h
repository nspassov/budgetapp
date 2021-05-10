//
//  AnnualReport.h
//  Budget
//
//  Created by Nikolay Spassov on 22.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AnnualReport : UIViewController <UITextFieldDelegate, UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *nav;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editSavingsButton;
@property (weak, nonatomic) IBOutlet UIWebView *chartCanvas;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *chartLoading;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (IBAction)editSavings:(UIBarButtonItem *)sender;
- (IBAction)switchExpenses:(id)sender;

@end
