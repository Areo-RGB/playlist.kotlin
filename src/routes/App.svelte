<script lang="ts">
  import { onMount } from 'svelte';
  import YouTubePlayer from 'youtube-player';

  interface Chapter {
    name: string;
    startSeconds: number;
    endSeconds: number;
  }

  interface Playlist {
    name: string;
    videoId: string;
    chapters: Chapter[];
  }

  function timeToSeconds(t: string): number {
    const parts = t.trim().split(':').map(Number);
    if (parts.length === 2) return parts[0] * 60 + parts[1];
    if (parts.length === 3) return parts[0] * 3600 + parts[1] * 60 + parts[2];
    return 0;
  }

  function getMockData(): Playlist[] {
    return [
      {
        name: 'Ball Mastery List 1',
        videoId: 'dRS5EgJp-98',
        chapters: [
          { name: 'Inside Outside Single Leg Two Touch', startSeconds: timeToSeconds('0:55'), endSeconds: timeToSeconds('1:46') },
          { name: 'Inside Outside Single Leg One Touch', startSeconds: timeToSeconds('1:46'), endSeconds: timeToSeconds('2:27') },
          { name: 'Inside Outside Both Feet', startSeconds: timeToSeconds('2:27'), endSeconds: timeToSeconds('3:08') },
          { name: 'Inside Inside (La Croqueta action)', startSeconds: timeToSeconds('3:08'), endSeconds: timeToSeconds('3:49') },
          { name: 'Sole Rolls', startSeconds: timeToSeconds('3:49'), endSeconds: timeToSeconds('4:29') },
          { name: 'Pull and Push (V-Pattern)', startSeconds: timeToSeconds('4:29'), endSeconds: timeToSeconds('5:21') },
          { name: 'Inside Sole (Tap Tap Roll)', startSeconds: timeToSeconds('5:21'), endSeconds: timeToSeconds('6:13') },
          { name: 'Inside Outside Sole Single Leg', startSeconds: timeToSeconds('6:13'), endSeconds: timeToSeconds('6:58') },
          { name: 'Inside Inside Outside', startSeconds: timeToSeconds('6:58'), endSeconds: timeToSeconds('7:48') },
          { name: 'La Croqueta Outside', startSeconds: timeToSeconds('7:48'), endSeconds: timeToSeconds('8:42') },
        ],
      },
      {
        name: '5 Easy Juggling',
        videoId: 'xSpvUfTBWx8',
        chapters: [
          { name: 'Toe Bounce', startSeconds: timeToSeconds('0:26'), endSeconds: timeToSeconds('1:12') },
          { name: 'Half Around The World', startSeconds: timeToSeconds('1:12'), endSeconds: timeToSeconds('1:59') },
          { name: 'Crossover', startSeconds: timeToSeconds('1:59'), endSeconds: timeToSeconds('2:47') },
          { name: 'Heel Juggling', startSeconds: timeToSeconds('2:47'), endSeconds: timeToSeconds('3:34') },
          { name: 'Slap Juggling', startSeconds: timeToSeconds('3:34'), endSeconds: timeToSeconds('4:32') },
        ],
      },
    ];
  }

  let playlists = $state<Playlist[]>([]);
  let activeIndex = $state(0);
  let chapterIndex = $state(0);
  let isPlaying = $state(false);
  let isLooping = $state(false);
  let isSlowMotion = $state(false);
  let isFullScreen = $state(false);
  let sidebarOpen = $state(false);
  let menuOpen = $state(false);

  let activePlaylist = $derived(playlists[activeIndex]);
  let chapters = $derived(activePlaylist?.chapters ?? []);
  let videoId = $derived(activePlaylist?.videoId ?? '');
  let playlistName = $derived(activePlaylist?.name ?? 'Loading…');

  let playerElem: HTMLDivElement | null = $state(null);
  let player: any = null;
  let interval: any = null;

  onMount(() => {
    playlists = getMockData();
    document.addEventListener('fullscreenchange', () => {
      isFullScreen = !!document.fullscreenElement;
    });

    return () => {
      if (interval) clearInterval(interval);
      if (player) player.destroy();
    };
  });

  $effect(() => {
    if (playerElem && videoId) {
      if (player) {
        if (isPlaying) {
          player.loadVideoById(videoId);
        } else {
          player.cueVideoById(videoId);
        }
      } else {
        player = YouTubePlayer(playerElem, {
          videoId,
          width: '100%',
          height: '100%',
          playerVars: {
            playsinline: 1,
            modestbranding: 1,
            rel: 0,
            controls: 0,
            disablekb: 1,
            fs: 0,
            iv_load_policy: 3,
            autoplay: 0,
          },
        });

        player.on('ready', () => {
          if (chapters.length > chapterIndex) {
            player.seekTo(chapters[chapterIndex].startSeconds, true);
          }
        });

        player.on('stateChange', (e: any) => {
          isPlaying = e.data === 1;
        });
      }
    }
  });

  $effect(() => {
    if (player) {
      player.setPlaybackRate(isSlowMotion ? 0.5 : 1);
    }
  });

  $effect(() => {
    if (interval) clearInterval(interval);
    interval = setInterval(async () => {
      if (player && isPlaying && chapters[chapterIndex]) {
        try {
          const currentTime = await player.getCurrentTime();
          const currentCh = chapters[chapterIndex];
          if (currentTime >= currentCh.endSeconds) {
            if (isLooping) {
              player.seekTo(currentCh.startSeconds, true);
            } else if (chapterIndex + 1 < chapters.length) {
              chapterIndex++;
              const nextCh = chapters[chapterIndex];
              if (nextCh) {
                player.seekTo(nextCh.startSeconds, true);
                player.playVideo();
              }
            } else {
              player.pauseVideo();
            }
          }
        } catch (err) {}
      }
    }, 500);
  });

  function jumpTo(i: number) {
    chapterIndex = i;
    sidebarOpen = false;
    if (player && chapters[i]) {
      player.seekTo(chapters[i].startSeconds, true);
      player.playVideo();
    }
  }

  function togglePlay() {
    if (!player) {
      isPlaying = !isPlaying;
      return;
    }
    if (isPlaying) {
      player.pauseVideo();
    } else {
      player.playVideo();
    }
  }

  function toggleSlowMotion() {
    isSlowMotion = !isSlowMotion;
  }

  function selectPlaylist(i: number) {
    activeIndex = i;
    chapterIndex = 0;
    menuOpen = false;
    if (player && playlists[i]) {
      const nextVid = playlists[i].videoId;
      const nextCh = playlists[i].chapters[0];
      if (isPlaying) {
        player.loadVideoById(nextVid, nextCh ? nextCh.startSeconds : 0);
      } else {
        player.cueVideoById(nextVid, nextCh ? nextCh.startSeconds : 0);
      }
    }
  }

  function toggleFullScreen() {
    if (!document.fullscreenElement) document.documentElement.requestFullscreen().catch(() => {});
    else document.exitFullscreen();
  }
