import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/finch_theme.dart';

class FinchQRCode extends StatelessWidget {
  const FinchQRCode({
    super.key,
    required this.data,
    this.size = 180,
  });

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: finch.colors.paper,
        border: Border.all(color: finch.colors.hairline),
        borderRadius: BorderRadius.circular(14),
        boxShadow: finch.colors.shadowSoft,
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        backgroundColor: finch.colors.paper,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: finch.colors.ink,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: finch.colors.ink,
        ),
      ),
    );
  }
}
