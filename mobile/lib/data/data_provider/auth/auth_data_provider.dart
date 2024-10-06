import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hotel_flutter/data/model/user_model.dart';
import 'package:hotel_flutter/data/model/signup_model.dart';

class AuthDataProvider {
  final String baseUrl = 'https://3-y1-cryptotel.vercel.app/api/v1/auth';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  //! Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: json.encode({
        'email': email,
        'password': password,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String token = data['token'];
      String userId = data['userId'];
      bool hasCompletedOnboarding = data['hasCompletedOnboarding'] ?? false;

      await storage.write(key: 'jwt', value: token);
      await storage.write(key: 'userId', value: userId);

      return {
        'token': token,
        'userId': userId,
        'hasCompletedOnboarding': hasCompletedOnboarding,
      };
    } else {
      final errorResponse = json.decode(response.body);
      String errorMessage =
          errorResponse['message'] ?? 'An unexpected error occurred.';
      throw Exception('Failed to login: $errorMessage');
    }
  }

  //! Register
  Future<Map<String, dynamic>> register(
      SignUpModel signUpModel, File? profilePicture) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/signup'));
    request.headers['Content-Type'] = 'application/json';

    // Add text fields
    request.fields['firstName'] = signUpModel.firstName;
    request.fields['lastName'] = signUpModel.lastName;
    request.fields['email'] = signUpModel.email;
    request.fields['password'] = signUpModel.password;
    request.fields['confirmPassword'] = signUpModel.confirmPassword;

    // Add file if it exists
    if (profilePicture != null) {
      request.files
          .add(await http.MultipartFile.fromPath('image', profilePicture.path));
    }

    final response = await request.send();

    if (response.statusCode == 201) {
      final responseData = await http.Response.fromStream(response);
      return json.decode(responseData.body);
    } else {
      final errorResponse = await http.Response.fromStream(response);
      String errorMessage =
          json.decode(errorResponse.body)['message'] ?? 'An error occurred';
      throw Exception('Failed to register: $errorMessage');
    }
  }

  //! Verify Code
  Future<void> verifyUser(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verifyCode'),
      body: json.encode({'email': email, 'code': code}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final errorResponse = json.decode(response.body);
      String errorMessage = errorResponse['message'] ?? 'An error occurred';
      throw Exception('Failed to verify code: $errorMessage');
    }
  }

  //! Forgot Password
  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgotPassword'),
      body: json.encode({'email': email}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final errorResponse = json.decode(response.body);
      String errorMessage = errorResponse['message'] ?? 'An error occurred';
      throw Exception('Failed to send reset link: $errorMessage');
    }
  }

  //! Reset Password
  Future<void> resetPassword(
      String token, String newPassword, String confirmPassword) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/resetPassword/$token'),
      body: json.encode({
        'password': newPassword,
        'confirmPassword': confirmPassword,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final errorResponse = json.decode(response.body);
      String errorMessage = errorResponse['message'] ?? 'An error occurred';
      throw Exception('Failed to reset password: $errorMessage');
    }
  }

  //! Fetch User
  Future<UserModel> getUser(String userId) async {
    final token = await storage.read(key: 'jwt');
    final url = 'https://3-y1-cryptotel.vercel.app/api/v1/users/$userId';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return UserModel.fromJson(jsonResponse['data']['user']);
    } else {
      final errorResponse = json.decode(response.body);
      String errorMessage =
          errorResponse['message'] ?? 'Failed to fetch user data';
      throw Exception(errorMessage);
    }
  }

  //! Change Password
  Future<void> updatePassword(String currentPassword, String newPassword,
      String confirmPassword) async {
    final token = await storage.read(key: 'jwt');

    final response = await http.patch(
      Uri.parse('$baseUrl/updateMyPassword'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'passwordCurrent': currentPassword,
        'password': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode != 200) {
      final errorResponse = json.decode(response.body);
      String errorMessage = errorResponse['message'] ?? 'An error occurred';
      throw Exception('Failed to update password: $errorMessage');
    }
  }

  //! Change User Profile Data
  Future<void> updateUserData({
    String? firstName,
    String? lastName,
    String? email,
    File? profilePicture,
  }) async {
    final token = await storage.read(key: 'jwt');

    if (token == null) {
      throw Exception('Authorization token is missing');
    }

    final uri =
        Uri.parse('https://3-y1-cryptotel.vercel.app/api/v1/users/updateMe');
    var request = http.MultipartRequest('PATCH', uri);

    // Set Authorization header
    request.headers['Authorization'] = 'Bearer $token';

    // Add text fields
    if (firstName != null) request.fields['firstName'] = firstName;
    if (lastName != null) request.fields['lastName'] = lastName;
    if (email != null) request.fields['lastName'] = email;

    // Add image file if it exists
    if (profilePicture != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          profilePicture.path,
          contentType:
              MediaType('image', 'png'), // Set the appropriate content type
        ),
      );
    }

    try {
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        print("Profile updated successfully: ${responseData.body}");
        final data = jsonDecode(responseData.body);

        if (data['data']['user']['profile'] != null) {
          print("Profile Picture URL: ${data['data']['user']['profile']}");
        } else {
          print("Profile Picture URL missing in response.");
        }
      } else {
        print("Failed to update profile. Response: ${responseData.body}");
        throw Exception('Failed to update user data: ${responseData.body}');
      }
    } catch (error) {
      print("An error occurred: $error");
      throw Exception('An error occurred during the update');
    }
  }

  //! Logout
  Future<void> logout() async {
    await storage.deleteAll();
  }

  //! Update User Onboarding
  Future<void> completeOnboarding() async {
    final token = await storage.read(key: 'jwt');

    final response = await http.put(
      Uri.parse(
          'https://3-y1-cryptotel.vercel.app/api/v1/users/updateHasCompletedOnboarding'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorResponse = json.decode(response.body);
      String errorMessage = errorResponse['message'] ?? 'An error occurred';
      throw Exception('Failed to complete onboarding: $errorMessage');
    }
  }
}
