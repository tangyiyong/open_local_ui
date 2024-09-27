import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gap/gap.dart';
import 'package:get_it/get_it.dart';
import 'package:open_local_ui/backend/private/models/model.dart';
import 'package:open_local_ui/backend/private/providers/chat.dart';
import 'package:open_local_ui/backend/private/providers/ollama_api.dart';
import 'package:open_local_ui/backend/private/storage/ollama_models.dart';
import 'package:open_local_ui/core/format.dart';
import 'package:open_local_ui/core/snackbar.dart';
import 'package:open_local_ui/frontend/dialogs/confirmation.dart';
import 'package:open_local_ui/frontend/dialogs/create_model.dart';
import 'package:open_local_ui/frontend/dialogs/import_model.dart';
import 'package:open_local_ui/frontend/dialogs/model_details.dart';
import 'package:open_local_ui/frontend/dialogs/model_settings.dart';
import 'package:open_local_ui/frontend/dialogs/pull_model.dart';
import 'package:open_local_ui/frontend/dialogs/push_model.dart';
import 'package:open_local_ui/frontend/screens/dashboard.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_scroll_multiplatform/smooth_scroll_multiplatform.dart';
import 'package:unicons/unicons.dart';
import 'package:units_converter/units_converter.dart';

enum SortBy {
  name,
  date,
  size,
}

enum SortOrder {
  ascending,
  descending,
}

class ModelsPage extends StatefulWidget {
  final PageController pageController;

  const ModelsPage({super.key, required this.pageController});

