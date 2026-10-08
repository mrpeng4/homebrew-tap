class Ac1869 < Formula
  desc "Terminal music player (run it with the 1869ac command)"
  homepage "https://github.com/mrpeng4/1869AC"
  url "https://github.com/mrpeng4/1869AC/archive/refs/tags/v1.4.tar.gz"
  sha256 "0c91495779e49214e2cad5e394533f13a920494725912d55d6f3e69046d46612"
  version "1.4"

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
    <<~EOS
      1869ac requires VLC. If you don't have it installed:
        brew install --cask vlc

      Run the player with:
        1869ac

      Your playlists and last-played data live in:
        ~/Library/Application Support/1869AC/
    EOS
  end

  test do
    assert_predicate bin/"1869ac", :executable?
  end
end
