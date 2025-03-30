# Use official TeX Live base image
FROM texlive/texlive:latest

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# Install system dependencies as root
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
  sudo \
  ca-certificates \
  fonts-liberation \
  && rm -rf /var/lib/apt/lists/*

# Install FiraCode fonts as root
RUN mkdir -p /usr/share/fonts/truetype/firacode && \
  wget -O /tmp/Fira_Code_v6.2.zip \
  https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip && \
  unzip -j /tmp/Fira_Code_v6.2.zip "ttf/*" -d /usr/share/fonts/truetype/firacode && \
  rm /tmp/Fira_Code_v6.2.zip && \
  fc-cache -f -v

# Install Node.js and npm as root
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
  apt-get install -y nodejs && \
  npm install -g npm

# Create non-root user and allow sudo without password
RUN useradd -m -s /bin/bash -u 1000 -g 1000 appuser && \
  chown -R appuser:appuser /app && \
  echo "appuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/appuser

# Switch to non-root user
USER appuser

# Set up Python virtual environment as appuser
RUN python3 -m venv /home/appuser/venv && \
  /home/appuser/venv/bin/pip install --no-cache-dir \
  pandocfilters==1.5.1 \
  pygments==2.19.1

# Set up global npm install path for appuser
RUN mkdir -p /home/appuser/.npm-global && \
  npm config set prefix /home/appuser/.npm-global

# Install Node.js dependencies globally as appuser
RUN npm install -g --no-progress \
  puppeteer@23.9.0 \
  @mermaid-js/mermaid-cli@11.4.2

# Configure Puppeteer env vars
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Set PATH for venv, global Node.js binaries, and TeX Live
ENV PATH="/home/appuser/venv/bin:/home/appuser/.npm-global/bin:/usr/local/texlive/2024/bin/x86_64-linux:$PATH"

CMD ["bash"]
HEALTHCHECK CMD ["latexmk", "--version"] || exit 1
