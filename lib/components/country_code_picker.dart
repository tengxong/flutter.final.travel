import 'package:flutter/material.dart';

class CountryCodePicker extends StatelessWidget {
  final String selectedCode;
  final ValueChanged<String?> onChanged;

  const CountryCodePicker({
    super.key,
    required this.selectedCode,
    required this.onChanged,
  });

  static const List<Map<String, String>> countryCodes = [
    {'code': '+66', 'name': 'TH (+66)'},
    {'code': '+1', 'name': 'US (+1)'},
    {'code': '+44', 'name': 'GB (+44)'},
    {'code': '+81', 'name': 'JP (+81)'},
    {'code': '+856', 'name': 'LA (+856)'},
    // เพิ่มประเทศอื่นๆ ได้ตามต้องการ
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedCode,
      decoration: const InputDecoration(
        labelText: 'Country Code',
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      ),
      style: const TextStyle(fontSize: 30),
      items: countryCodes
          .map((c) => DropdownMenuItem(
                value: c['code'],
                child: Text(c['name']!, style: const TextStyle(fontSize: 15, color: Colors.black)),
              ))
          .toList(),
      onChanged: onChanged,
      isExpanded: true,
      iconSize: 18,
    );
  }
} 