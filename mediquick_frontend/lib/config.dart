class Config {
  static const String apiUrl = 'http://localhost:5000/api';

  static const String loginUrl = '$apiUrl/auth/login';
  static const String registerUrl = '$apiUrl/auth/register';
  static const String updateAddressUrl = '$apiUrl/auth/address';
  static const String uploadPrescriptionUrl = '$apiUrl/prescription/upload';
  static const String myOrdersUrl = '$apiUrl/order/myorders';
  static const String simpleOrderUrl = '$apiUrl/simple-order';
  static const String simpleMyOrdersUrl = '$apiUrl/simple-order/myorders';
  static const String medicineSearchUrl = '$apiUrl/medicine/search';
  static String medicineDetailsUrl(String id) => '$apiUrl/medicine/$id';

  // Admin
  static const String adminLoginUrl = '$apiUrl/auth/admin-login';
  static const String adminStatsUrl = '$apiUrl/admin/stats';
  static const String adminUsersUrl = '$apiUrl/admin/users';
  static const String adminGodownsUrl = '$apiUrl/admin/godowns';
  static String adminGodownUrl(String id) => '$apiUrl/admin/godowns/$id';
}

