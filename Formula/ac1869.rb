class Ac1869 < Formula
  desc "Terminal music player (run it with the 1869ac command)"
  homepage "https://github.com/mrpeng4/1869AC"
  url "https://github.com/mrpeng4/1869AC/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_SHA256_OF_THE_TARBALL"

  depends_on :macos
  depends_on "python@3.12"

  def install
    libexec.install "main.py", "widgets.py", "songs_path.py",
                    "turning_pages-ui-toggle-off-confirmation-608627.mp3"

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

      # Refresh the app code on every launch (so brew upgrades take effect)...
      install -m 644 "$SRC/main.py" "$DATA/main.py"
      install -m 644 "$SRC/widgets.py" "$DATA/widgets.py"
      install -m 644 "$SRC/turning_pages-ui-toggle-off-confirmation-608627.mp3" "$DATA/turning_pages-ui-toggle-off-confirmation-608627.mp3"

      # ...but never overwrite the user's songs_path.py
      if [ ! -f "$DATA/songs_path.py" ]; then
        install -m 644 "$SRC/songs_path.py" "$DATA/songs_path.py"
      fi

      # One-time (or after a python upgrade) private environment setup
      if ! "$VENV/bin/python" -c "import importlib.util, sys; sys.exit(0 if importlib.util.find_spec('vlc') and importlib.util.find_spec('pygame') else 1)" >/dev/null 2>&1; then
        echo "First run: setting things up (one time only)..."
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
      1869ac needs VLC. If you don't have it:
        brew install --cask vlc

      Run it with:
        1869ac

      Your playlists live in:
        ~/Library/Application Support/1869AC/songs_path.py
    EOS
  end

  test do
    assert_predicate bin/"1869ac", :executable?
  end
end
