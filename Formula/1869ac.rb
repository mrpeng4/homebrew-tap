class Ac1869 < Formula
  desc "Terminal music player (run it with the 1869ac command)"
  homepage "https://github.com/mrpeng4/1869AC"
  url "https://github.com/mrpeng4/1869AC/archive/refs/tags/v1.2.tar.gz"
  sha256 "845b495cd3dae00a640181c5fc8560509a3a969f14845da110efeba318e1e008"

  depends_on :macos
  depends_on "python@3.12"

  def install
    # Pulls the files from your nested macOS-code directory
    mac_code_dir = "mrpeng-mac-original-donot-alter-ANYTHING/macOS-code"

    libexec.install Dir["#{mac_code_dir}/*"]

    # This ensures the terminal command you type to run the player is exactly `1869ac`
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

      # Copy/Update application code into user's Application Support directory
      install -m 644 "$SRC/main.py" "$DATA/main.py"
      install -m 644 "$SRC/widgets.py" "$DATA/widgets.py"
      install -m 644 "$SRC/import_system.py" "$DATA/import_system.py"

      if [ -f "$SRC/turning_pages-ui-toggle-off-confirmation-608627.mp3" ]; then
        install -m 644 "$SRC/turning_pages-ui-toggle-off-confirmation-608627.mp3" "$DATA/turning_pages-ui-toggle-off-confirmation-608627.mp3"
      fi

      # Preserve user's playlists file
      if [ ! -f "$DATA/songs_path.py" ] && [ -f "$SRC/songs_path.py" ]; then
        install -m 644 "$SRC/songs_path.py" "$DATA/songs_path.py"
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

      Your playlists file lives in:
        ~/Library/Application Support/1869AC/songs_path.py
    EOS
  end

  test do
    assert_predicate bin/"1869ac", :executable?
  end
end
