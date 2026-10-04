class Ac1869 < Formula
  desc "Terminal music player (run it with the 1869ac command)"
  homepage "https://github.com/mrpeng4/1869AC"
  url "https://github.com/mrpeng4/1869AC/archive/refs/tags/v1.1.tar.gz"
  sha256 "2abf28df7ec26d2051b5d6713097992ce1debf36812d7a7a22e7058938c8a417"

  depends_on :macos
  depends_on "python@3.12"

  def install
    # Install files into libexec from their respective source subdirectories/folders.
    # Adjust the relative path prefixes (e.g., "src/main.py" or "assets/...") if your folders are named differently.
    libexec.install Dir["src/*"], Dir["assets/*"] rescue libexec.install Dir["*"]

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

      # Copy all core files from libexec into the user's data directory
      cp -Rf "$SRC/." "$DATA/"

      # Preserve user's existing playlists file if present
      if [ -f "$DATA/songs_path.py.bak" ]; then
        mv "$DATA/songs_path.py.bak" "$DATA/songs_path.py"
      fi

      # Setup private venv if missing or python environment changed
      if ! "$VENV/bin/python" -c "import importlib.util, sys; sys.exit(0 if importlib.util.find_spec('vlc') and importlib.util.find_spec('pygame') else 1)" >/dev/null 2>&1; then
        echo "Setting up dependencies..."
        "$PYTHON" -m venv --clear "$VENV"
        "$VENV/bin/pip" install --quiet python-vlc pygame
      fi

      cd "$DATA"
      exec "$VENV/bin/python" main.py "$@"
    SH

    chmod 0755, bin/"1869ac"
  end

  def caveats
    <<~EOS
      1869ac requires VLC. If you don't have it installed:
        brew install --cask vlc

      Run the player with:
        1869ac

      Your settings and playlists live in:
        ~/Library/Application Support/1869AC/
    EOS
  end

  test do
    assert_predicate bin/"1869ac", :executable?
  end
end
