extension StringReverse on String {
  String reverse() {
    return split('').reversed.join();
  }
}

extension StringWords on String {
  int countWords() {
    final words = split(RegExp(r'\s+'));
    return words.where((w) => w.isNotEmpty).length;
  }
}

extension StringEmail on String {
  bool isEmail() {
    return RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(this);
  }
}

extension StringPhoneNumber on String {
  bool isPhoneNumber() {
    // regular expression to match phone number
    final phoneNumberRegex = RegExp(
        r'^(?:(?:\+?1\s*(?:[.-]\s*)?)?(?:\(\s*([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9])\s*\)|([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9]))\s*(?:[.-]\s*)?)?([2-9]1[02-9]|[2-9][02-9]1|[2-9][02-9]{2})\s*(?:[.-]\s*)?([0-9]{4})(?:\s*(?:#|x\.?|ext\.?|extension)\s*(\d+))?$');
    return phoneNumberRegex.hasMatch(this);
  }
}

extension StringNumeric on String {
  bool isNumeric() {
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }
}

extension StringAlpha on String {
  bool isAlpha() {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  }
}


extension StringCapitalize on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

extension StringAscii on String {
  bool isAscii() {
    return RegExp(r'^[\x00-\x7F]+$').hasMatch(this);
  }
}


extension StringCapitalizeWords on String {
  String capitalizeWords() {
    return split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
  }
}