class Ac1869 < Formula
  desc "Terminal music player (run it with the 1869ac command)"
  homepage "https://github.com/mrpeng4/1869AC"
  url "https://github.com/mrpeng4/1869AC/archive/refs/tags/v1.3.tar.gz"
  sha256 "6cd466d4d54235e18eaf92b7ea6f4faf4728c474e2e6461d04e3e4a95f5d8320"
  version "1.3"

  depends_on :macos
  depends_on "python@3.12"

  def install
    libexec.install Dir["mrpeng-mac-original-donot-alter-ANYTHING/macOS-code/*"]

    (bin/"1869ac").write <<~SH
      #!/bin/bash
      set -e
      SRC="#{libexec}"
      DATA="$HOME/Library/Application Support/1869AC"
      VENV="$DATA/venv"
      PYTHON="#{Formula["python@3.12"].opt_bin}/python3.12"

      if [ ! -d "/Applications/VLC.app" ] && [ ! -d "$HOME/Applications/VLC.app" ]; then
        echo "VLC is required. Install it with: brew install --cask vlc"
        exit 1
      fi

      mkdir -p "$DATA"

      # Copy every app file (code, sounds, help text) into the user's folder,
      # except songs_path.py which holds the user's playlists
      for f in "$SRC"/*; do
        name="$(basename "$f")"
        if [ "$name" != "songs_path.py" ] && [ "$name" != "requirements.txt" ]; then
          install -m 644 "$f" "$DATA/$name"
        fi
      done

      # Preserve the user's playlists file
      if [ ! -f "$DATA/songs_path.py" ]; then
        install -m 644 "$SRC/songs_path.py" "$DATA/songs_path.py"
      fi

      # Set up private venv if missing or broken
      if ! "$VENV/bin/python" -c "import importlib.util, sys; sys.exit(0 if importlib.util.find_spec('vlc') and importlib.util.find_spec('pygame') else 1)" >/dev/null 2>&1; then
        echo "Setting up dependencies..."
        "$PYTHON" -m venv --clear "$VENV"
        "$VENV/bin/pip" install --quiet python-vlc pygame
      fi

      cd "$DATA"
      exec "$VENV/bin/python" main.py "$@"
    SH

    (bin/"1869ac").chmod 0755
  end

  def caveats
    <<~EOS
      1869ac requires VLC. If you don't have it installed:
        brew install --cask vlc

      Run the player with:
        1869ac

      Your playlists file lives in:
        ~/Library/Application Support/1869AC/songs_path.py
    EOS
  end

  test do
    assert_predicate bin/"1869ac", :executable?
  end
end
