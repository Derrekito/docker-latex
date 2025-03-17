# Use official TeX Live base image
FROM texlive/texlive:latest

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /app

# Install basic utilities, jq, Puppeteer dependencies, Chromium, fontconfig, and unzip
RUN apt-get update && apt-get install -y \
  curl \
  wget \
  git \
  make \
  jq \
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
  libasound2 \
  perl \
  pandoc \
  python3 \
  python3-pip \
  python3-venv \
  chromium \
  fontconfig \
  unzip \
  && rm -rf /var/lib/apt/lists/*

# Install all FiraCode font variants from zip file
RUN mkdir -p /usr/share/fonts/truetype/firacode && \
  wget -O /tmp/Fira_Code_v6.2.zip \
  https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip && \
  unzip -j /tmp/Fira_Code_v6.2.zip "ttf/*" -d /usr/share/fonts/truetype/firacode && \
  rm /tmp/Fira_Code_v6.2.zip && \
  fc-cache -f -v

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
  apt-get install -y nodejs && \
  npm install -g npm

# Create and activate a Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies in the virtual environment
RUN pip3 install --no-cache-dir \
  pandocfilters \
  pygments

# Install Node.js dependencies
RUN npm install --global --no-progress \
  puppeteer@24.4.0 \
  @mermaid-js/mermaid-cli@11.4.2

# Configure Puppeteer to use the system Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Ensure TeX Live binaries are in PATH (already set in base image, but confirming)
ENV PATH="/usr/local/texlive/2024/bin/x86_64-linux:$PATH"

# Set default command
CMD ["bash"]

# Optional: Add a healthcheck
HEALTHCHECK CMD ["latexmk", "--version"] || exit 1
