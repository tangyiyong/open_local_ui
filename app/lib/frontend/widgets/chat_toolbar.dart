import 'package:flutter/material.dart';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gap/gap.dart';
import 'package:open_local_ui/backend/private/providers/chat.dart';
import 'package:open_local_ui/backend/private/providers/model.dart';
import 'package:open_local_ui/core/snackbar.dart';
import 'package:open_local_ui/frontend/dialogs/model_settings.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class ChatToolbarWidget extends StatefulWidget {
  const ChatToolbarWidget({super.key});

  @override
  State<ChatToolbarWidget> createState() => _ChatToolbarWidgetState();
}

class _ChatToolbarWidgetState extends State<ChatToolbarWidget> {
  void _newSession() {
    if (context.read<ChatProvider>().isSessionSelected) {
      if (context.read<ChatProvider>().session!.messages.isEmpty) {
        SnackBarHelpers.showSnackBar(
          AppLocalizations.of(context).snackBarInfoTitle,
          AppLocalizations.of(context).noNeedToCreateSessionSnackBar,
          SnackbarContentType.info,
        );
      } else if (context.read<ChatProvider>().isGenerating) {
        SnackBarHelpers.showSnackBar(
          AppLocalizations.of(context).snackBarErrorTitle,
          AppLocalizations.of(context).modelIsGeneratingSnackBar,
          SnackbarContentType.failure,
        );
      } else {
        context.read<ChatProvider>().newSession();
      }
    } else {
      SnackBarHelpers.showSnackBar(
        AppLocalizations.of(context).snackBarInfoTitle,
        AppLocalizations.of(context).noNeedToCreateSessionSnackBar,
        SnackbarContentType.info,
      );
    }
  }

  Widget _buildModelSelectionWidget(BuildContext context) {
    final List<DropdownMenuEntry> modelsMenuEntries = [];

    for (final model in context.read<ModelProvider>().models) {
      late String modelName;

      if (model.name.length > 20) {
        modelName = '${model.name.substring(0, 20)}...';
      } else {
        modelName = model.name;
      }

      modelsMenuEntries.add(
        DropdownMenuEntry(
          value: model.name,
          label: modelName,
        ),
      );
    }

    return DropdownMenu(
      key: const Key('model_selector'),
      enabled: context.watch<ModelProvider>().modelsCount > 0 &&
          !context.watch<ChatProvider>().isGenerating,
      menuHeight: 128,
      menuStyle: MenuStyle(
        elevation: WidgetStateProperty.all(
          8.0,
        ),
        shape: WidgetStateProperty.all(
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      enableSearch: true,
      hintText: AppLocalizations.of(context).chatToolbarModelSelectorHint,
      initialSelection: context.watch<ChatProvider>().modelName,
      dropdownMenuEntries: modelsMenuEntries,
      onSelected: (value) => context.read<ChatProvider>().setModel(value ?? ''),
    );
  }

  // ignore: unused_element
  Widget _buildChatOptionBarWidget(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AdaptiveTheme.of(context).theme.dividerColor,
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              Text(AppLocalizations.of(context).chatToolbarWebSearchOption),
              Checkbox(
                value: context.watch<ChatProvider>().isWebSearchEnabledForModel,
                onChanged: !context.watch<ChatProvider>().isGenerating
                    ? (value) {
                        context
                            .read<ChatProvider>()
                            .enableWebSearch(value ?? false);
                      }
                    : null,
              ),
              const Gap(8),
              Text(AppLocalizations.of(context).chatToolbarDocsSearchOption),
              Checkbox(
                value:
                    context.watch<ChatProvider>().isDocsSearchEnabledForModel,
                onChanged: !context.watch<ChatProvider>().isGenerating
                    ? (value) {
                        context
                            .read<ChatProvider>()
                            .enableDocsSearch(value ?? false);
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (context.read<ChatProvider>().modelName.isNotEmpty)
          IconButton(
            tooltip: AppLocalizations.of(context).modelsPageSettingsButton,
            icon: const Icon(UniconsLine.setting),
            onPressed: () => SnackBarHelpers.showSnackBar(
              AppLocalizations.of(context).snackBarWarningTitle,
              AppLocalizations.of(context).enteringCriticalSectionSnackBar,
              SnackbarContentType.warning,
              onTap: () => showModelSettingsDialog(
                context.read<ChatProvider>().modelName,
                context,
              ),
            ),
          ),
        if (context.read<ChatProvider>().modelName.isNotEmpty) const Gap(16),
        _buildModelSelectionWidget(context),
        const Gap(16),
        // _buildChatOptionBarWidget(context),
        // const Gap(16),
        ElevatedButton.icon(
          key: const Key('new_session_button'),
          label: Text(
            AppLocalizations.of(context).chatToolbarNewSessionButton,
            style: const TextStyle(fontSize: 18.0),
          ),
          icon: const Icon(UniconsLine.plus),
          onPressed: !context.watch<ChatProvider>().isGenerating
              ? () => _newSession()
              : null,
        ),
      ],
    );
  }
}