  @override
  State<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends State<ModelsPage> {
  late Set<SortBy> _sortBy;
  late Set<SortOrder> _sortOrder;

  final prototypeModel = Model(
    name: '',
    modifiedAt: DateTime.timestamp(),
    size: 0,
    digest: '',
    details: ModelDetails(
      format: '',
      family: '',
      families: [],
      parameterSize: '',
      quantizationLevel: '',
    ),
  );

  @override
  void initState() {
    super.initState();

    _sortBy = {SortBy.name};
    _sortOrder = {SortOrder.ascending};

    SharedPreferences.getInstance().then((prefs) {
      final sortBy = prefs.getInt('modelsSortBy') ?? 0;
      final sortOrder = prefs.getBool('modelsSortOrder') ?? false;

      setState(() {
        _sortBy = {SortBy.values[sortBy]};
        _sortOrder = {sortOrder ? SortOrder.descending : SortOrder.ascending};
      });
    });
  }

  Future<int> _totalOnDiskSize() async {
    var size = 0;

    for (final model in context.read<OllamaAPIProvider>().models) {
      size += model.size;
    }

    return size;
  }

  @override
  Widget build(BuildContext context) {
    var sortedModels = List.from(context.watch<OllamaAPIProvider>().models);

    sortedModels.sort(
      (a, b) {
        if (_sortBy.contains(SortBy.name)) {
          return a.name.compareTo(b.name);
        } else if (_sortBy.contains(SortBy.date)) {
          return a.modifiedAt.compareTo(
            b.modifiedAt,
          );
        } else if (_sortBy.contains(SortBy.size)) {
          return a.size.compareTo(b.size);
        }
        return 0;
      },
    );

    if (_sortOrder.contains(SortOrder.descending)) {
      sortedModels = sortedModels.reversed.toList();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppLocalizations.of(context).modelsPageTitle,
          style: const TextStyle(
            fontSize: 32.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              label: Text(
                AppLocalizations.of(context).modelsPagePullButton,
                style: const TextStyle(fontSize: 18.0),
              ),
              icon: const Icon(UniconsLine.download_alt),
              onPressed: () => showPullModelDialog(context),
            ),
            TextButton.icon(
              label: Text(
                AppLocalizations.of(context).modelsPagePushButton,
                style: const TextStyle(fontSize: 18.0),
              ),
              icon: const Icon(UniconsLine.upload_alt),
              onPressed: () => showPushModelDialog(context),
            ),
            TextButton.icon(
              label: Text(
                AppLocalizations.of(context).modelsPageCreateButton,
                style: const TextStyle(fontSize: 18.0),
              ),
              icon: const Icon(UniconsLine.create_dashboard),
              onPressed: () => showCreateModelDialog(context),
            ),
            TextButton.icon(
              label: Text(
                AppLocalizations.of(context).modelsPageImportButton,
                style: const TextStyle(fontSize: 18.0),
              ),
              icon: const Icon(UniconsLine.import),
              onPressed: () => showImportModelDialog(context),
            ),
            TextButton.icon(
              label: Text(
                AppLocalizations.of(context).modelsPageRefreshButton,
                style: const TextStyle(fontSize: 18.0),
              ),
              icon: const Icon(UniconsLine.sync),
              onPressed: () {
                context.read<OllamaAPIProvider>().updateList();
              },
            ),
          ],
        ),
        const Gap(16),
        const Divider(),
        const Gap(16),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).listFiltersSortByLabel),
            const Gap(16),
            SegmentedButton<SortBy>(
              selectedIcon: const Icon(UniconsLine.check),
              segments: [
                ButtonSegment(
                  value: SortBy.name,
                  label: Text(
                    AppLocalizations.of(context).sortByNameOption,
                  ),
                  icon: const Icon(UniconsLine.tag),
                ),
                ButtonSegment(
                  value: SortBy.date,
                  label: Text(
                    AppLocalizations.of(context).sortByDateOption,
                  ),
                  icon: const Icon(UniconsLine.clock),
                ),
                ButtonSegment(
                  value: SortBy.size,
                  label: Text(
                    AppLocalizations.of(context).sortBySizeOption,
                  ),
                  icon: const Icon(UniconsLine.database),
                ),
              ],
              selected: _sortBy,
              onSelectionChanged: (value) async {
                final prefs = await SharedPreferences.getInstance();

                await prefs.setInt('modelsSortBy', value.first.index);

                setState(() {
                  _sortBy = value;
                });
              },
            ),
            const Gap(16),
            Text(
              AppLocalizations.of(context).listFiltersSortOrderLabel,
            ),
            const Gap(16),
            SegmentedButton<SortOrder>(
              selectedIcon: const Icon(UniconsLine.check),
              segments: [
                ButtonSegment(
                  value: SortOrder.ascending,
                  label: Text(
                    AppLocalizations.of(context).sortOrderAscendingOption,
                  ),
                  icon: const Icon(UniconsLine.arrow_up),
                ),
                ButtonSegment(
                  value: SortOrder.descending,
                  label: Text(
                    AppLocalizations.of(context).sortOrderDescendingOption,
                  ),
                  icon: const Icon(UniconsLine.arrow_down),
                ),
              ],
              selected: _sortOrder,
              onSelectionChanged: (value) async {
                final prefs = await SharedPreferences.getInstance();

                if (value.contains(SortOrder.descending)) {
                  await prefs.setBool('modelsSortOrder', true);
                } else {
                  await prefs.setBool('modelsSortOrder', false);
                }

                setState(() {
                  _sortOrder = value;
                });
              },
            ),
            const Spacer(),
            FutureBuilder(
              future: _totalOnDiskSize(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    AppLocalizations.of(context).totalOnDiskSizeLabel(
                      '${snapshot.data!.convertFromTo(
                            DIGITAL_DATA.byte,
                            DIGITAL_DATA.gigabyte,
                          )!.toStringAsFixed(2)} GB',
                    ),
                  );
                } else {
                  return const Text('');
                }
              },
            ),
          ],
        ),
        const Gap(16),
        Expanded(
          child: DynMouseScroll(
            controller: ScrollController(),
            builder: (context, controller, physics) => ListView.builder(
              shrinkWrap: true,
              physics: physics,
              controller: controller,
              prototypeItem: ModelListTile(
                model: prototypeModel,
                pageController: widget.pageController,
              ),
              itemCount: context.watch<OllamaAPIProvider>().modelsCount,
              itemBuilder: (context, index) {
                return ModelListTile(
                  model: sortedModels[index],
                  pageController: widget.pageController,
                )
                    .animate(delay: (index * 100).ms)
                    .fadeIn(duration: 900.ms, delay: 300.ms)
                    .move(
                      begin: const Offset(-16, 0),
                      curve: Curves.easeOutQuad,
                    );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class ModelListTile extends StatefulWidget {
  final Model model;
  final PageController pageController;

  const ModelListTile({
    super.key,
    required this.model,
    required this.pageController,
  });

  @override
  State<ModelListTile> createState() => _ModelListTileState();
}

class _ModelListTileState extends State<ModelListTile> {
  void _setModel(Model model) async {
    if (context.read<ChatProvider>().isGenerating) {
      SnackBarHelpers.showSnackBar(
        AppLocalizations.of(context).snackBarErrorTitle,
        AppLocalizations.of(context).modelIsGeneratingSnackBar,
        SnackbarContentType.failure,
      );
    } else {
      if (!context.read<ChatProvider>().isSessionSelected) {
        final session = context.read<ChatProvider>().addSession('');
        context.read<ChatProvider>().setSession(session.uuid);
      }

      await context.read<ChatProvider>().setModel(model.name);
      widget.pageController.jumpToPage(PageIndex.chat.index);
    }
  }

  void _deleteModel() async {
    if (context.read<ChatProvider>().modelName == widget.model.name &&
        context.read<ChatProvider>().isGenerating) {
      SnackBarHelpers.showSnackBar(
        AppLocalizations.of(context).snackBarErrorTitle,
        AppLocalizations.of(context).modelIsGeneratingSnackBar,
        SnackbarContentType.failure,
      );
    } else {
      await context.read<OllamaAPIProvider>().remove(widget.model.name);
    }
  }

  Widget _buildTags(String modelName) {
    if (modelName.isEmpty) return const SizedBox.shrink();

    final cleanModelName = modelName.toLowerCase().split(':').first;

    final db = GetIt.instance<OllamaModelsDB>();

    if (!db.isModelInDatabase(cleanModelName)) {
      return const SizedBox.shrink();
    }

    final tags = <Widget>[];

    if (db.doesModelSupport(cleanModelName, 'vision')) {
      tags.add(
        Chip(
          avatar: const Icon(
            UniconsLine.eye,
            color: Colors.purple,
          ),
          label: Text(
            'vision'.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          backgroundColor: Colors.purple.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: const BorderSide(
              color: Colors.purple,
              width: 1,
            ),
          ),
        ),
      );
    }

    if (db.doesModelSupport(cleanModelName, 'tools')) {
      tags.add(
        Chip(
          avatar: const Icon(
            UniconsLine.drill,
            color: Colors.blue,
          ),
          label: Text(
            'tools'.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          backgroundColor: Colors.blue.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: const BorderSide(
              color: Colors.blue,
              width: 1,
            ),
          ),
        ),
      );
    }

    if (db.doesModelSupport(cleanModelName, 'embedding')) {
      tags.add(
        Chip(
          avatar: const Icon(
            UniconsLine.arrow,
            color: Colors.green,
          ),
          label: Text(
            'embedding'.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          backgroundColor: Colors.green.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: const BorderSide(
              color: Colors.green,
              width: 1,
            ),
          ),
        ),
      );
    }

    if (db.doesModelSupport(cleanModelName, 'code')) {
      tags.add(
        Chip(
          avatar: const Icon(
            UniconsLine.brackets_curly,
            color: Colors.deepOrange,
          ),
          label: Text(
            'code'.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          backgroundColor: Colors.deepOrange.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: const BorderSide(
              color: Colors.deepOrange,
              width: 1,
            ),
          ),
        ),
      );
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: tags,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.model.name),
      subtitle: Text(
        AppLocalizations.of(context).modifiedAtTextShared(
          FortmatHelpers.standardDate(widget.model.modifiedAt),
        ),
        style: const TextStyle(
          color: Colors.grey,
        ),
      ),
      trailing: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTags(widget.model.name),
          const Gap(16),
          IconButton(
            tooltip: AppLocalizations.of(context).modelsPageSettingsButton,
            icon: const Icon(UniconsLine.setting),
            onPressed: () => SnackBarHelpers.showSnackBar(
              AppLocalizations.of(context).snackBarWarningTitle,
              AppLocalizations.of(context).enteringCriticalSectionSnackBar,
              SnackbarContentType.warning,
              onTap: () => showModelSettingsDialog(widget.model.name, context),
            ),
          ),
          const Gap(8),
          IconButton(
            tooltip: AppLocalizations.of(context).modelsPageDetailsButton,
            icon: const Icon(UniconsLine.info_circle),
            onPressed: () => showModelDetailsDialog(widget.model, context),
          ),
          const Gap(8),
          IconButton(
            tooltip: AppLocalizations.of(context).modelsPageDeleteButton,
            icon: const Icon(
              UniconsLine.trash,
              color: Colors.red,
            ),
            onPressed: () {
              showConfirmationDialog(
                context: context,
                title: AppLocalizations.of(context).modelsPageDeleteDialogTitle,
                content:
                    AppLocalizations.of(context).modelsPageDeleteDialogText(
                  widget.model.name,
                ),
                onConfirm: () => _deleteModel(),
              );
            },
          ),
        ],
      ),
      onTap: () => _setModel(widget.model),
    );
  }
}
