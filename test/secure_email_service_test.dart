import 'package:flutter_test/flutter_test.dart';
import 'package:moodi/core/secure_email_service.dart';

void main() {
  group('SecureEmailService Tests', () {
    test('should add and retrieve email account', () async {
      // Test email account
      const testEmail = 'test@example.com';
      const testPassword = 'testpassword123';
      const testDisplayName = 'Test User';
      const testProvider = 'example.com';

      // Add email account
      await SecureEmailService.addEmailAccount(
        email: testEmail,
        password: testPassword,
        displayName: testDisplayName,
        provider: testProvider,
      );

      // Retrieve all accounts
      final accounts = await SecureEmailService.getAllEmailAccounts();
      
      // Verify account was added
      expect(accounts, isNotEmpty);
      final addedAccount = accounts.firstWhere((acc) => acc['email'] == testEmail);
      expect(addedAccount['email'], equals(testEmail));
      expect(addedAccount['password'], equals(testPassword));
      expect(addedAccount['displayName'], equals(testDisplayName));
      expect(addedAccount['provider'], equals(testProvider));
      expect(addedAccount['createdAt'], isNotNull);
      expect(addedAccount['lastUsed'], isNotNull);

      // Clean up
      await SecureEmailService.deleteEmailAccount(testEmail);
    });

    test('should update existing email account', () async {
      // Test email account
      const testEmail = 'update@example.com';
      const testPassword = 'oldpassword';
      const newPassword = 'newpassword123';

      // Add email account
      await SecureEmailService.addEmailAccount(
        email: testEmail,
        password: testPassword,
      );

      // Update password
      await SecureEmailService.updateEmailAccount(
        email: testEmail,
        password: newPassword,
      );

      // Retrieve account
      final updatedAccount = await SecureEmailService.getEmailAccount(testEmail);
      
      // Verify password was updated
      expect(updatedAccount, isNotNull);
      expect(updatedAccount!['password'], equals(newPassword));

      // Clean up
      await SecureEmailService.deleteEmailAccount(testEmail);
    });

    test('should delete email account', () async {
      // Test email account
      const testEmail = 'delete@example.com';
      const testPassword = 'deletepassword';

      // Add email account
      await SecureEmailService.addEmailAccount(
        email: testEmail,
        password: testPassword,
      );

      // Verify account was added
      var accounts = await SecureEmailService.getAllEmailAccounts();
      expect(accounts.any((acc) => acc['email'] == testEmail), isTrue);

      // Delete account
      await SecureEmailService.deleteEmailAccount(testEmail);

      // Verify account was deleted
      accounts = await SecureEmailService.getAllEmailAccounts();
      expect(accounts.any((acc) => acc['email'] == testEmail), isFalse);
    });

    test('should handle encryption security check', () async {
      // Check if encryption is secure
      final isSecure = await SecureEmailService.isEncryptionSecure();
      
      // Should be secure after any operation
      expect(isSecure, isTrue);
    });

    test('should clear all email accounts', () async {
      // Add multiple test accounts
      await SecureEmailService.addEmailAccount(
        email: 'test1@example.com',
        password: 'password1',
      );
      await SecureEmailService.addEmailAccount(
        email: 'test2@example.com',
        password: 'password2',
      );

      // Verify accounts were added
      var accounts = await SecureEmailService.getAllEmailAccounts();
      expect(accounts.length, greaterThanOrEqualTo(2));

      // Clear all accounts
      await SecureEmailService.clearAllEmailAccounts();

      // Verify all accounts were cleared
      accounts = await SecureEmailService.getAllEmailAccounts();
      expect(accounts, isEmpty);
    });
  });
} 