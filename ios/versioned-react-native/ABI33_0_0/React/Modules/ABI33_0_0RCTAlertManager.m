/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI33_0_0RCTAlertManager.h"

#import "ABI33_0_0RCTAssert.h"
#import "ABI33_0_0RCTConvert.h"
#import "ABI33_0_0RCTLog.h"
#import "ABI33_0_0RCTUtils.h"

@implementation ABI33_0_0RCTConvert (UIAlertViewStyle)

ABI33_0_0RCT_ENUM_CONVERTER(ABI33_0_0RCTAlertViewStyle, (@{
  @"default": @(ABI33_0_0RCTAlertViewStyleDefault),
  @"secure-text": @(ABI33_0_0RCTAlertViewStyleSecureTextInput),
  @"plain-text": @(ABI33_0_0RCTAlertViewStylePlainTextInput),
  @"login-password": @(ABI33_0_0RCTAlertViewStyleLoginAndPasswordInput),
}), ABI33_0_0RCTAlertViewStyleDefault, integerValue)

@end

@interface ABI33_0_0RCTAlertManager()

@end

@implementation ABI33_0_0RCTAlertManager
{
  NSHashTable *_alertControllers;
}

ABI33_0_0RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)invalidate
{
  for (UIAlertController *alertController in _alertControllers) {
    [alertController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  }
}

/**
 * @param {NSDictionary} args Dictionary of the form
 *
 *   @{
 *     @"message": @"<Alert message>",
 *     @"buttons": @[
 *       @{@"<key1>": @"<title1>"},
 *       @{@"<key2>": @"<title2>"},
 *     ],
 *     @"cancelButtonKey": @"<key2>",
 *   }
 * The key from the `buttons` dictionary is passed back in the callback on click.
 * Buttons are displayed in the order they are specified.
 */
ABI33_0_0RCT_EXPORT_METHOD(alertWithArgs:(NSDictionary *)args
                  callback:(ABI33_0_0RCTResponseSenderBlock)callback)
{
  NSString *title = [ABI33_0_0RCTConvert NSString:args[@"title"]];
  NSString *message = [ABI33_0_0RCTConvert NSString:args[@"message"]];
  ABI33_0_0RCTAlertViewStyle type = [ABI33_0_0RCTConvert ABI33_0_0RCTAlertViewStyle:args[@"type"]];
  NSArray<NSDictionary *> *buttons = [ABI33_0_0RCTConvert NSDictionaryArray:args[@"buttons"]];
  NSString *defaultValue = [ABI33_0_0RCTConvert NSString:args[@"defaultValue"]];
  NSString *cancelButtonKey = [ABI33_0_0RCTConvert NSString:args[@"cancelButtonKey"]];
  NSString *destructiveButtonKey = [ABI33_0_0RCTConvert NSString:args[@"destructiveButtonKey"]];
  UIKeyboardType keyboardType = [ABI33_0_0RCTConvert UIKeyboardType:args[@"keyboardType"]];

  if (!title && !message) {
    ABI33_0_0RCTLogError(@"Must specify either an alert title, or message, or both");
    return;
  }

  if (buttons.count == 0) {
    if (type == ABI33_0_0RCTAlertViewStyleDefault) {
      buttons = @[@{@"0": ABI33_0_0RCTUIKitLocalizedString(@"OK")}];
      cancelButtonKey = @"0";
    } else {
      buttons = @[
        @{@"0": ABI33_0_0RCTUIKitLocalizedString(@"OK")},
        @{@"1": ABI33_0_0RCTUIKitLocalizedString(@"Cancel")},
      ];
      cancelButtonKey = @"1";
    }
  }

  UIViewController *presentingController = ABI33_0_0RCTPresentedViewController();
  if (presentingController == nil) {
    ABI33_0_0RCTLogError(@"Tried to display alert view but there is no application window. args: %@", args);
    return;
  }

  UIAlertController *alertController = [UIAlertController
                                        alertControllerWithTitle:title
                                        message:nil
                                        preferredStyle:UIAlertControllerStyleAlert];
  switch (type) {
    case ABI33_0_0RCTAlertViewStylePlainTextInput: {
      [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = NO;
        textField.text = defaultValue;
        textField.keyboardType = keyboardType;
      }];
      break;
    }
    case ABI33_0_0RCTAlertViewStyleSecureTextInput: {
      [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = ABI33_0_0RCTUIKitLocalizedString(@"Password");
        textField.secureTextEntry = YES;
        textField.text = defaultValue;
        textField.keyboardType = keyboardType;
      }];
      break;
    }
    case ABI33_0_0RCTAlertViewStyleLoginAndPasswordInput: {
      [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = ABI33_0_0RCTUIKitLocalizedString(@"Login");
        textField.text = defaultValue;
        textField.keyboardType = keyboardType;
      }];
      [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = ABI33_0_0RCTUIKitLocalizedString(@"Password");
        textField.secureTextEntry = YES;
      }];
      break;
    }
    case ABI33_0_0RCTAlertViewStyleDefault:
      break;
  }

  alertController.message = message;

  for (NSDictionary<NSString *, id> *button in buttons) {
    if (button.count != 1) {
      ABI33_0_0RCTLogError(@"Button definitions should have exactly one key.");
    }
    NSString *buttonKey = button.allKeys.firstObject;
    NSString *buttonTitle = [ABI33_0_0RCTConvert NSString:button[buttonKey]];
    UIAlertActionStyle buttonStyle = UIAlertActionStyleDefault;
    if ([buttonKey isEqualToString:cancelButtonKey]) {
      buttonStyle = UIAlertActionStyleCancel;
    } else if ([buttonKey isEqualToString:destructiveButtonKey]) {
      buttonStyle = UIAlertActionStyleDestructive;
    }
    __weak UIAlertController *weakAlertController = alertController;
    [alertController addAction:[UIAlertAction actionWithTitle:buttonTitle
                                                        style:buttonStyle
                                                      handler:^(__unused UIAlertAction *action) {
      switch (type) {
        case ABI33_0_0RCTAlertViewStylePlainTextInput:
        case ABI33_0_0RCTAlertViewStyleSecureTextInput:
          callback(@[buttonKey, [weakAlertController.textFields.firstObject text]]);
          break;
        case ABI33_0_0RCTAlertViewStyleLoginAndPasswordInput: {
          NSDictionary<NSString *, NSString *> *loginCredentials = @{
            @"login": [weakAlertController.textFields.firstObject text],
            @"password": [weakAlertController.textFields.lastObject text]
          };
          callback(@[buttonKey, loginCredentials]);
          break;
        }
        case ABI33_0_0RCTAlertViewStyleDefault:
          callback(@[buttonKey]);
          break;
      }
    }]];
  }

  if (!_alertControllers) {
    _alertControllers = [NSHashTable weakObjectsHashTable];
  }
  [_alertControllers addObject:alertController];

  dispatch_async(dispatch_get_main_queue(), ^{
    [presentingController presentViewController:alertController animated:YES completion:nil];
  });
}

@end
