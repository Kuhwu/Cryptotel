import 'dart:io';
import 'package:hotel_flutter/data/data_provider/auth/auth_data_provider.dart';
import 'package:hotel_flutter/data/model/auth/login_model.dart';
import 'package:hotel_flutter/data/model/auth/signup_model.dart';
import 'package:hotel_flutter/data/model/auth/user_model.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hotel_flutter/presentation/widgets/tabscreen/user_storage_helper.dart';

class AuthRepository {
  SharedPreferences? _sharedPrefs;
  final Logger _logger = Logger('AuthRepository');
  final AuthDataProvider dataProvider;
  UserModel? _cachedUser;

  AuthRepository(this.dataProvider);

  Future<void> initializeSharedPreferences() async {
    _sharedPrefs = await SharedPreferences.getInstance();
  }

  String? getUserId() {
    return _sharedPrefs
        ?.getString('userId'); // Replace 'userId' with your actual key
  }

  //! Register
  Future<UserModel> register(
      SignUpModel signUpModel, File? profilePicture) async {
    try {
      final data = await dataProvider.register(signUpModel, profilePicture);
      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  //! Login
  Future<LoginModel> login(String email, String password) async {
    try {
      final data = await dataProvider.login(email, password);
      return LoginModel.fromJson(data);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  //! Forgot Password
  Future<void> forgotPassword(String email) async {
    try {
      await dataProvider.forgotPassword(email);
    } catch (e) {
      throw Exception(
          'Did not find any email or an error occurred. Please try again.');
    }
  }

  //! Reset Password
  Future<void> resetPassword(
      String token, String newPassword, String confirmPassword) async {
    return await dataProvider.resetPassword(
        token, newPassword, confirmPassword);
  }

  //! Resend Code
  Future<void> resendCode(String email) async {
    try {
      await dataProvider.resendCode(email);
    } catch (e) {
      throw Exception('Failed to resend verification code: ${e.toString()}');
    }
  }

  //! Get user
  Future<UserModel> getUser(String userId) async {
    try {
      // Directly fetch the UserModel from the data provider
      final user = await dataProvider.getUser(userId);

      // Cache the user after fetching
      _cachedUser = user; // This ensures you're always fetching fresh data

      // Save user details to SharedPreferences
      if (_sharedPrefs != null) {
        await _sharedPrefs!.setString('userId', user.id ?? '');
        await _sharedPrefs!.setString('firstName', user.firstName ?? '');
        await _sharedPrefs!.setString('lastName', user.lastName ?? '');
        await _sharedPrefs!.setString('email', user.email ?? '');
        await _sharedPrefs!.setString('gender', user.gender ?? '');
        await _sharedPrefs!.setString('phoneNumber', user.phoneNumber ?? '');
        await _sharedPrefs!.setString('roles', user.roles ?? '');
        await _sharedPrefs!.setString('favoriteId', user.favoriteId ?? '');
        await _sharedPrefs!
            .setString('profilePicture', user.profilePicture ?? '');
      } else {
        throw Exception('Shared preferences not initialized');
      }

      return _cachedUser!;
    } catch (error) {
      throw Exception('Error fetching data');
    }
  }

  //! Fetch all managers
  Future<List<UserModel>> fetchAllManagers() async {
    try {
      // Fetch all users from the data provider
      final usersData = await dataProvider.fetchAllUsers();

      // Filter only managers
      final managers = usersData.where((user) {
        return user.roles?.toLowerCase() == 'manager' &&
            (user.active == true || user.active == null) &&
            user.verified == true &&
            user.hasCompletedOnboarding == true;
      }).toList();

      print('Filtered managers count: ${managers.length}');
      return managers;
    } catch (error) {
      print('Failed to fetch managers: $error');
      throw Exception('Failed to fetch managers: $error');
    }
  }

//! Fetch all users with filtering conditions
  Future<List<UserModel>> fetchAllUsers() async {
    try {
      // First, get users from SharedPreferences
      List<UserModel> storedUsers = await UserStorageHelper.getUsers();

      // If storedUsers is not empty, return it
      if (storedUsers.isNotEmpty) {
        print('Fetched users from SharedPreferences: ${storedUsers.length}');
        return storedUsers;
      }

      // If no stored users, fetch from the data provider
      final usersData = await dataProvider.fetchAllUsers();

      if (usersData.isEmpty) {
        throw Exception('No users data found');
      }

      // Log the fetched users
      final filteredUsers = usersData.where((user) {
        return (user.active == true || user.active == null) &&
            user.verified == true &&
            user.hasCompletedOnboarding == true &&
            user.roles == "user";
      }).toList();

      // Store the fetched users in SharedPreferences
      await UserStorageHelper.storeUsers(filteredUsers);

      print('Filtered users count: ${filteredUsers.length}');
      return filteredUsers;
    } catch (error) {
      print('Failed to fetch all users: $error');
      throw Exception('Failed to fetch all users: $error');
    }
  }

  //! Logout
  Future<void> logout() async {
    try {
      await dataProvider.logout();
      clearUserCache(); // Clear cache on logout if necessary
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  //! Change Password
  Future<void> changePassword(String currentPassword, String newPassword,
      String confirmPassword) async {
    try {
      await dataProvider.changePassword(
          currentPassword, newPassword, confirmPassword);
      _logger.info('Password changed successfully');
    } catch (e) {
      _logger.severe('Failed to change password: $e');
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  //! Verify User
  Future<void> verifyUser(String email, String code) async {
    try {
      await dataProvider.verifyUser(email, code);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

//! Update User
  Future<UserModel> updateUser(
    UserModel user, {
    String? firstName,
    String? lastName,
    String? email,
    File? profilePicture,
  }) async {
    try {
      final updatedUser = await dataProvider.updateUserData(
        firstName: firstName ?? user.firstName,
        lastName: lastName ?? user.lastName,
        email: email ?? user.email,
        profilePicture: profilePicture,
      );

      // Ensure _sharedPrefs is initialized
      if (_sharedPrefs != null) {
        // Update shared preferences with non-null assertion
        await _sharedPrefs!.setString('userId', updatedUser.id ?? '');
        await _sharedPrefs!.setString('firstName', updatedUser.firstName ?? '');
        await _sharedPrefs!.setString('lastName', updatedUser.lastName ?? '');
        await _sharedPrefs!.setString('email', updatedUser.email ?? '');
        await _sharedPrefs!
            .setString('profilePicture', updatedUser.profilePicture ?? '');
      } else {
        throw Exception('Shared preferences not initialized');
      }

      return updatedUser; // Return the updated UserModel
    } catch (error) {
      throw Exception('Failed to update user: $error');
    }
  }

  //! Delete Account
  Future<void> deleteAccount() async {
    try {
      await dataProvider
          .deleteAccount(); // Call data provider to delete account
      clearUserCache(); // Clear the cached user data
      _logger.info('Account deleted successfully');
    } catch (e) {
      _logger.severe('Failed to delete account: $e'); // Log error
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  //! Check Onboarding Status
  Future<bool> checkOnboardingStatus(String userId) async {
    try {
      final user = await getUser(userId);
      return user.hasCompletedOnboarding ?? false;
    } catch (e) {
      return false; // Default to false on error
    }
  }

  //! Complete Onboarding
  Future<void> completeOnboarding() async {
    try {
      await dataProvider.completeOnboarding();
      _cachedUser?.hasCompletedOnboarding =
          true; // Update the cached user status
    } catch (e) {
      throw Exception('Failed to complete onboarding: ${e.toString()}');
    }
  }

  //! Clearing Cache
  void clearUserCache() {
    _cachedUser = null;
  }

  //! Add to Favorites
  Future<void> addToFavorites(String userId, String type, String id) {
    return dataProvider.addToFavorites(userId, type, id);
  }

  //! Remove from Favorites
  Future<void> removeFromFavorites(String userId, String type, String id) {
    return dataProvider.removeFromFavorites(userId, type, id);
  }

  //! Get Favorites
  Future<Map<String, List<String>>> getFavorites(String userId) {
    return dataProvider.getFavorites(userId);
  }
}
