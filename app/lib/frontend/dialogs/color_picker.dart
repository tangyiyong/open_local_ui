import 'package:flutter/material.dart';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
  });

  @override
  _ColorPickerDialogState createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).colorPickerDialogTitle),
      content: ColorPicker(
        color: _selectedColor,
        onColorChanged: (Color color) {
          setState(() {
            _selectedColor = color;
          });
        },
        pickersEnabled: const <ColorPickerType, bool>{
          ColorPickerType.accent: true,
          ColorPickerType.primary: false,
        },
        enableShadesSelection: true,
      ),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context).dialogCancelButtonShared),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(AppLocalizations.of(context).dialogConfirmButtonShared),
          onPressed: () {
            Navigator.of(context).pop(_selectedColor);
          },
        ),
      ],
    );
  }
}

Future<void> showColorPickerDialog({
  required BuildContext context,
  required Color initialColor,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return ColorPickerDialog(
        initialColor: initialColor,
      );
    },
  );
}
