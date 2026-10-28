#!/usr/bin/env bash
# Provision a Debian VM with the same toolchain as the Docker image.
# Runs as root (Vagrant's default for shell provisioners). Safe to re-run.
#
# Keep the versions below in sync with ../Dockerfile.
set -euo pipefail

VM_USER="${VM_USER:-vagrant}"
TEXLIVE_SCHEME="${TEXLIVE_SCHEME:-scheme-full}"
TEXLIVE_MIRROR="${TEXLIVE_MIRROR:-https://mirror.ctan.org/systems/texlive/tlnet}"
NODE_MAJOR=24
PANDOC_VERSION=3.11
FIRACODE_VERSION=6.2
PANDOCFILTERS_VERSION=1.5.1
PYGMENTS_VERSION=2.21.0
PUPPETEER_VERSION=25.16.0
MERMAID_CLI_VERSION=12.0.0
MANUAL_PIPELINE_REPO="${MANUAL_PIPELINE_REPO:-https://github.com/Derrekito/manual-pipeline.git}"
MANUAL_PIPELINE_REF="${MANUAL_PIPELINE_REF:-main}"

export DEBIAN_FRONTEND=noninteractive
USER_HOME="$(getent passwd "$VM_USER" | cut -d: -f6)"

echo "==> Installing system packages"
apt-get update
apt-get install -y --no-install-recommends \
  curl \
  wget \
  git \
  make \
  imagemagick \
  jq \
  perl \
  python3 \
  python3-pip \
  python3-venv \
  fontconfig \
  unzip \
  sudo \
  ca-certificates \
  fonts-liberation \
  gnupg \
  chromium
rm -rf /var/lib/apt/lists/*

echo "==> Installing pandoc $PANDOC_VERSION"
if [ "$(pandoc --version 2>/dev/null | head -n1 | awk '{print $2}')" != "$PANDOC_VERSION" ]; then
  wget -qO /tmp/pandoc.deb \
    "https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/pandoc-$PANDOC_VERSION-1-$(dpkg --print-architecture).deb"
  dpkg -i /tmp/pandoc.deb
  rm /tmp/pandoc.deb
fi

echo "==> Installing TeX Live ($TEXLIVE_SCHEME)"
if [ ! -x /usr/local/texlive/bin/tex ]; then
  tl_tmp="$(mktemp -d)"
  curl -fsSL "$TEXLIVE_MIRROR/install-tl-unx.tar.gz" | tar -xz -C "$tl_tmp" --strip-components=1
  cat > "$tl_tmp/texlive.profile" <<EOF
selected_scheme $TEXLIVE_SCHEME
instopt_adjustpath 0
tlpdbopt_autobackup 0
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
EOF
  "$tl_tmp/install-tl" --no-interaction --profile "$tl_tmp/texlive.profile" --repository "$TEXLIVE_MIRROR"
  rm -rf "$tl_tmp"
  # Same version-agnostic path the Docker image exposes
  ln -sfn "$(find /usr/local/texlive -mindepth 3 -maxdepth 3 -path '*/bin/*-linux' -type d | head -n1)" /usr/local/texlive/bin
else
  echo "    already installed, skipping"
fi

echo "==> Installing FiraCode fonts"
if [ ! -d /usr/share/fonts/truetype/firacode ]; then
  mkdir -p /usr/share/fonts/truetype/firacode
  wget -qO /tmp/firacode.zip \
    "https://github.com/tonsky/FiraCode/releases/download/$FIRACODE_VERSION/Fira_Code_v$FIRACODE_VERSION.zip"
  unzip -oj /tmp/firacode.zip "ttf/*" -d /usr/share/fonts/truetype/firacode
  rm /tmp/firacode.zip
  fc-cache -f
fi

echo "==> Installing Node.js $NODE_MAJOR.x"
if ! node --version 2>/dev/null | grep -q "^v$NODE_MAJOR\."; then
  curl -fsSL "https://deb.nodesource.com/setup_$NODE_MAJOR.x" | bash -
  apt-get install -y nodejs
  rm -rf /var/lib/apt/lists/*
fi

echo "==> Configuring environment"
cat > /etc/profile.d/latex-env.sh <<'EOF'
export PUPPETEER_SKIP_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
export PATH="$HOME/venv/bin:$HOME/.npm-global/bin:/usr/local/texlive/bin:$PATH"
# Start in the mounted documents directory, like the Docker WORKDIR
[ "$PWD" = "$HOME" ] && [ -d /app ] && cd /app
EOF
echo "$VM_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$VM_USER"
chmod 0440 "/etc/sudoers.d/$VM_USER"

echo "==> Installing Python venv and npm packages for $VM_USER"
sudo -u "$VM_USER" -H bash -s <<EOF
set -euo pipefail
export PUPPETEER_SKIP_DOWNLOAD=true
python3 -m venv ~/venv
~/venv/bin/pip install --no-cache-dir \
  pandocfilters==$PANDOCFILTERS_VERSION \
  pygments==$PYGMENTS_VERSION
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
npm install -g --no-progress \
  puppeteer@$PUPPETEER_VERSION \
  @mermaid-js/mermaid-cli@$MERMAID_CLI_VERSION
EOF

echo "==> Installing manual-pipeline ($MANUAL_PIPELINE_REF)"
install -d -o "$VM_USER" -g "$VM_USER" /opt/manual-pipeline
sudo -u "$VM_USER" -H bash -s <<EOF
set -euo pipefail
export PUPPETEER_SKIP_DOWNLOAD=true
if [ -d /opt/manual-pipeline/.git ]; then
  git -C /opt/manual-pipeline fetch --quiet origin "$MANUAL_PIPELINE_REF"
  git -C /opt/manual-pipeline checkout --quiet --force FETCH_HEAD
else
  git clone --quiet "$MANUAL_PIPELINE_REPO" /opt/manual-pipeline
  git -C /opt/manual-pipeline checkout --quiet "$MANUAL_PIPELINE_REF"
fi
cd /opt/manual-pipeline && npm ci --no-progress
EOF
echo 'export MANUAL_PIPELINE_DIR=/opt/manual-pipeline' > /etc/profile.d/manual-pipeline.sh

echo "==> Done"
PATH="$USER_HOME/venv/bin:$USER_HOME/.npm-global/bin:/usr/local/texlive/bin:$PATH" \
  bash -c 'pdflatex --version | head -n1; pandoc --version | head -n1; node --version; mmdc --version; pygmentize -V'
