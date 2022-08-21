import 'package:flutter/material.dart';

class Utils {
  Utils._();

  static FormFieldValidator<String>? emptyCheck = (text) {
    return text == null || text.isEmpty ? 'Cannot be empty' : null;
  };
}