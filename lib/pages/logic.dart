import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

enum YouTubeLinkType { video, playlist, unknown }

// 'Video' is both video and audio, while 'Audio' is audio-only.
enum DownloadType { Video, Audio }

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
      uri.pathSegments.contains('v') ||
      uri.pathSegments.contains('embed')) {
    return YouTubeLinkType.video;
  }

  // Check for playlist links
  if (uri.queryParameters.containsKey('list') ||
      uri.pathSegments.contains('playlist')) {
    return YouTubeLinkType.playlist;
  }

  return YouTubeLinkType.unknown;
}

// returns a boolean based on success.
Future<bool> downloadVideo(
    String url, DownloadType vidType, String outputDir) async {
  final YoutubeExplode yt = YoutubeExplode();

  try {
    final video = await yt.videos.get(url);
    final streamManifest = await yt.videos.streamsClient.getManifest(video.id);
    StreamInfo streamInfo;

    if (vidType == DownloadType.Video)
      streamInfo = streamManifest.muxed.withHighestBitrate();
    else
      streamInfo = streamManifest.audioOnly.withHighestBitrate();

    // Get the actual stream
    final stream = yt.videos.streamsClient.get(streamInfo);

    // Set the path
    final fileName = "${video.title}.${streamInfo.container.name}";
    final fullPath = "$outputDir/$fileName";

    // Open a file for writing and check if it already exists.
    final file = File(fullPath);
    if (file.existsSync()) {
      if (file.lengthSync() == streamInfo.size.totalBytes)
        return true;
      else
        file.deleteSync();
    }
    final fileStream = file.openWrite();

    // Pipe all the content of the stream into the file.
    await stream.pipe(fileStream);

    // Close the file.
    await fileStream.flush();
    await fileStream.close();
  } catch (_) {
    // Todo: log errors

    yt.close();
    return false;
  }

  yt.close();
  return true;
}

Future<bool> downloadPlaylist(
    String url, DownloadType vidType, String outputDir) async {
  final YoutubeExplode yt = YoutubeExplode();

  try {
    final playlist = await yt.playlists.get(url);
    final path = "$outputDir/${playlist.title}";
    Directory(path).createSync();

    await for (final video in yt.playlists.getVideos(playlist.id)) {
      final streamManifest =
          await yt.videos.streamsClient.getManifest(video.id);
      StreamInfo streamInfo;

      if (vidType == DownloadType.Video)
        streamInfo = streamManifest.muxed.withHighestBitrate();
      else
        streamInfo = streamManifest.audioOnly.withHighestBitrate();

      // Get the actual stream
      final stream = yt.videos.streamsClient.get(streamInfo);

      // Set the path
      final fileName = "${video.title}.${streamInfo.container.name}";
      final fullPath = "$path/$fileName";

      // Open a file for writing and check if it already exists.
      final file = File(fullPath);
      if (file.existsSync()) {
        if (file.lengthSync() == streamInfo.size.totalBytes)
          return true;
        else
          file.deleteSync();
      }

      final fileStream = file.openWrite();

      // Pipe all the content of the stream into the file.
      await stream.pipe(fileStream);

      // Close the file.
      await fileStream.flush();
      await fileStream.close();
    }
  } catch (_) {
    // Todo: log errors

    yt.close();
    return false;
  }

  yt.close();
  return true;
}
