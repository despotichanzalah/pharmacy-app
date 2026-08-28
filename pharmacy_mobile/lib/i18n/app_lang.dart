import 'package:flutter/foundation.dart';

// Simple app-wide language state — no extra package needed. Wrap widgets that
// should rebuild on language change in AnimatedBuilder(animation: AppLang.instance, ...).
class AppLang extends ChangeNotifier {
  static final AppLang instance = AppLang._();
  AppLang._();

  String _lang = 'en';
  String get lang => _lang;
  bool get isUrdu => _lang == 'ur';

  void toggle() {
    _lang = _lang == 'en' ? 'ur' : 'en';
    notifyListeners();
  }
}

const Map<String, Map<String, String>> _translations = {
  'en': {
    'appName': 'Pharmacy System',
    'welcomeBack': 'Welcome back',
    'signInSub': "Sign in to your shop's dashboard",
    'email': 'Email',
    'password': 'Password',
    'rememberMe': 'Remember me',
    'forgotPassword': 'Forgot password?',
    'signIn': 'Sign in',
    'signingIn': 'Signing in…',
    'newShopQuestion': 'New shop or joining one?',
    'createAccount': 'Create an account',
    'createYourAccount': 'Create your account',
    'createAccountSub': 'Open a new shop, or join one your team already runs.',
    'startNewShop': 'Start a new shop',
    'joinMyShop': 'Join my shop',
    'yourName': 'Your name',
    'shopName': 'Shop name',
    'youWillBeAdmin': "You'll be this shop's Admin.",
    'yourShop': 'Your shop',
    'selectShop': 'Select a shop…',
    'yourRole': 'Your role',
    'pharmacist': 'Pharmacist',
    'cashier': 'Cashier',
    'admin': 'Admin',
    'creatingAccount': 'Creating account…',
    'alreadyHaveAccount': 'Already have an account?',
    'overview': 'Overview',
    'medicines': 'Medicines',
    'stock': 'Stock',
    'sales': 'Sales',
    'salesHistory': 'Sales History',
    'returns': 'Returns',
    'suppliers': 'Suppliers',
    'purchases': 'Purchases',
    'reports': 'Reports',
    'staff': 'Staff',
    'signOut': 'Sign out',
  },
  'ur': {
    'appName': 'فارمیسی سسٹم',
    'welcomeBack': 'خوش آمدید',
    'signInSub': 'اپنی دکان کے ڈیش بورڈ میں سائن ان کریں',
    'email': 'ای میل',
    'password': 'پاس ورڈ',
    'rememberMe': 'یاد رکھیں',
    'forgotPassword': 'پاس ورڈ بھول گئے؟',
    'signIn': 'سائن ان',
    'signingIn': 'سائن ان ہو رہا ہے…',
    'newShopQuestion': 'نئی دکان یا کسی میں شامل ہونا ہے؟',
    'createAccount': 'اکاؤنٹ بنائیں',
    'createYourAccount': 'اپنا اکاؤنٹ بنائیں',
    'createAccountSub': 'نئی دکان کھولیں، یا اپنی ٹیم کی موجودہ دکان میں شامل ہوں۔',
    'startNewShop': 'نئی دکان شروع کریں',
    'joinMyShop': 'اپنی دکان میں شامل ہوں',
    'yourName': 'آپ کا نام',
    'shopName': 'دکان کا نام',
    'youWillBeAdmin': 'آپ اس دکان کے ایڈمن ہوں گے۔',
    'yourShop': 'آپ کی دکان',
    'selectShop': 'دکان منتخب کریں…',
    'yourRole': 'آپ کا کردار',
    'pharmacist': 'فارماسسٹ',
    'cashier': 'کیشیئر',
    'admin': 'ایڈمن',
    'creatingAccount': 'اکاؤنٹ بن رہا ہے…',
    'alreadyHaveAccount': 'پہلے سے اکاؤنٹ ہے؟',
    'overview': 'جائزہ',
    'medicines': 'ادویات',
    'stock': 'اسٹاک',
    'sales': 'فروخت',
    'salesHistory': 'فروخت کی تاریخ',
    'returns': 'واپسی',
    'suppliers': 'سپلائرز',
    'purchases': 'خریداری',
    'reports': 'رپورٹس',
    'staff': 'عملہ',
    'signOut': 'سائن آؤٹ',
  },
};

String t(String key) {
  return _translations[AppLang.instance.lang]?[key] ?? _translations['en']![key] ?? key;
}