</script>

<div id="rotate-overlay"
  class="fixed inset-0 z-[200] bg-black text-white flex-col items-center justify-center gap-4 text-center px-8"
  style="display:none">
  <p class="text-xl font-semibold">Please rotate your device</p>
  <p class="text-sm text-neutral-400">This app is optimised for landscape mode</p>
</div>

<div class="fixed inset-0 bg-black text-white flex flex-col overflow-hidden" style="font-family:sans-serif">

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

  <!-- Playlist drawer (slides in from LEFT) -->
  <aside
    class="absolute top-[52px] left-0 h-[calc(100%-52px)] w-[300px] bg-neutral-900 border-r border-neutral-800 z-40 flex flex-col overflow-hidden transition-transform duration-300 ease-in-out will-change-transform"
    style="transform: {menuOpen ? 'translateX(0)' : 'translateX(-100%)'}">
    <div class="px-4 py-3 border-b border-neutral-800 flex items-center justify-between shrink-0">
      <span class="text-xs font-bold uppercase tracking-widest text-neutral-400">Playlists</span>
      <button onclick={() => menuOpen = false}
        class="w-10 h-10 flex items-center justify-center rounded-full text-neutral-500 hover:text-white hover:bg-neutral-800 transition-colors focus:outline-none"
        aria-label="Close playlists">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
        </svg>
      </button>
    </div>
    <ul class="flex-1 overflow-y-auto overscroll-contain">
      {#each playlists as pl, i (i)}
        <li class="border-b border-neutral-800 last:border-b-0">
          <button onclick={() => selectPlaylist(i)}
            class="w-full flex items-center gap-3 px-4 py-3 text-left transition-colors group
              {activeIndex === i ? 'bg-neutral-800 border-l-2 border-l-white' : 'border-l-2 border-l-transparent hover:bg-neutral-800'}"
            aria-label="Select {pl.name}">
            <div class="w-20 h-12 shrink-0 bg-neutral-800 rounded overflow-hidden">
              <img src="https://img.youtube.com/vi/{pl.videoId}/mqdefault.jpg" alt=""
                loading="lazy"
                class="w-full h-full object-cover {activeIndex === i ? 'opacity-100' : 'opacity-70 group-hover:opacity-100'}" />
            </div>
            <span class="text-sm font-medium line-clamp-2 {activeIndex === i ? 'text-white' : 'text-neutral-300 group-hover:text-white'}">{pl.name}</span>
          </button>
        </li>
      {/each}
    </ul>
  </aside>

  <main class="flex-1 flex overflow-hidden relative">
    <div class="flex-1 relative bg-black min-w-0">
      <div bind:this={playerElem} class="w-full h-full"></div>
      <button onclick={togglePlay}
        class="absolute inset-0 w-full h-full z-30 bg-transparent focus:outline-none"
        aria-label="Toggle play/pause">
        {#if !isPlaying}
          <div class="absolute inset-0 flex items-center justify-center pointer-events-none">
            <div class="w-16 h-16 rounded-full bg-black/60 flex items-center justify-center">
              <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="white" stroke="none">
                <polygon points="5 3 19 12 5 21 5 3"/>
              </svg>
            </div>
          </div>
        {:else}
          <div class="absolute inset-0 flex items-center justify-center pointer-events-none">
            <div class="w-16 h-16 rounded-full bg-black/40 flex items-center justify-center">
              <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="white" stroke="none">
                <rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/>
              </svg>
            </div>
          </div>
        {/if}
      </button>
      {#if chapters.length > 0}
        <div class="absolute bottom-4 left-4 z-40 bg-black/60 backdrop-blur-sm px-3 py-1 rounded-full text-xs text-neutral-200 max-w-[60%] truncate pointer-events-none">
          {chapters[chapterIndex]?.name ?? ''}
        </div>
      {/if}
    </div>

    <!-- Chapter sidebar (slides in from RIGHT) -->
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
        {#each chapters as ch, i (i)}
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
