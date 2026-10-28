# Use official TeX Live base image
FROM texlive/texlive:latest

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# Install system dependencies as root
# Use --no-install-recommends to avoid pulling in unnecessary packages
# Fix dpkg if interrupted, then install dependencies
RUN dpkg --configure -a || true && \
  apt-get update && \
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
  fonts-firacode \
  fonts-hack \
  fonts-roboto \
  fonts-jetbrains-mono \
  poppler-utils \
  qpdf \
  # Chromium and its dependencies (libasound2t64 already in base image)
  chromium \
  libnss3 \
  libatk1.0-0 \
  libatk-bridge2.0-0 \
  libcups2 \
  libdrm2 \
  libxkbcommon0 \
  libxcomposite1 \
  libxdamage1 \
  libxfixes3 \
  libxrandr2 \
  libgbm1 \
  && rm -rf /var/lib/apt/lists/*

# Install a pinned pandoc release; distro pandoc versions vary between bases
ARG PANDOC_VERSION=3.11
RUN wget -qO /tmp/pandoc.deb \
  "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-$(dpkg --print-architecture).deb" && \
  dpkg -i /tmp/pandoc.deb && \
  rm /tmp/pandoc.deb

# Fonts not packaged by Debian
RUN mkdir -p /usr/share/fonts/truetype/special-gothic && \
  wget -qO /usr/share/fonts/truetype/special-gothic/SpecialGothicCondensedOne-Regular.ttf \
  https://github.com/google/fonts/raw/main/ofl/specialgothiccondensedone/SpecialGothicCondensedOne-Regular.ttf && \
  # The base image ships a populated /var/cache/fontconfig; fc-cache's clean
  # pass chokes on those stale cache files ("invalid cache file" -> "fc-cache:
  # failed"). Clearing it first lets fc-cache regenerate from scratch cleanly.
  rm -rf /var/cache/fontconfig/* && \
  fc-cache -f

# Install Node.js 24.x LTS
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
  apt-get install -y nodejs && \
  npm install -g npm

# Create a version-agnostic symlink to the TeX Live binaries.
# The base image's TeX Live year (e.g. 2024, 2025, ...) changes over time,
# so we resolve the versioned bin dir at build time and expose it at a fixed path.
RUN ln -s "$(dirname "$(find /usr/local/texlive -maxdepth 3 -name 'x86_64-linux' -type d | head -n1)")/x86_64-linux" /usr/local/texlive/bin

# Beamer theme (RosePineMoon) into the local TeX tree
COPY texmf/ /tmp/texmf/
RUN cp -r /tmp/texmf/. "$(/usr/local/texlive/bin/kpsewhich -var-value TEXMFLOCAL)/" && \
  rm -rf /tmp/texmf && \
  /usr/local/texlive/bin/mktexlsr

# Prebuild the luaotfload font-name database so LuaLaTeX doesn't rebuild it on
# every fresh container. The cache must stay writable by any UID: luaotfload
# refuses to run with a read-only TEXMFVAR, and manage_docker.sh runs as the
# host user's UID.
ENV TEXMFVAR=/var/cache/texlive/texmf-var
ENV TEXMFCACHE=/var/cache/texlive/texmf-var
RUN mkdir -p "$TEXMFVAR" && \
  /usr/local/texlive/bin/luaotfload-tool --update --force && \
  chmod -R a+rwX /var/cache/texlive

# Create non-root user and allow sudo without password
# Check if user with UID 1000 exists, if so use it, otherwise create appuser
RUN if id -u 1000 >/dev/null 2>&1; then \
      EXISTING_USER=$(id -un 1000); \
      echo "$EXISTING_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$EXISTING_USER; \
      chown -R $EXISTING_USER:$(id -gn 1000) /app; \
    else \
      useradd -m -s /bin/bash -u 1000 -g 1000 appuser && \
      echo "appuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/appuser && \
      chown -R appuser:appuser /app; \
    fi

# Switch to non-root user (Docker sets HOME automatically)
USER 1000

# Use system Chromium; skip Puppeteer's browser download during npm install
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Set up Python virtual environment and npm in one consolidated layer
RUN python3 -m venv ~/venv && \
  ~/venv/bin/pip install --no-cache-dir \
  pandocfilters==1.5.1 \
  pygments==2.21.0 \
  numpy==2.5.4 \
  pandas==3.1.0 \
  scipy==1.18.1 \
  matplotlib==3.11.2 \
  seaborn==0.13.2 \
  openpyxl==3.1.5 \
  joblib==1.6.0 \
  jinja2==3.1.6 \
  nbformat==5.11.1 \
  ipython==9.17.1 \
  pyyaml==6.0.3 && \
  mkdir -p ~/.npm-global && \
  npm config set prefix ~/.npm-global && \
  npm install -g --no-progress \
  puppeteer@25.16.0 \
  @mermaid-js/mermaid-cli@12.0.0

# Custom Pygments lexers and styles (pseudocode, rosepinemoon) for minted
COPY --chown=1000:1000 python/custom_pygments/ /tmp/custom_pygments/
RUN ~/venv/bin/pip install --no-cache-dir /tmp/custom_pygments && rm -rf /tmp/custom_pygments

# Bake in manual-pipeline with its Node dependencies preinstalled. Projects use it
# by setting PIPELINE_DIR := $(MANUAL_PIPELINE_DIR) in their manual/Makefile.
# BuildKit resolves the ref on every build, so a rebuild picks up new commits.
ARG MANUAL_PIPELINE_REF=main
ADD --chown=1000:1000 https://github.com/Derrekito/manual-pipeline.git#${MANUAL_PIPELINE_REF} /opt/manual-pipeline
RUN cd /opt/manual-pipeline && npm ci --no-progress
ENV MANUAL_PIPELINE_DIR=/opt/manual-pipeline
ENV MERMAID_BIN=/home/texlive/.npm-global/bin/mmdc

# Set PATH for venv, global Node.js binaries, and TeX Live
# Note: Use full paths since ENV doesn't expand variables at runtime
ENV PATH="/home/texlive/venv/bin:/home/texlive/.npm-global/bin:/usr/local/texlive/bin:${PATH}"

CMD ["bash"]
HEALTHCHECK CMD latexmk --version || exit 1
