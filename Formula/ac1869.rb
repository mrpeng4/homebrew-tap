class Ac1869 < Formula
  desc "Terminal music player (run it with the 1869ac command)"
  homepage "https://github.com/1869AC/1869AC"
  url "https://github.com/1869AC/1869AC/archive/refs/tags/v2.1.tar.gz"
  sha256 "9affbee6d293723183d9da92128e5ae6af0a150cd3cc4b885e29105a07085555"

  depends_on "python@3.12"

  def install
    libexec.install Dir["*.py"],
                    Dir["*.txt"],
                    (Dir["*.json"] - Dir["package*.json"]),
                    Dir["*.mp3"],
                    Dir["*.wav"]

    (bin/"1869ac").write <<~SH
      #!/bin/bash
      set -e
      SRC="#{libexec}"
      PYTHON="#{Formula["python@3.12"].opt_bin}/python3.12"

      # OS-specific data folder and VLC check
      if [ "$(uname)" = "Darwin" ]; then
        DATA="$HOME/Library/Application Support/1869AC"
        if [ ! -d "/Applications/VLC.app" ] && [ ! -d "$HOME/Applications/VLC.app" ]; then
          echo "VLC is required. Install it with: brew install --cask vlc"
          exit 1
        fi
      else
        DATA="${XDG_DATA_HOME:-$HOME/.local/share}/1869AC"
        if ! command -v vlc >/dev/null 2>&1; then
          echo "VLC is required. Install it with: sudo apt install vlc"
          exit 1
        fi
      fi

      VENV="$DATA/venv"
      mkdir -p "$DATA"

      # Files that belong to the user and must never be overwritten
      USER_FILES="songs_path.py last_played.json"

      # Refresh app files (code, sounds, help text) on every launch
      for f in "$SRC"/*; do
        name="$(basename "$f")"
        case " $USER_FILES requirements.txt " in
          *" $name "*) continue ;;
        esac
        install -m 644 "$f" "$DATA/$name"
      done

      # Seed the user's files only if they don't exist yet
      for name in $USER_FILES; do
        if [ ! -f "$DATA/$name" ] && [ -f "$SRC/$name" ]; then
          install -m 644 "$SRC/$name" "$DATA/$name"
        fi
      done

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
    if OS.mac?
      <<~EOS
        1869ac requires VLC. If you don't have it installed:
          brew install --cask vlc

        Run the player with:
          1869ac

        Your playlists and last-played data live in:
          ~/Library/Application Support/1869AC/
      EOS
    else
      <<~EOS
        1869ac requires VLC. If you don't have it installed:
          sudo apt install vlc

        Run the player with:
          1869ac

        Your playlists and last-played data live in:
          ~/.local/share/1869AC/

        On WSL, audio needs WSLg (Windows 11, or Windows 10 with an updated WSL).
      EOS
    end
  end

  test do
    assert_predicate bin/"1869ac", :executable?
  end
end
