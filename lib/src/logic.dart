import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

enum YouTubeLinkType { video, playlist, unknown }

// 'Video' is both video and audio, while 'Audio' is audio-only.
enum DownloadType { Video, VideoHD, Audio }

String cleanFromInvalidFileSystemChars(String str) {
  return str.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}

YouTubeLinkType analyzeYouTubeLink(String url) {
  Uri uri;
  try {
    uri = Uri.parse(url);
  } catch (e) {
    return YouTubeLinkType.unknown;
  }

  // Check for video links
  if (uri.host == 'youtu.be' ||
      uri.pathSegments.contains('watch') ||
      uri.pathSegments.contains('embed') ||
      uri.pathSegments.contains('shorts')) {
    return YouTubeLinkType.video;
  }

  // Check for playlist links
  if (uri.queryParameters.containsKey('list') ||
      uri.pathSegments.contains('playlist')) {
    return YouTubeLinkType.playlist;
  }

  return YouTubeLinkType.unknown;
}

Future<String?> getPlaylistPath(String url, String outputDir) async {
  final YoutubeExplode yt = YoutubeExplode();

  try {
    final Playlist playlist = await yt.playlists.get(url);
    final String playlistFolderName =
        cleanFromInvalidFileSystemChars(playlist.title);
    yt.close();

    final String playlistOutputDir = "$outputDir/$playlistFolderName";
    if (!Directory(playlistOutputDir).existsSync())
      Directory(playlistOutputDir).createSync();

    return playlistOutputDir;
  } catch (err) {
    yt.close();
    return null;
  }
}

Future<bool> startDownloadVideo(
    String url, DownloadType vidType, String outputDir) async {}

Future<bool> startDownloadPlaylist(
    String url, DownloadType vidType, String outputDir,
    {required Function(double progress) updateProgressFn}) async {
  final String? playlistOutputDir = await getPlaylistPath(url, outputDir);
  if (playlistOutputDir == null) return false;

  return true;
}
