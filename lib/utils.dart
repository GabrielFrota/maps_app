import 'package:flutter/material.dart';

class Utils {
  Utils._();

  static FormFieldValidator<String>? emptyCheck = (val) {
    return val == null || val.isEmpty ? 'Cannot be empty' : null;
  };
}