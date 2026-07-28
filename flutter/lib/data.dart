class Chapter {
  final String name;
  final int startSeconds;
  final int endSeconds;

  const Chapter({
    required this.name,
    required this.startSeconds,
    required this.endSeconds,
  });
}

class Playlist {
  final String name;
  final String videoUrl;
  final List<Chapter> chapters;

  const Playlist({
    required this.name,
    required this.videoUrl,
    required this.chapters,
  });
}

int timeToSeconds(String t) {
  final parts = t.trim().split(':').map(int.parse).toList();
  if (parts.length == 2) return parts[0] * 60 + parts[1];
  if (parts.length == 3) return parts[0] * 3600 + parts[1] * 60 + parts[2];
  return 0;
}

// Timestamps sourced from: yt-player - Sheet1 (2).csv
const _juggleUrl = 'https://pub-7c85e81a76e54ba9ad1dd7277f5a1013.r2.dev/5%20Easy%20Juggling.mp4';

final List<Playlist> playlists = [
  Playlist(
    name: 'Ball Mastery List 1',
    videoUrl: _juggleUrl,
    chapters: [
      Chapter(name: 'Inside Outside Single Leg Two Touch', startSeconds: 55,  endSeconds: 106),
      Chapter(name: 'Inside Outside Single Leg One Touch', startSeconds: 106, endSeconds: 147),
      Chapter(name: 'Inside Outside Both Feet',            startSeconds: 147, endSeconds: 188),
      Chapter(name: 'Inside Inside (La Croqueta action)',  startSeconds: 188, endSeconds: 229),
      Chapter(name: 'Sole Rolls',                          startSeconds: 229, endSeconds: 269),
      Chapter(name: 'Pull and Push (V-Pattern)',           startSeconds: 269, endSeconds: 321),
      Chapter(name: 'Inside Sole (Tap Tap Roll)',          startSeconds: 321, endSeconds: 373),
      Chapter(name: 'Inside Outside Sole Single Leg',      startSeconds: 373, endSeconds: 418),
      Chapter(name: 'Inside Inside Outside',               startSeconds: 418, endSeconds: 468),
      Chapter(name: 'La Croqueta Outside',                 startSeconds: 468, endSeconds: 522),
    ],
  ),
  Playlist(
    name: '5 Easy Juggling',
    videoUrl: _juggleUrl,
    chapters: [
      Chapter(name: 'Toe Bounce',            startSeconds: 26,  endSeconds: 72),
      Chapter(name: 'Half Around The World', startSeconds: 72,  endSeconds: 119),
      Chapter(name: 'Crossover',             startSeconds: 119, endSeconds: 167),
      Chapter(name: 'Heel Juggling',         startSeconds: 167, endSeconds: 214),
      Chapter(name: 'Slap Juggling',         startSeconds: 214, endSeconds: 272),
    ],
  ),
];
