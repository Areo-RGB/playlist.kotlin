<script lang="ts">
  import { onMount } from 'svelte';
  import YouTubePlayer from 'youtube-player';
  import { fetchVideoData } from './data';
  import type { Playlist } from './data';
  import type { YouTubePlayer as YTPlayer } from 'youtube-player/dist/types';

  let playlists = $state<Playlist[]>([]);
  let activeIndex = $state(0);
  let chapterIndex = $state(0);
  let player = $state<YTPlayer | null>(null);
  let isPlaying = $state(false);
  let isReady = $state(false);
  let isLooping = $state(false);
  let isSlowMotion = $state(false);
  let isFullScreen = $state(false);
  let sidebarOpen = $state(false);
  let menuOpen = $state(false);

  let activePlaylist = $derived(playlists[activeIndex]);
  let chapters = $derived(activePlaylist?.chapters ?? []);
  let videoId = $derived(activePlaylist?.videoId ?? '');
  let playlistName = $derived(activePlaylist?.name ?? 'Loading…');

  onMount(async () => {
    playlists = await fetchVideoData();
    document.addEventListener('fullscreenchange', () => {
      isFullScreen = !!document.fullscreenElement;
    });
  });

  $effect(() => {
    if (!videoId) return;
    setTimeout(() => {
      if (!player) {
        player = YouTubePlayer('yt-player', {
          videoId,
          width: '100%',
          height: '100%',
          playerVars: { playsinline: 1, modestbranding: 1, rel: 0, controls: 0, disablekb: 1, fs: 0, iv_load_policy: 3, autoplay: 0 },
        });
        player.on('ready', () => { isReady = true; player?.unMute(); });
        player.on('stateChange', (e) => { isPlaying = e.data === 1; });
      } else {
        if (isPlaying) {
          player.loadVideoById(videoId);
        } else {
          player.cueVideoById(videoId);
        }
      }
    }, 0);
  });

  $effect(() => {
    if (!player || chapters.length === 0) return;
    const iv = setInterval(async () => {
      try {
        const iframe = await player!.getIframe();
        const doc = iframe.contentDocument ?? iframe.contentWindow?.document;
        if (doc) {
          const hide = ['ytp-chrome-top','ytp-chrome-controls','ytp-gradient-top','ytp-gradient-bottom',
            'ytp-progress-bar','ytp-progress-bar-container','ytp-fullscreen-quick-actions',
            'ytp-fullscreen-metadata','ytp-cued-thumbnail-overlay','ytp-title','ytp-watermark',
            'ytp-impression-link','ytp-share-button','ytp-endscreen-element',
            'ytp-large-play-button','ytp-cued-thumbnail-overlay-image'];
          for (const c of hide) {
            const els = doc.getElementsByClassName(c);
            for (let i = 0; i < els.length; i++) (els[i] as HTMLElement).style.visibility = 'hidden';
          }
        }
      } catch {}
      const t = await player!.getCurrentTime();
      if (isLooping) {
        const ch = chapters[chapterIndex];
        if (t >= ch.endSeconds) player!.seekTo(ch.startSeconds, true);
      } else {
        let idx = chapters.length - 1;
        for (let i = 0; i < chapters.length; i++) {
          if (t >= chapters[i].startSeconds && t < chapters[i].endSeconds) { idx = i; break; }
        }
        chapterIndex = idx;
      }
    }, 500);
    return () => clearInterval(iv);
  });

  function jumpTo(i: number) {
    if (!player) return;
    chapterIndex = i;
    player.seekTo(chapters[i].startSeconds, true);
    player.playVideo();
    sidebarOpen = false;
  }

  function togglePlay() {
    if (!player) return;
    isPlaying ? player.pauseVideo() : player.playVideo();
  }

  function toggleSlowMotion() {
    if (!player) return;
    isSlowMotion = !isSlowMotion;
    player.setPlaybackRate(isSlowMotion ? 0.25 : 1);
    isSlowMotion ? player.mute() : player.unMute();
  }

  function selectPlaylist(i: number) {
    activeIndex = i;
    chapterIndex = 0;
    menuOpen = false;
  }

  function toggleFullScreen() {
    if (!document.fullscreenElement) document.documentElement.requestFullscreen().catch(() => {});
    else document.exitFullscreen();
  }
