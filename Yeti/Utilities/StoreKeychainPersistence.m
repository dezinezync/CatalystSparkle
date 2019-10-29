//
//  StoreKeychainPersistence.m
//  Yeti
//
//  Created by Nikhil Nigade on 08/10/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "StoreKeychainPersistence.h"
#import "Keychain.h"

NSString* const RMStoreTransactionsKeychainKey = @"RMStoreTransactions";

@implementation StoreKeychainPersistence {
    NSDictionary *_transactionsDictionary;
}

#pragma mark - RMStoreTransactionPersistor

- (void)persistTransaction:(SKPaymentTransaction*)paymentTransaction
{
    SKPayment *payment = paymentTransaction.payment;
    NSString *productIdentifier = payment.productIdentifier;
    NSDictionary *transactions = [self transactionsDictionary];
    NSInteger count = [transactions[productIdentifier] integerValue];
    count++;
    NSMutableDictionary *updatedTransactions = [NSMutableDictionary dictionaryWithDictionary:transactions];
    updatedTransactions[productIdentifier] = @(count);
    [self setTransactionsDictionary:updatedTransactions];
}

#pragma mark - Public

- (void)removeTransactions
{
    [self setTransactionsDictionary:nil];
}

- (BOOL)consumeProductOfIdentifier:(NSString*)productIdentifier
{
    NSDictionary *transactions = [self transactionsDictionary];
    NSInteger count = [transactions[productIdentifier] integerValue];
    if (count > 0)
    {
        count--;
        NSMutableDictionary *updatedTransactions = [NSMutableDictionary dictionaryWithDictionary:transactions];
        updatedTransactions[productIdentifier] = @(count);
        [self setTransactionsDictionary:updatedTransactions];
        return YES;
    } else {
        return NO;
    }
}

- (NSInteger)countProductOfdentifier:(NSString*)productIdentifier
{
    NSDictionary *transactions = [self transactionsDictionary];
    NSInteger count = [transactions[productIdentifier] integerValue];
    return count;
}

- (BOOL)isPurchasedProductOfIdentifier:(NSString*)productIdentifier
{
    NSDictionary *transactions = [self transactionsDictionary];
    return transactions[productIdentifier] != nil;
}

- (NSSet*)purchasedProductIdentifiers
{
    NSDictionary *transactions = [self transactionsDictionary];
    NSArray *productIdentifiers = transactions.allKeys;
    return [NSSet setWithArray:productIdentifiers];
}

#pragma mark - Private

- (NSDictionary*)transactionsDictionary
{
    if (!_transactionsDictionary)
    { // Reading the keychain is slow so we cache its values in memory
        NSError *error = nil;
        
        NSData *data = [Keychain dataFor:RMStoreTransactionsKeychainKey error:&error];
        
        if (error) {
            NSLog(@"Error fetching transactions from the keychain: %@", error);
            return nil;
        }
        
        NSDictionary *transactions = @{};
        if (data)
        {
            NSError *error;
            transactions = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (!transactions)
            {
                NSLog(@"RMStoreKeychainPersistence: failed to read JSON data with error %@", error);
            }
        }
        _transactionsDictionary = transactions;
    }
    return _transactionsDictionary;
    
}

- (void)setTransactionsDictionary:(NSDictionary*)dictionary
{
    _transactionsDictionary = dictionary;
    NSData *data = nil;
    if (dictionary)
    {
        NSError *error;
        data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
        if (!data)
        {
            NSLog(@"RMStoreKeychainPersistence: failed to write JSON data with error %@", error);
        }
    }
    
    NSError *error = [Keychain add:RMStoreTransactionsKeychainKey data:data];
    
    if (error != nil) {
        NSLog(@"Error updating keychain value for RMStore: %@", error);
    }

}

@end
