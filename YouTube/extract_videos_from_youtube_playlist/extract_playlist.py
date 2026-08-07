import sys
import os
import yt_dlp

def extract_playlist_urls(playlist_url, output_file):
    # Ensure the file exists
    if not os.path.exists(output_file):
        with open(output_file, 'w', encoding='utf-8') as f:
            pass

    # yt-dlp options
    ydl_opts = {
        'extract_flat': 'in_playlist', # Don't download videos, just extract metadata
        'ignoreerrors': True,          # Skip unavailable/private videos silently
        'quiet': True,                 # Suppress console output
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            print(f"Fetching playlist data from: {playlist_url}")
            info = ydl.extract_info(playlist_url, download=False)
            
            if not info or 'entries' not in info:
                print("Error: The provided URL does not seem to be a valid playlist or could not be accessed.")
                return

            urls = []
            for entry in info['entries']:
                if entry and entry.get('url'):
                    # Some entries might only have the ID, we construct the full URL
                    url = entry.get('url')
                    if not url.startswith('http'):
                        url = f"https://www.youtube.com/watch?v={entry.get('id')}"
                    urls.append(url)

            with open(output_file, 'w', encoding='utf-8') as f:
                f.write('\n'.join(urls) + '\n')
            
            print(f"Successfully extracted {len(urls)} video URLs to {output_file}")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python extract_playlist.py <playlist_url> <output_file.txt>")
        sys.exit(1)
        
    playlist_url = sys.argv[1]
    output_file = sys.argv[2]
    extract_playlist_urls(playlist_url, output_file)
