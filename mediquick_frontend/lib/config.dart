class Config {
  // static const String apiUrl = 'http://localhost:5000/api';
  // static const apiUrl = "http://10.0.2.2:5000/api";
  static const apiUrl = "http://192.168.43.232:5000/api"; //laptop ip address
  static const String loginUrl = '$apiUrl/auth/login';
  static const String registerUrl = '$apiUrl/auth/register';
  static const String updateAddressUrl = '$apiUrl/auth/address';
  static const String updateLocationUrl = '$apiUrl/auth/location';
  static const String uploadPrescriptionUrl = '$apiUrl/prescription/upload';
  static const String myOrdersUrl = '$apiUrl/order/myorders';
  static const String simpleOrderUrl = '$apiUrl/simple-order';
  static const String simpleMyOrdersUrl = '$apiUrl/simple-order/myorders';
  static const String medicineSearchUrl = '$apiUrl/medicine/search';
  static const String allMedicinesUrl = '$apiUrl/medicine/getmeds';
  static String medicineDetailsUrl(String id) => '$apiUrl/medicine/$id';
  static const String addMedicineUrl = '$apiUrl/medicine';

  // Admin
  static const String adminLoginUrl = '$apiUrl/auth/admin-login';
  static const String adminStatsUrl = '$apiUrl/admin/stats';
  static const String adminUsersUrl = '$apiUrl/admin/users';
  static const String adminGodownsUrl = '$apiUrl/admin/godowns';
  static String adminGodownUrl(String id) => '$apiUrl/admin/godowns/$id';
  static String adminGodownInventoryUrl(String id) => '$apiUrl/admin/godowns/$id/inventory';
}
