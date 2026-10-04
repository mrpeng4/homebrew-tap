class Ac1869 < Formula
  desc "Terminal music player (run it with the 1869ac command)"
  homepage "https://github.com/mrpeng4/1869AC"
  url "https://github.com/mrpeng4/1869AC/archive/refs/tags/v1.2.tar.gz"
  sha256 "845b495cd3dae00a640181c5fc8560509a3a969f14845da110efeba318e1e008"
  version "1.2"

  depends_on :macos
  depends_on "python@3.12"

  def install
    # Pull the app files from the macOS-code folder of the 1869AC repo
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

      # Copy app files into the user's folder on every launch
      for f in main.py widgets.py import_system.py turning_pages-ui-toggle-off-confirmation-608627.mp3; do
        install -m 644 "$SRC/$f" "$DATA/$f"
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
