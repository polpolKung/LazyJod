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

  /// Discover all image albums and identify which ones are banking or income slip folders
  Future<List<TargetedAlbumInfo>> getAvailableAlbums({
    Set<String>? savedExpenseIds,
    Set<String>? savedIncomeIds,
  }) async {
    try {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: false,
      );

      final List<TargetedAlbumInfo> results = [];

      for (final path in paths) {
        final count = await path.assetCountAsync;
        final name = path.name;
        final isBanking = isLikelyBankingAlbum(name);
        final isIncome = isLikelyIncomeAlbum(name);

        final isSelected = savedExpenseIds != null && savedExpenseIds.isNotEmpty
            ? savedExpenseIds.contains(path.id)
            : isBanking;

        final isIncomeSelected = savedIncomeIds != null && savedIncomeIds.isNotEmpty
            ? savedIncomeIds.contains(path.id)
            : isIncome;

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

      // Sort: Banking & Income folders first, then alphabetically
      results.sort((a, b) {
        final aPriority = (a.isBankingFolder || a.isIncomeFolder) ? 0 : 1;
        final bPriority = (b.isBankingFolder || b.isIncomeFolder) ? 0 : 1;
        if (aPriority != bPriority) return aPriority.compareTo(bPriority);
        return a.name.compareTo(b.name);
      });

      return results;
    } catch (e) {
      print('Error fetching albums: $e');
      return [];
    }
  }

  /// Checks if album name matches privacy whitelist for Thai banks (Expense)
  bool isLikelyBankingAlbum(String albumName) {
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
    bool scanIncome = false,
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
        // Check if path is selected for income
        final isIncomeTarget = scanIncome &&
            (selectedIncomeAlbumIds != null && selectedIncomeAlbumIds.isNotEmpty
                ? selectedIncomeAlbumIds.contains(path.id)
                : isLikelyIncomeAlbum(path.name));

        // Check if path is selected for expense
        final isExpenseTarget = selectedExpenseAlbumIds != null && selectedExpenseAlbumIds.isNotEmpty
            ? selectedExpenseAlbumIds.contains(path.id)
            : isLikelyBankingAlbum(path.name);

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
        }

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
      scanIncome: false,
      maxCount: maxCount,
    );
    return scannables.map((s) => s.asset).toList();
  }
}
