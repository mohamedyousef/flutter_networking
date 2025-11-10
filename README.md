<div align="center">

# 🌐 Network Package

**A powerful, type-safe networking package for Flutter/Dart applications**

[![Dart](https://img.shields.io/badge/Dart-2.15+-0175C2?logo=dart)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-0.2.0-blue.svg)](pubspec.yaml)

Built on top of [Dio](https://pub.dev/packages/dio) with a clean, type-safe API for REST APIs, GraphQL, and file uploads.

[Features](#-features) • [Installation](#-installation) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Examples](#-examples)

</div>

---

## 📋 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Documentation](#-documentation)
  - [NetworkService](#networkservice)
  - [NetworkRequest](#networkrequest)
  - [NetworkResponse](#networkresponse)
  - [NetworkErrorType](#networkerrortype)
  - [UploadFile](#uploadfile)
- [Advanced Features](#-advanced-features)
  - [Automatic Token Refresh](#automatic-token-refresh)
  - [Custom Interceptors](#custom-interceptors)
  - [Error Handling](#error-handling)
- [Examples](#-examples)
- [Best Practices](#-best-practices)
- [Architecture](#-architecture)
- [Contributing](#-contributing)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔄 **REST API Support** | Make GET, POST, PUT, PATCH, DELETE requests with type-safe responses |
| 🔷 **GraphQL Support** | Execute GraphQL queries and mutations with automatic error handling |
| 📤 **File Uploads** | Upload single or multiple files with progress tracking |
| 🔐 **Automatic Token Refresh** | Built-in access token refresh interceptor |
| 🛠️ **Request Interceptors** | Customizable header and logging interceptors |
| 🎯 **Type-Safe Responses** | Strongly typed response handling with error types |
| ⚠️ **Error Handling** | Comprehensive error type classification |
| 📝 **Logging** | Built-in request/response logging (optional) |

---

## 📦 Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  network:
    path: ../network  # or use git/version if published
```

Then run:

```bash
flutter pub get
```

---

## 🚀 Quick Start

### 1. Initialize NetworkService

```dart
import 'package:network/network.dart';

final networkService = NetworkService(
  baseUrlBuilder: () async => 'https://api.example.com',
  enableLogging: true,
  connectTimeout: 8000,
  sendTimeout: 8000,
  receiveTimeout: 10000,
);
```

### 2. Make a REST API Request

```dart
// Create a request
final request = NetworkRequest.get(
  endpoint: '/users',
);

// Execute the request
final response = await networkService.request<Map<String, dynamic>, UserModel>(
  request: request,
  fromJson: (json) => UserModel.fromJson(json),
);

// Handle the response
response.when(
  success: (user) {
    print('User: ${user.name}');
  },
  failure: (error) {
    print('Error: $error');
  },
);
```

### 3. Make a GraphQL Query

```dart
const query = '''
  query GetUser($id: ID!) {
    user(id: $id) {
      id
      name
      email
    }
  }
''';

final request = NetworkRequest.graphQl(
  query: query,
  variables: {'id': '123'},
);

final response = await networkService.executeGraphQLRequest<UserModel>(
  request: request,
  fromJson: (json) => UserModel.fromJson(json),
);

response.when(
  success: (user) {
    print('User: ${user.name}');
  },
  failure: (error) {
    print('Error: $error');
  },
);
```

---

## 📚 Documentation

### NetworkService

The main service class for making network requests.

#### Constructor

```dart
NetworkService({
  required BaseUrlBuilder baseUrlBuilder,
  CreateRefreshAccessTokenOptions? createRefreshAccessTokenOptions,
  void Function()? onUnAuthorizedCallback,
  bool enableLogging = true,
  int connectTimeout = 8000,
  int sendTimeout = 8000,
  int receiveTimeout = 10000,
})
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `baseUrlBuilder` | `BaseUrlBuilder` | Async function that returns the base URL |
| `createRefreshAccessTokenOptions` | `CreateRefreshAccessTokenOptions?` | Optional token refresh configuration |
| `onUnAuthorizedCallback` | `void Function()?` | Callback invoked on 401 unauthorized responses |
| `enableLogging` | `bool` | Enable/disable request/response logging (default: `true`) |
| `connectTimeout` | `int` | Connection timeout in milliseconds (default: `8000`) |
| `sendTimeout` | `int` | Send timeout in milliseconds (default: `8000`) |
| `receiveTimeout` | `int` | Receive timeout in milliseconds (default: `10000`) |

#### Methods

##### `request<T, K>`

Make a REST API request with type-safe response handling.

**Signature:**
```dart
Future<NetworkResponse<T>> request<T extends Object, K>({
  required NetworkRequest request,
  K Function(Map<String, dynamic>)? fromJson,
})
```

**Example:**
```dart
final request = NetworkRequest.post(
  endpoint: '/users',
  body: {
    'name': 'John',
    'email': 'john@example.com',
  },
);

final response = await networkService.request<UserModel, UserModel>(
  request: request,
  fromJson: (json) => UserModel.fromJson(json),
);

response.when(
  success: (user) => print('Created: ${user.id}'),
  failure: (error) => print('Error: $error'),
);
```

##### `executeGraphQLRequest<T>`

Execute a GraphQL query or mutation with automatic error handling.

**Signature:**
```dart
Future<NetworkResponse<T>> executeGraphQLRequest<T>({
  required NetworkRequest request,
  required T Function(Map<String, dynamic>) fromJson,
})
```

**Example:**
```dart
const mutation = '''
  mutation CreateUser($input: UserInput!) {
    createUser(input: $input) {
      id
      name
    }
  }
''';

final request = NetworkRequest.graphQl(
  query: mutation,
  variables: {
    'input': {
      'name': 'John',
      'email': 'john@example.com',
    },
  },
);

final response = await networkService.executeGraphQLRequest<UserModel>(
  request: request,
  fromJson: (json) => UserModel.fromJson(json),
);
```

##### `executeGraphQLUpload<T>`

Execute a GraphQL mutation with file uploads and progress tracking.

**Signature:**
```dart
Future<NetworkResponse<T>> executeGraphQLUpload<T>({
  required NetworkRequest request,
  required T Function(Map<String, dynamic>) fromJson,
  void Function(double progress)? onProgress,
})
```

**Example:**
```dart
final files = [
  UploadFile(
    file: File('/path/to/image.jpg'),
    fieldName: 'avatar',
  ),
];

final request = NetworkRequest.graphQlUpload(
  query: mutation,
  variables: {'name': 'John'},
  files: files,
);

final response = await networkService.executeGraphQLUpload<UserModel>(
  request: request,
  fromJson: (json) => UserModel.fromJson(json),
  onProgress: (progress) {
    print('Upload progress: ${(progress * 100).toInt()}%');
  },
);
```

##### `requestMultipart<T, K>`

Make a multipart/form-data request for file uploads with progress tracking.

**Signature:**
```dart
Future<NetworkResponse<T>> requestMultipart<T extends Object, K>({
  required NetworkRequest request,
  K Function(Map<String, dynamic>)? fromJson,
  void Function(double progress)? onProgress,
})
```

**Example:**
```dart
final request = NetworkRequest.post(
  endpoint: '/upload',
  body: {
    'file': File('/path/to/file.pdf'),
    'description': 'My file',
  },
);

final response = await networkService.requestMultipart<UploadResponse, UploadResponse>(
  request: request,
  fromJson: (json) => UploadResponse.fromJson(json),
  onProgress: (progress) {
    print('Progress: ${(progress * 100).toInt()}%');
  },
);
```

##### `addInterceptor`

Add a custom Dio interceptor for request/response modification.

**Signature:**
```dart
void addInterceptor(Interceptor interceptor)
```

**Example:**
```dart
networkService.addInterceptor(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      options.headers['X-Request-ID'] = generateRequestId();
      handler.next(options);
    },
    onResponse: (response, handler) {
      print('Response: ${response.statusCode}');
      handler.next(response);
    },
    onError: (error, handler) {
      print('Error: ${error.message}');
      handler.next(error);
    },
  ),
);
```

##### `addHeaderInterceptor`

Add a custom header interceptor for dynamic header management.

**Signature:**
```dart
void addHeaderInterceptor(HeaderInterceptor interceptor)
```

**Example:**
```dart
class CustomHeaderInterceptor implements HeaderInterceptor {
  @override
  void onHeaderRequest(RequestOptions options) {
    options.headers['X-API-Key'] = 'your-api-key';
    options.headers['X-Client-Version'] = '1.0.0';
  }
}

networkService.addHeaderInterceptor(CustomHeaderInterceptor());
```

---

### NetworkRequest

A builder class for creating network requests with a fluent API.

#### Constructors

| Constructor | Method | Description |
|------------|--------|-------------|
| `NetworkRequest.get()` | GET | Retrieve resources |
| `NetworkRequest.post()` | POST | Create resources |
| `NetworkRequest.put()` | PUT | Update resources (full) |
| `NetworkRequest.patch()` | PATCH | Update resources (partial) |
| `NetworkRequest.delete()` | DELETE | Delete resources |
| `NetworkRequest.graphQl()` | POST | GraphQL query/mutation |
| `NetworkRequest.graphQlUpload()` | POST | GraphQL mutation with files |

#### Common Parameters

```dart
NetworkRequest.get({
  required String endpoint,
  String endpointVersion = '',
  Map<String, dynamic>? body,
})
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `endpoint` | `String` | API endpoint path (required) |
| `endpointVersion` | `String` | API version prefix (default: `''`) |
| `body` | `Map<String, dynamic>?` | Request body data (optional) |

#### Methods

##### `addQueryParameter`

Add a query parameter to the request.

```dart
void addQueryParameter(String key, String value)
```

##### `addHeader`

Add a custom header to the request.

```dart
void addHeader(String key, String value)
```

**Example:**
```dart
final request = NetworkRequest.get(
  endpoint: '/users',
)
  ..addQueryParameter('page', '1')
  ..addQueryParameter('limit', '10')
  ..addQueryParameter('sort', 'name')
  ..addHeader('Accept', 'application/json')
  ..addHeader('X-Custom-Header', 'value');
```

**GraphQL Example:**
```dart
final request = NetworkRequest.graphQl(
  query: '''
    query GetUsers($limit: Int!) {
      users(limit: $limit) {
        id
        name
      }
    }
  ''',
  variables: {'limit': 10},
);
```

---

### NetworkResponse

A wrapper class for network responses with success/failure handling.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `statusCode` | `int?` | HTTP status code |
| `rawData` | `dynamic` | Raw response data |

#### Methods

##### `when`

Handle success or failure cases with type-safe callbacks.

**Signature:**
```dart
R when<R>({
  required R Function(T data) success,
  required R Function(NetworkErrorType error) failure,
})
```

**Example:**
```dart
final result = response.when(
  success: (data) {
    return 'Success: ${data.name}';
  },
  failure: (error) {
    return 'Error: $error';
  },
);
```

##### `ifHasError`

Execute a callback if the response has an error.

**Signature:**
```dart
void ifHasError(void Function(NetworkErrorType networkErrorType) onHasError)
```

**Example:**
```dart
response.ifHasError((error) {
  if (error == NetworkErrorType.unauthorized) {
    // Redirect to login
    navigator.pushReplacementNamed('/login');
  } else if (error == NetworkErrorType.server) {
    // Show server error message
    showErrorSnackBar('Server error. Please try again later.');
  }
});
```

##### `getDataOnError<K>`

Extract error data from failed responses.

**Signature:**
```dart
K? getDataOnError<K>({required K Function(Map<String, dynamic>) fromJson})
```

**Example:**
```dart
final errorData = response.getDataOnError<ErrorModel>(
  fromJson: (json) => ErrorModel.fromJson(json),
);

if (errorData != null) {
  print('Error message: ${errorData.message}');
  print('Error code: ${errorData.code}');
}
```

---

### NetworkErrorType

Enumeration of network error types for comprehensive error handling.

```dart
enum NetworkErrorType {
  cancel,           // Request was cancelled
  parsing,          // JSON parsing error
  badRequest,       // 400 Bad Request
  unauthorized,     // 401 Unauthorized
  forbidden,        // 403 Forbidden
  noData,           // 404 Not Found
  unprocessable,    // 422 Unprocessable Entity
  badConnection,    // Connection/timeout errors
  server,           // 500+ Server errors
  other,            // Other errors
  operation,        // GraphQL operation errors
}
```

#### Error Type Mapping

| HTTP Status | NetworkErrorType | Description |
|-------------|------------------|-------------|
| - | `cancel` | Request was cancelled |
| - | `parsing` | JSON parsing failed |
| 400 | `badRequest` | Invalid request |
| 401 | `unauthorized` | Authentication required |
| 403 | `forbidden` | Access denied |
| 404 | `noData` | Resource not found |
| 422 | `unprocessable` | Validation error |
| - | `badConnection` | Network/timeout error |
| 500+ | `server` | Server error |
| - | `other` | Unknown error |
| - | `operation` | GraphQL operation error |

---

### UploadFile

Class for representing files to upload with metadata.

**Constructor:**
```dart
UploadFile({
  required File file,
  required String fieldName,
  String? fileName,
  String? contentType,
})
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `file` | `File` | The file to upload (required) |
| `fieldName` | `String` | Form field name (required) |
| `fileName` | `String?` | Custom filename (optional) |
| `contentType` | `String?` | MIME type (optional) |

**Example:**
```dart
final uploadFile = UploadFile(
  file: File('/path/to/image.jpg'),
  fieldName: 'avatar',
  fileName: 'profile.jpg',
  contentType: 'image/jpeg',
);
```

---

## 🔧 Advanced Features

### Automatic Token Refresh

Configure automatic access token refresh when receiving 401 responses. The interceptor will automatically retry the original request after refreshing the token.

**Implementation:**

```dart
class RefreshTokenOptions extends CreateRefreshAccessTokenOptions {
  final TokenStorage storage;
  
  RefreshTokenOptions(this.storage);

  @override
  Future<String?> get currentToken async {
    // Return current access token from storage
    return await storage.getAccessToken();
  }

  @override
  Future<NetworkRequest?> get networkRequest async {
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null) return null;
    
    return NetworkRequest.post(
      endpoint: '/auth/refresh',
      body: {'refreshToken': refreshToken},
    );
  }

  @override
  String get networkRequestPath => '/auth/refresh';

  @override
  String parse(dynamic data) {
    // Extract new access token from response
    return data['accessToken'] as String;
  }

  @override
  void onTokenCreated(String token) {
    // Save new access token to storage
    storage.saveAccessToken(token);
  }
}

// Usage
final networkService = NetworkService(
  baseUrlBuilder: () async => 'https://api.example.com',
  createRefreshAccessTokenOptions: RefreshTokenOptions(tokenStorage),
  onUnAuthorizedCallback: () {
    // Handle case when token refresh fails
    // e.g., redirect to login screen
    authService.logout();
    navigator.pushReplacementNamed('/login');
  },
);
```

**Flow Diagram:**

```
Request → 401 Unauthorized
    ↓
Refresh Token Request
    ↓
Token Refresh Success?
    ├─ Yes → Retry Original Request → Success
    └─ No → Call onUnAuthorizedCallback → Logout
```

---

### Custom Interceptors

Add custom interceptors for request/response modification, analytics, or debugging.

**Request Interceptor Example:**
```dart
networkService.addInterceptor(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      // Add request ID for tracking
      options.headers['X-Request-ID'] = generateRequestId();
      
      // Add timestamp
      options.headers['X-Request-Time'] = DateTime.now().toIso8601String();
      
      // Log request
      logger.d('Request: ${options.method} ${options.path}');
      
      handler.next(options);
    },
  ),
);
```

**Response Interceptor Example:**
```dart
networkService.addInterceptor(
  InterceptorsWrapper(
    onResponse: (response, handler) {
      // Log response
      logger.d('Response: ${response.statusCode}');
      
      // Track analytics
      analytics.trackApiCall(
        endpoint: response.requestOptions.path,
        statusCode: response.statusCode,
        duration: response.extra['duration'],
      );
      
      handler.next(response);
    },
  ),
);
```

**Error Interceptor Example:**
```dart
networkService.addInterceptor(
  InterceptorsWrapper(
    onError: (error, handler) {
      // Log error
      logger.e('Error: ${error.message}', error: error);
      
      // Track error analytics
      analytics.trackError(
        endpoint: error.requestOptions.path,
        statusCode: error.response?.statusCode,
        message: error.message,
      );
      
      handler.next(error);
    },
  ),
);
```

---

### Error Handling

The package provides comprehensive error handling through `NetworkErrorType`:

```dart
response.when(
  success: (data) {
    // Handle success
    return data;
  },
  failure: (error) {
    switch (error) {
      case NetworkErrorType.badConnection:
        // Handle connection issues
        showSnackBar('No internet connection');
        break;
        
      case NetworkErrorType.unauthorized:
        // Handle unauthorized access
        authService.logout();
        navigator.pushReplacementNamed('/login');
        break;
        
      case NetworkErrorType.forbidden:
        // Handle forbidden access
        showSnackBar('You don\'t have permission to access this resource');
        break;
        
      case NetworkErrorType.server:
        // Handle server errors
        showSnackBar('Server error. Please try again later.');
        break;
        
      case NetworkErrorType.parsing:
        // Handle JSON parsing errors
        logger.e('Failed to parse response');
        showSnackBar('Invalid response format');
        break;
        
      case NetworkErrorType.unprocessable:
        // Handle validation errors
        final errorData = response.getDataOnError<ValidationError>(
          fromJson: (json) => ValidationError.fromJson(json),
        );
        if (errorData != null) {
          showValidationErrors(errorData.errors);
        }
        break;
        
      default:
        // Handle other errors
        showSnackBar('An unexpected error occurred');
    }
  },
);
```

---

## 💡 Examples

### REST API Examples

#### GET Request with Query Parameters

```dart
final request = NetworkRequest.get(
  endpoint: '/users',
)
  ..addQueryParameter('page', '1')
  ..addQueryParameter('limit', '20')
  ..addQueryParameter('sort', 'name')
  ..addHeader('Accept', 'application/json');

final response = await networkService.request<List<UserModel>, UserModel>(
  request: request,
  fromJson: (json) => UserModel.fromJson(json),
);

response.when(
  success: (users) {
    print('Found ${users.length} users');
  },
  failure: (error) {
    print('Failed to fetch users: $error');
  },
);
```

#### POST Request (Create)

```dart
final request = NetworkRequest.post(
  endpoint: '/users',
  body: {
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 30,
  },
)
  ..addHeader('Content-Type', 'application/json');

final response = await networkService.request<UserModel, UserModel>(
  request: request,
  fromJson: (json) => UserModel.fromJson(json),
);

response.when(
  success: (user) {
    print('User created: ${user.id}');
  },
  failure: (error) {
    print('Failed to create user: $error');
  },
);
```

#### PUT Request (Update)

```dart
final request = NetworkRequest.put(
  endpoint: '/users/123',
  body: {
    'name': 'Jane Doe',
    'email': 'jane@example.com',
  },
);

final response = await networkService.request<UserModel, UserModel>(
  request: request,
  fromJson: (json) => UserModel.fromJson(json),
);
```

#### DELETE Request

```dart
final request = NetworkRequest.delete(
  endpoint: '/users/123',
);

final response = await networkService.request<bool, bool>(
  request: request,
);

response.when(
  success: (_) {
    print('User deleted successfully');
  },
  failure: (error) {
    print('Failed to delete user: $error');
  },
);
```

---

### GraphQL Examples

#### Query with Variables

```dart
const query = '''
  query GetUsers($limit: Int!, $offset: Int!) {
    users(limit: $limit, offset: $offset) {
      id
      name
      email
      posts {
        id
        title
      }
    }
  }
''';

final request = NetworkRequest.graphQl(
  query: query,
  variables: {
    'limit': 10,
    'offset': 0,
  },
);

final response = await networkService.executeGraphQLRequest<UsersData>(
  request: request,
  fromJson: (json) => UsersData.fromJson(json),
);

response.when(
  success: (data) {
    print('Found ${data.users.length} users');
  },
  failure: (error) {
    print('GraphQL error: $error');
  },
);
```

#### Mutation

```dart
const mutation = '''
  mutation UpdateUser($id: ID!, $input: UserInput!) {
    updateUser(id: $id, input: $input) {
      id
      name
      email
    }
  }
''';

final request = NetworkRequest.graphQl(
  query: mutation,
  variables: {
    'id': '123',
    'input': {
      'name': 'Jane Doe',
      'email': 'jane@example.com',
    },
  },
);

final response = await networkService.executeGraphQLRequest<UserModel>(
  request: request,
  fromJson: (json) => UserModel.fromJson(json['updateUser']),
);
```

---

### File Upload Examples

#### Single File Upload (REST)

```dart
final request = NetworkRequest.post(
  endpoint: '/upload',
  body: {
    'file': File('/path/to/document.pdf'),
    'type': 'document',
    'description': 'Important document',
  },
);

final response = await networkService.requestMultipart<UploadResult, UploadResult>(
  request: request,
  fromJson: (json) => UploadResult.fromJson(json),
  onProgress: (progress) {
    final percentage = (progress * 100).toInt();
    print('Upload progress: $percentage%');
    // Update UI progress indicator
  },
);

response.when(
  success: (result) {
    print('File uploaded: ${result.url}');
  },
  failure: (error) {
    print('Upload failed: $error');
  },
);
```

#### Multiple Files Upload

```dart
final request = NetworkRequest.post(
  endpoint: '/upload/multiple',
  body: {
    'files': [
      File('/path/to/image1.jpg'),
      File('/path/to/image2.jpg'),
      File('/path/to/image3.jpg'),
    ],
    'album': 'Vacation Photos',
  },
);

final response = await networkService.requestMultipart<UploadResult, UploadResult>(
  request: request,
  fromJson: (json) => UploadResult.fromJson(json),
  onProgress: (progress) {
    print('Upload progress: ${(progress * 100).toInt()}%');
  },
);
```

#### GraphQL File Upload

```dart
const mutation = '''
  mutation UploadAvatar($userId: ID!) {
    uploadAvatar(userId: $userId) {
      id
      avatarUrl
    }
  }
''';

final request = NetworkRequest.graphQlUpload(
  query: mutation,
  variables: {'userId': '123'},
  files: [
    UploadFile(
      file: File('/path/to/avatar.jpg'),
      fieldName: 'avatar',
      fileName: 'profile.jpg',
      contentType: 'image/jpeg',
    ),
  ],
);

final response = await networkService.executeGraphQLUpload<UserModel>(
  request: request,
  fromJson: (json) => UserModel.fromJson(json['uploadAvatar']),
  onProgress: (progress) {
    print('Upload progress: ${(progress * 100).toInt()}%');
  },
);
```

---

## 🎯 Best Practices

### 1. Use Type-Safe Models

Always provide `fromJson` functions for type-safe responses:

```dart
// ✅ Good
final response = await networkService.request<UserModel, UserModel>(
  request: request,
  fromJson: (json) => UserModel.fromJson(json),
);

// ❌ Avoid
final response = await networkService.request<Map, Map>(
  request: request,
);
```

### 2. Handle Errors Properly

Always use the `when` method to handle both success and failure cases:

```dart
// ✅ Good
response.when(
  success: (data) => handleSuccess(data),
  failure: (error) => handleError(error),
);

// ❌ Avoid
if (response.isSuccess) {
  // Missing error handling
}
```

### 3. Configure Appropriate Timeouts

Set timeout values based on your API requirements:

```dart
final networkService = NetworkService(
  baseUrlBuilder: () async => baseUrl,
  connectTimeout: 10000,  // 10 seconds for slow networks
  sendTimeout: 30000,      // 30 seconds for large uploads
  receiveTimeout: 30000,   // 30 seconds for large downloads
);
```

### 4. Enable Logging in Development

Use logging during development for debugging:

```dart
final networkService = NetworkService(
  baseUrlBuilder: () async => baseUrl,
  enableLogging: kDebugMode,  // Only in debug mode
);
```

### 5. Implement Token Refresh

Always set up automatic token refresh for authenticated APIs:

```dart
final networkService = NetworkService(
  baseUrlBuilder: () async => baseUrl,
  createRefreshAccessTokenOptions: RefreshTokenOptions(),
  onUnAuthorizedCallback: () => handleLogout(),
);
```

### 6. Use Interceptors for Common Functionality

Add interceptors for cross-cutting concerns:

```dart
// Add request ID for tracking
networkService.addInterceptor(RequestIdInterceptor());

// Add analytics tracking
networkService.addInterceptor(AnalyticsInterceptor());

// Add error reporting
networkService.addInterceptor(ErrorReportingInterceptor());
```

### 7. Centralize Network Service

Create a singleton or use dependency injection:

```dart
// Using Riverpod
final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService(
    baseUrlBuilder: () async => ref.read(configProvider).apiUrl,
    createRefreshAccessTokenOptions: RefreshTokenOptions(ref),
  );
});
```

---

## 🏗️ Architecture

### Request Flow

```
┌─────────────────┐
│  NetworkRequest │
│   (Builder)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ NetworkService  │
│   (Core)        │
└────────┬────────┘
         │
         ├──► Interceptors
         │    ├── LoggingInterceptor
         │    ├── AccessTokenInterceptor
         │    └── Custom Interceptors
         │
         ▼
┌─────────────────┐
│      Dio        │
│  (HTTP Client)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ NetworkResponse │
│   (Wrapper)     │
└─────────────────┘
```

### Error Handling Flow

```
Request
  │
  ├─► Success ──► NetworkResponse.success()
  │
  └─► Error
       │
       ├─► 401 Unauthorized
       │    ├─► Token Refresh Available?
       │    │    ├─ Yes ──► Refresh Token ──► Retry Request
       │    │    └─ No ──► onUnAuthorizedCallback()
       │    │
       │    └─► NetworkResponse.failure(unauthorized)
       │
       ├─► Network Error ──► NetworkResponse.failure(badConnection)
       │
       ├─► Parsing Error ──► NetworkResponse.failure(parsing)
       │
       └─► Other Error ──► NetworkResponse.failure(other)
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Dart style guidelines
- Write tests for new features
- Update documentation as needed
- Ensure all tests pass

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Made with ❤️ for Flutter developers**

[Report Bug](https://github.com/your-repo/issues) • [Request Feature](https://github.com/your-repo/issues) • [Documentation](#-documentation)

</div>
