import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/constants/app_constants.dart';
import '../../transactions/models/transaction_type.dart';

class TargetedAlbumInfo {
  final String id;
  final String name;
  final int assetCount;
  final bool isBankingFolder;
  final bool isSelected;
  final bool isIncomeFolder;
  final bool isIncomeSelected;

  const TargetedAlbumInfo({
    required this.id,
    required this.name,
    required this.assetCount,
    required this.isBankingFolder,
    this.isSelected = false,
    this.isIncomeFolder = false,
    this.isIncomeSelected = false,
  });

  TargetedAlbumInfo copyWith({
    bool? isSelected,
    bool? isIncomeFolder,
    bool? isIncomeSelected,
  }) {
    return TargetedAlbumInfo(
      id: id,
      name: name,
      assetCount: assetCount,
      isBankingFolder: isBankingFolder,
      isSelected: isSelected ?? this.isSelected,
      isIncomeFolder: isIncomeFolder ?? this.isIncomeFolder,
      isIncomeSelected: isIncomeSelected ?? this.isIncomeSelected,
    );
  }
}

class ScannableAsset {
  final AssetEntity asset;
  final TransactionType targetType;
  final String albumName;

  ScannableAsset({
    required this.asset,
    required this.targetType,
    required this.albumName,
  });
}

class TargetedAlbumService {
  List<String> _userExpenseFolderNames = List.from(AppConstants.defaultBankingFolders);
  List<String> _userIncomeFolderNames = List.from(AppConstants.defaultIncomeFolders);

  List<String> get targetedFolderNames => List.unmodifiable(_userExpenseFolderNames);
  List<String> get incomeFolderNames => List.unmodifiable(_userIncomeFolderNames);

  void setExpenseFolderNames(List<String> names) {
    _userExpenseFolderNames = List.from(names);
  }

  void setIncomeFolderNames(List<String> names) {
    _userIncomeFolderNames = List.from(names);
  }

  void addTargetedFolderName(String name) {
    if (!_userExpenseFolderNames.contains(name)) {
      _userExpenseFolderNames.add(name);
    }
  }

  void removeTargetedFolderName(String name) {
    _userExpenseFolderNames.remove(name);
  }

  void addIncomeFolderName(String name) {
    if (!_userIncomeFolderNames.contains(name)) {
      _userIncomeFolderNames.add(name);
    }
  }

  void removeIncomeFolderName(String name) {
    _userIncomeFolderNames.remove(name);
  }

  /// Request photo library permission with limited/privacy scope
  Future<PermissionState> requestPermission() async {
    return await PhotoManager.requestPermissionExtend();
  }

