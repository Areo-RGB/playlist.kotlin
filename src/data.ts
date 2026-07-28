export interface Chapter {
  name: string;
  startSeconds: number;
  endSeconds: number;
}

export interface Playlist {
  name: string;
  videoId: string;
  chapters: Chapter[];
}

const SHEET_ID = import.meta.env.VITE_SHEET_ID ?? '';

export async function fetchVideoData(): Promise<Playlist[]> {
  if (!SHEET_ID) return getMockData();
  try {
    const url = `https://docs.google.com/spreadsheets/d/${SHEET_ID}/gviz/tq?tqx=out:json`;
    const res = await fetch(url);
    const text = await res.text();
    const json = JSON.parse(text.substring(47).slice(0, -2));
    const rows: string[][] = json.table.rows.map((r: any) => r.c.map((c: any) => c?.v ?? ''));
    const playlists: Record<string, Playlist> = {};
    for (const [plName, vidId, chName, start, end] of rows) {
      if (!playlists[plName]) playlists[plName] = { name: plName, videoId: vidId, chapters: [] };
      playlists[plName].chapters.push({ name: chName, startSeconds: Number(start), endSeconds: Number(end) });
    }
    return Object.values(playlists);
  } catch {
    return getMockData();
  }
}

function getMockData(): Playlist[] {
  return [{
    name: 'Demo Playlist',
    videoId: 'dQw4w9WgXcQ',
    chapters: [
      { name: 'Intro', startSeconds: 0, endSeconds: 30 },
      { name: 'Main', startSeconds: 30, endSeconds: 90 },
      { name: 'Outro', startSeconds: 90, endSeconds: 212 },
    ],
  }];
}
