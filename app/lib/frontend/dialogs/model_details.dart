import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:open_local_ui/backend/private/models/model.dart';
import 'package:units_converter/units_converter.dart';

class ModelDetailsDialog extends StatelessWidget {
  final Model model;

  const ModelDetailsDialog({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(model.name),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context).modifiedAtTextShared(
              model.modifiedAt.toString(),
            ),
          ),
          Text(
            AppLocalizations.of(context).modelDetailsSizeText(
              model.size
                  .convertFromTo(
                    DIGITAL_DATA.byte,
                    DIGITAL_DATA.gigabyte,
                  )!
                  .toStringAsFixed(2),
            ),
          ),
          Text(
            AppLocalizations.of(context).modelDetailsDigestText(model.digest),
          ),
          Text(
            AppLocalizations.of(context)
                .modelDetailsFormatText(model.details.format),
          ),
          Text(
            AppLocalizations.of(context)
                .modelDetailsFamilyText(model.details.family),
          ),
          if (model.details.families != null)
            Text(
              AppLocalizations.of(context).modelDetailsFamilyText(
                model.details.families!.join(', '),
              ),
            ),
          Text(
            AppLocalizations.of(context)
                .modelDetailsParametersSizeText(model.details.parameterSize),
          ),
          Text(
            AppLocalizations.of(context).modelDetailsQuantizationLevelText(
              model.details.quantizationLevel.toString(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            AppLocalizations.of(context).closeButtonShared,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(
          duration: 200.ms,
        )
        .move(
          begin: const Offset(0, 160),
          curve: Curves.easeOutQuad,
        );
  }
}

Future<void> showModelDetailsDialog(Model model, BuildContext context) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return ModelDetailsDialog(model: model);
    },
  );
}
