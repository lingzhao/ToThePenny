//
//  AddCategoryViewController.m
//  Depoza
//
//  Created by Ivan Magda on 19.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "AddCategoryViewController.h"
#import "CollectionViewController.h"

    //CoreData
#import "CategoryData+Fetch.h"

    //KVNProgress
#import <KVNProgress/KVNProgress.h>

@interface AddCategoryViewController () <UITextFieldDelegate>

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender;

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIImageView *iconImage;

@end

@implementation AddCategoryViewController {
    NSString *_categoryName;
}

#pragma mark - LifeCycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(self.managedObjectContext != nil);

    self.textField.delegate = self;
    [self.textField becomeFirstResponder];

    if (_iconName == nil) {
        _iconName = @"Puzzle";
    }
    self.iconImage.image = [UIImage imageNamed:_iconName];
}

#pragma mark - IBActions -

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self.textField resignFirstResponder];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(id)sender {
    [self.textField resignFirstResponder];

    [self adjustmentOfText];

    if ([self isUniqueName:_categoryName]) {
        CategoryData *category = [CategoryData categoryDataWithTitle:_categoryName iconName:_iconName andExpenses:nil inManagedObjectContext:_managedObjectContext];

        NSError *error = nil;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Error when save %@", [error localizedDescription]);
        }

        [self.delegate addCategoryViewController:self didFinishAddingCategory:category];

        [KVNProgress showSuccessWithStatus:NSLocalizedString(@"Category added", @"AddCategoryVC succes text for show") completion:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    } else {
        [KVNProgress showErrorWithStatus:NSLocalizedString(@"enter a unique name", @"AddCategorVC message for KVNProgress showWithError") completion:^{
            self.textField.text = @"";
            [self.textField becomeFirstResponder];
        }];
    }
}

#pragma mark - Helpers -

- (void)adjustmentOfText {
    NSString *firstLetter = [self.textField.text substringToIndex:1];
    NSRange range = {0, 1};
    _categoryName = [_categoryName stringByReplacingCharactersInRange:range withString:firstLetter.uppercaseString];

    _categoryName = [_categoryName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)isUniqueName:(NSString *)name {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];

    NSExpression *title = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(title))];
    NSExpression *categoryName = [NSExpression expressionForConstantValue:name];
    NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:title
                                                                rightExpression:categoryName
                                                                       modifier:NSDirectPredicateModifier
                                                                           type:NSEqualToPredicateOperatorType
                                                                        options:NSCaseInsensitivePredicateOption];
    fetchRequest.predicate = predicate;

    NSUInteger countCategories = [self.managedObjectContext countForFetchRequest:fetchRequest error:nil];
    return (countCategories == 0);
}

#pragma mark - UITextFieldDelegate -

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *stringFromTextField = [textField.text stringByReplacingCharactersInRange:range withString:string];

    self.doneButton.enabled = (stringFromTextField.length > 0);

    _categoryName = stringFromTextField;

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    _categoryName = textField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.textField resignFirstResponder];
    return YES;
}

#pragma mark - Navigation -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ChooseIcon"]) {
        CollectionViewController *controller = segue.destinationViewController;
        controller.selectedIconName = _iconName;
        controller.isAddingNewCategoryMode = YES;
    }
}

- (IBAction)didPickIcon:(UIStoryboardSegue *)unwindSegue {
    UIViewController *sourceVC = unwindSegue.sourceViewController;
    if ([sourceVC isKindOfClass:[CollectionViewController class]]) {
        CollectionViewController *controller = (CollectionViewController *)sourceVC;
        NSString *iconName = controller.selectedIconName;
        self.iconImage.image = [UIImage imageNamed:iconName];
        _iconName = iconName;
    }
}

@end