  /// Discover all image albums and identify which ones are banking or income slip folders.
  /// [savedExpenseIds] / [savedIncomeIds]:
  ///   null  → first launch (never configured) → auto-select conservative banking apps for expense only
  ///   Set   → user has configured at least once → use ONLY those IDs (even if empty = nothing selected)
  Future<List<TargetedAlbumInfo>> getAvailableAlbums({
    Set<String>? savedExpenseIds,
    Set<String>? savedIncomeIds,
  }) async {
    // Conservative list of EXACT banking-app album names for first-launch auto-select.
    // We only match albums whose names contain these strings.
    // Income is NEVER auto-selected — user must explicitly pick.
    const firstLaunchAutoExpense = [
      'k plus', 'kplus', 'scb easy', 'scbeasy', 'krungthai next', 'ktbnext',
      'make by kbank', 'paotang', 'เป๋าตัง', 'ttb touch', 'bualuang mbanking',
      'bualuang', 'mymo', 'kma', 'krungsri', 'a-mobile', 'baac',
      'kkp mobile', 'cimb thai', 'uob tmrw', 'truemoney wallet',
      'ghb all', 'lhb you', 'move clean',
    ];

    final bool isConfigured = savedExpenseIds != null || savedIncomeIds != null;

    try {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: false,
      );

      final List<TargetedAlbumInfo> results = [];

      for (final path in paths) {
        final count = await path.assetCountAsync;
        final name = path.name;
        final nameLower = name.toLowerCase().trim();

        // Keyword detection is used for HINT BADGES only — not for auto-selection
        final isIncome = isLikelyIncomeAlbum(name);
        final isBanking = !isIncome && isLikelyBankingAlbum(name);

        bool isIncomeSelected;
        bool isSelected;

        if (isConfigured) {
          // EXPLICIT-ONLY: Only use saved IDs — no keyword fallback
          isIncomeSelected = savedIncomeIds?.contains(path.id) ?? false;
          isSelected = !isIncomeSelected && (savedExpenseIds?.contains(path.id) ?? false);
        } else {
          // FIRST LAUNCH: Conservative auto-select of known banking apps (expense only)
          isIncomeSelected = false; // Never auto-select income
          isSelected = !isIncome && firstLaunchAutoExpense.any(
            (kw) => nameLower.contains(kw),
          );
        }

        results.add(TargetedAlbumInfo(
          id: path.id,
          name: name,
          assetCount: count,
          isBankingFolder: isBanking,
          isSelected: isSelected,
          isIncomeFolder: isIncome,
          isIncomeSelected: isIncomeSelected,
        ));
      }

      // Sort: Income folders first, then Banking folders, then alphabetically
      results.sort((a, b) {
        final aPriority = a.isIncomeFolder ? 0 : (a.isBankingFolder ? 1 : 2);
        final bPriority = b.isIncomeFolder ? 0 : (b.isBankingFolder ? 1 : 2);
        if (aPriority != bPriority) return aPriority.compareTo(bPriority);
        return a.name.compareTo(b.name);
      });

      return results;
    } catch (e) {
      print('Error fetching albums: $e');
      return [];
    }
  }

  /// Checks if album name matches privacy whitelist for Thai banks (Expense).
  /// Excludes any album that matches Income keywords so Income is never swallowed.
  bool isLikelyBankingAlbum(String albumName) {
    if (isLikelyIncomeAlbum(albumName)) return false;
    final lower = albumName.toLowerCase().trim();
    for (final target in _userExpenseFolderNames) {
      if (lower.contains(target.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /// Checks if album name matches keywords for Income albums
  bool isLikelyIncomeAlbum(String albumName) {
    final lower = albumName.toLowerCase().trim();
    for (final target in _userIncomeFolderNames) {
      if (lower.contains(target.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /// Fetches scannable assets for both Expense and Income with target type metadata
  Future<List<ScannableAsset>> fetchAssetsToScan({
    List<String>? selectedExpenseAlbumIds,
    List<String>? selectedIncomeAlbumIds,
    int maxCount = 1000,
  }) async {
    try {
      final filterOption = FilterOptionGroup()
        ..addOrderOption(
          const OrderOption(
            type: OrderOptionType.createDate,
            asc: false,
          ),
        );

      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: false,
        filterOption: filterOption,
      );

      final List<ScannableAsset> scannableAssets = [];
      final Set<String> seenAssetIds = {};

      for (final path in paths) {
        // EXPLICIT-ONLY: Only scan albums with IDs the user has explicitly selected.
        // No keyword fallback — if user unticked an album, it is NOT scanned.
        final isIncomeTarget = selectedIncomeAlbumIds != null &&
            selectedIncomeAlbumIds.contains(path.id);

        if (isIncomeTarget) {
          final assets = await path.getAssetListRange(start: 0, end: maxCount);
          for (final asset in assets) {
            if (seenAssetIds.add(asset.id)) {
              scannableAssets.add(ScannableAsset(
                asset: asset,
                targetType: TransactionType.income,
                albumName: path.name,
              ));
            }
          }
          continue; // Already processed as income, skip expense check
        }

        // EXPLICIT-ONLY: Only scan if explicitly in expense list
        final isExpenseTarget = !isIncomeTarget &&
            selectedExpenseAlbumIds != null &&
            selectedExpenseAlbumIds.contains(path.id);

        if (isExpenseTarget) {
          final assets = await path.getAssetListRange(start: 0, end: maxCount);
          for (final asset in assets) {
            if (seenAssetIds.add(asset.id)) {
              scannableAssets.add(ScannableAsset(
                asset: asset,
                targetType: TransactionType.expense,
                albumName: path.name,
              ));
            }
          }
        }
      }

      // Sort assets descending by creation date (newest first)
      scannableAssets.sort((a, b) => b.asset.createDateTime.compareTo(a.asset.createDateTime));
      return scannableAssets.take(maxCount).toList();
    } catch (e) {
      print('Error fetching scannable assets: $e');
      return [];
    }
  }

  /// Legacy helper for backward compatibility
  Future<List<AssetEntity>> fetchAssetsFromTargetedAlbums({
    List<String>? selectedAlbumIds,
    int maxCount = 1000,
  }) async {
    final scannables = await fetchAssetsToScan(
      selectedExpenseAlbumIds: selectedAlbumIds,
      maxCount: maxCount,
    );
    return scannables.map((s) => s.asset).toList();
  }
}
