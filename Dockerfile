# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /app

# Install basic utilities, jq, and Puppeteer dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
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
    && rm -rf /var/lib/apt/lists/*

# Install TeX Live 2024 from official source
RUN wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz && \
    tar -xzf install-tl-unx.tar.gz && \
    cd install-tl-* && \
    echo "selected_scheme scheme-full" > texlive.profile && \
    echo "TEXDIR /usr/local/texlive/2024" >> texlive.profile && \
    echo "TEXMFLOCAL /usr/local/texlive/texmf-local" >> texlive.profile && \
    echo "TEXMFSYSVAR /usr/local/texlive/2024/texmf-var" >> texlive.profile && \
    echo "TEXMFSYSCONFIG /usr/local/texlive/2024/texmf-config" >> texlive.profile && \
    echo "TEXMFVAR ~/.texmf-var" >> texlive.profile && \
    echo "TEXMFCONFIG ~/.texmf-config" >> texlive.profile && \
    echo "TEXMFHOME ~/texmf" >> texlive.profile && \
    ./install-tl -profile texlive.profile && \
    rm -rf install-tl-unx.tar.gz install-tl-*

# Add TeX Live to PATH
ENV PATH="/usr/local/texlive/2024/bin/x86_64-linux:$PATH"

# Install Pandoc, Python 3, and pip
RUN apt-get update && apt-get install -y \
    pandoc \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm

# Install Python dependencies globally
RUN pip3 install --no-cache-dir \
    pandocfilters \
    pygments

# Install Node.js dependencies
RUN npm install --global --no-progress \
    puppeteer@22.12.0 \
    mermaid-filter@1.4.7

# Set default command
CMD ["bash"]

# Optional: Add a healthcheck
HEALTHCHECK CMD ["latexmk", "--version"] || exit 1