</script>

<!-- Portrait rotate overlay -->
<div id="rotate-overlay"
  class="fixed inset-0 z-[200] bg-black text-white flex-col items-center justify-center gap-4 text-center px-8"
  style="display:none">
  <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none"
    stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <rect x="4" y="2" width="16" height="20" rx="2" ry="2"/>
    <path d="M12 18h.01"/>
  </svg>
  <p class="text-xl font-semibold">Please rotate your device</p>
  <p class="text-sm text-neutral-400">This app is optimised for landscape mode</p>
</div>

<div class="fixed inset-0 bg-black text-white flex flex-col overflow-hidden" style="font-family:sans-serif">

  <!-- Header -->
  <header class="shrink-0 flex items-center justify-between px-5 py-2 bg-neutral-900 border-b border-neutral-800 z-30" style="min-height:52px">
    <h1 class="text-base font-bold tracking-tight truncate max-w-[50vw]">{playlistName}</h1>
    <div class="flex items-center gap-1">

      <button onclick={toggleSlowMotion}
        class="w-12 h-12 flex items-center justify-center rounded-full transition-colors focus:outline-none {isSlowMotion ? 'bg-neutral-700 text-white' : 'text-neutral-500 hover:text-white hover:bg-neutral-800'}"
        aria-label="Toggle slow motion">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M2 13a6 6 0 1 0 12 0 4 4 0 1 0-8 0 2 2 0 0 0 4 0"/>
          <circle cx="10" cy="13" r="8"/>
          <path d="M2 21h12c4.4 0 8-3.6 8-8V7a2 2 1 0 0-4 0v6"/>
          <path d="M18 3 19.1 5.2"/><path d="M22 3 20.9 5.2"/>
        </svg>
      </button>

      <button onclick={() => isLooping = !isLooping}
        class="w-12 h-12 flex items-center justify-center rounded-full transition-colors focus:outline-none {isLooping ? 'bg-neutral-700 text-white' : 'text-neutral-500 hover:text-white hover:bg-neutral-800'}"
        aria-label="Toggle loop">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/>
          <path d="M3 3v5h5"/>
          <path d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16"/>
          <path d="M16 16h5v5"/>
        </svg>
      </button>

      <button onclick={toggleFullScreen}
        class="w-12 h-12 flex items-center justify-center rounded-full transition-colors focus:outline-none {isFullScreen ? 'bg-neutral-700 text-white' : 'text-neutral-500 hover:text-white hover:bg-neutral-800'}"
        aria-label="Toggle fullscreen">
        {#if isFullScreen}
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M8 3v3a2 2 0 0 1-2 2H3"/><path d="M21 8h-3a2 2 0 0 1-2-2V3"/>
            <path d="M3 16h3a2 2 0 0 1 2 2v3"/><path d="M16 21v-3a2 2 0 0 1 2-2h3"/>
          </svg>
        {:else}
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M8 3H5a2 2 0 0 0-2 2v3"/><path d="M21 8V5a2 2 0 0 0-2-2h-3"/>
            <path d="M3 16v3a2 2 0 0 0 2 2h3"/><path d="M16 21h3a2 2 0 0 0 2-2v-3"/>
          </svg>
        {/if}
      </button>

      <button onclick={() => menuOpen = !menuOpen}
        class="w-12 h-12 flex items-center justify-center rounded-full transition-colors focus:outline-none {menuOpen ? 'bg-neutral-700 text-white' : 'text-neutral-500 hover:text-white hover:bg-neutral-800'}"
        aria-label="Open playlist menu">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/>
          <line x1="8" y1="18" x2="21" y2="18"/>
          <line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/>
          <line x1="3" y1="18" x2="3.01" y2="18"/>
        </svg>
      </button>

      <button onclick={() => sidebarOpen = !sidebarOpen}
        class="w-12 h-12 flex items-center justify-center rounded-full transition-colors focus:outline-none {sidebarOpen ? 'bg-neutral-700 text-white' : 'text-neutral-500 hover:text-white hover:bg-neutral-800'}"
        aria-label="Toggle chapters sidebar">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="3" y="3" width="18" height="18" rx="2"/><path d="M9 3v18"/>
          <path d="M13 8h4"/><path d="M13 12h4"/><path d="M13 16h4"/>
        </svg>
      </button>
    </div>
  </header>

  <!-- Playlist dropdown -->
  {#if menuOpen}
    <div class="absolute top-[52px] right-0 z-50 w-72 bg-neutral-900 border border-neutral-800 shadow-2xl">
      {#each playlists as pl, i}
        <button onclick={() => selectPlaylist(i)}
          class="w-full text-left px-5 py-4 text-sm transition-colors {activeIndex === i ? 'bg-neutral-800 text-white' : 'text-neutral-300 hover:bg-neutral-800'}">
          {pl.name}
        </button>
      {/each}
    </div>
  {/if}

  <!-- Body -->
  <main class="flex-1 flex overflow-hidden relative">

    <!-- Video area -->
    <div class="flex-1 relative bg-black min-w-0">
      <div id="yt-player" class="w-full h-full pointer-events-none"></div>

      {#if !isPlaying && videoId}
        <img src="https://i.ytimg.com/vi/{videoId}/hqdefault.jpg" alt="thumbnail"
          class="absolute inset-0 w-full h-full object-cover z-20 pointer-events-none" />
      {/if}

      <button onclick={togglePlay}
        class="absolute inset-0 w-full h-full z-30 bg-transparent focus:outline-none"
        aria-label="Toggle play/pause"></button>

      {#if chapters.length > 0}
        <div class="absolute bottom-4 left-4 z-40 bg-black/60 backdrop-blur-sm px-3 py-1 rounded-full text-xs text-neutral-200 max-w-[60%] truncate pointer-events-none">
          {chapters[chapterIndex]?.name ?? ''}
        </div>
      {/if}
    </div>

    <!-- Chapter sidebar (slides in from right) -->
    <aside
      class="absolute top-0 right-0 h-full w-[300px] bg-neutral-900 border-l border-neutral-800 z-40 flex flex-col overflow-hidden transition-transform duration-300 ease-in-out will-change-transform"
      style="transform: {sidebarOpen ? 'translateX(0)' : 'translateX(100%)'}">

      <div class="px-4 py-3 border-b border-neutral-800 flex items-center justify-between shrink-0">
        <span class="text-xs font-bold uppercase tracking-widest text-neutral-400">Chapters</span>
        <button onclick={() => sidebarOpen = false}
          class="w-10 h-10 flex items-center justify-center rounded-full text-neutral-500 hover:text-white hover:bg-neutral-800 transition-colors focus:outline-none"
          aria-label="Close chapters">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
          </svg>
        </button>
      </div>

      <ul class="flex-1 overflow-y-auto overscroll-contain">
        {#each chapters as ch, i}
          <li class="border-b border-neutral-800 last:border-b-0">
            <button onclick={() => jumpTo(i)}
              class="w-full flex items-center gap-3 px-4 py-3 text-left transition-colors group
                {chapterIndex === i ? 'bg-neutral-800 border-l-2 border-l-white' : 'border-l-2 border-l-transparent hover:bg-neutral-800'}"
              aria-label="Jump to {ch.name}">
              <div class="w-20 h-12 shrink-0 bg-neutral-800 rounded overflow-hidden">
                <img src="https://img.youtube.com/vi/{videoId}/mqdefault.jpg" alt=""
                  loading="lazy"
                  class="w-full h-full object-cover {chapterIndex === i ? 'opacity-100' : 'opacity-70 group-hover:opacity-100'}" />
              </div>
              <span class="text-sm font-medium line-clamp-2 {chapterIndex === i ? 'text-white' : 'text-neutral-300 group-hover:text-white'}">{ch.name}</span>
            </button>
          </li>
        {/each}
      </ul>
    </aside>

  </main>
</div>
