import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/constants/app_constants.dart';

class TargetedAlbumInfo {
  final String id;
  final String name;
  final int assetCount;
  final bool isBankingFolder;
  final bool isSelected;

  const TargetedAlbumInfo({
    required this.id,
    required this.name,
    required this.assetCount,
    required this.isBankingFolder,
    this.isSelected = false,
  });

  TargetedAlbumInfo copyWith({bool? isSelected}) {
    return TargetedAlbumInfo(
      id: id,
      name: name,
      assetCount: assetCount,
      isBankingFolder: isBankingFolder,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class TargetedAlbumService {
  List<String> _userTargetedAlbumNames = List.from(AppConstants.defaultBankingFolders);

  List<String> get targetedFolderNames => List.unmodifiable(_userTargetedAlbumNames);

  void addTargetedFolderName(String name) {
    if (!_userTargetedAlbumNames.contains(name)) {
      _userTargetedAlbumNames.add(name);
    }
  }

  void removeTargetedFolderName(String name) {
    _userTargetedAlbumNames.remove(name);
  }

  /// Request photo library permission with limited/privacy scope
  Future<PermissionState> requestPermission() async {
    return await PhotoManager.requestPermissionExtend();
  }

  /// Discover all image albums and identify which ones are banking slip folders
  Future<List<TargetedAlbumInfo>> getAvailableAlbums() async {
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

        results.add(TargetedAlbumInfo(
          id: path.id,
          name: name,
          assetCount: count,
          isBankingFolder: isBanking,
          isSelected: isBanking,
        ));
      }

      // Sort: Banking folders first, then alphabetically
      results.sort((a, b) {
        if (a.isBankingFolder && !b.isBankingFolder) return -1;
        if (!a.isBankingFolder && b.isBankingFolder) return 1;
        return a.name.compareTo(b.name);
      });

      return results;
    } catch (e) {
      print('Error fetching albums: $e');
      return [];
    }
  }

  /// Checks if album name matches privacy whitelist for Thai banks
  bool isLikelyBankingAlbum(String albumName) {
    final lower = albumName.toLowerCase().trim();
    for (final target in _userTargetedAlbumNames) {
      if (lower.contains(target.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /// Fetches recent slip assets exclusively from the targeted banking albums
  Future<List<AssetEntity>> fetchAssetsFromTargetedAlbums({
    List<String>? selectedAlbumIds,
    int maxCount = 50,
  }) async {
    try {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: false,
      );

      final List<AssetEntity> targetAssets = [];

      for (final path in paths) {
        bool shouldScan = false;
        if (selectedAlbumIds != null && selectedAlbumIds.isNotEmpty) {
          shouldScan = selectedAlbumIds.contains(path.id);
        } else {
          shouldScan = isLikelyBankingAlbum(path.name);
        }

        if (shouldScan) {
          final assets = await path.getAssetListRange(start: 0, end: maxCount);
          targetAssets.addAll(assets);
        }
      }

      // Sort assets descending by creation date
      targetAssets.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
      return targetAssets.take(maxCount).toList();
    } catch (e) {
      print('Error fetching assets from targeted albums: $e');
      return [];
    }
  }
}
