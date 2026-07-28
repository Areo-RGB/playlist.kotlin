# Flutter Android — Playlist Player

Native Flutter Android rewrite of the Svelte playlist player. No YouTube — uses direct MP4 URLs.

## Features
- Video playback via `video_player` (network MP4)
- Chapter timestamps from `yt-player - Sheet1 (2).csv`
- Playlist drawer (slides from left)
- Chapter sidebar (slides from right)
- Tap-to-play/pause overlay
- Slow motion (0.5×) toggle
- Chapter loop toggle
- Auto-advance chapters
- Landscape-forced, immersive fullscreen
- Wakelock (screen stays on)

## Video URL
```
https://pub-7c85e81a76e54ba9ad1dd7277f5a1013.r2.dev/5%20Easy%20Juggling.mp4
```

## Run
```bash
cd flutter
flutter pub get
flutter run
```

## Structure
```
flutter/
  lib/
    main.dart          # entry point, landscape lock
    app.dart           # MaterialApp wrapper
    data.dart          # playlists + CSV timestamps
    player_screen.dart # full UI
  pubspec.yaml
```
