# Use a base image (Ubuntu latest version)
FROM ubuntu:latest

# Add the universe repository for missing packages
RUN apt-get -y update && \
    apt-get -y install software-properties-common && \
    add-apt-repository universe && \
    apt-get -y update

# Install prerequisites for adding repositories, build tools, and other dependencies
RUN apt-get -y update && apt-get -y install \
    software-properties-common \
    libpcre3-dev \
    libgeoip-dev \
    libssl-dev \
    make \
    gcc-4.8 \
    git \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    libncurses5-dev \
    texinfo \
    autoconf \
    automake \
    bison \
    gettext \
    gperf \
    gzip \
    help2man \
    m4 \
    perl \
    tar \
    wget \
    xz-utils \
    python3-tk \
    emacs \
    zsh \
    fonts-powerline \
    autopoint && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set environment variables for common paths
ENV USER_HOME=/root \
    IBCS_HOME=/root/IBCS \
    COREUTILS_HOME=/root/coreutils \
    BINARYNINJA_PATH=/root/binaryninja/python

# Update PYTHONPATH to include Binary Ninja
ENV PYTHONPATH=$PYTHONPATH:$BINARYNINJA_PATH

# Clone the coreutils repository into the working directory
RUN git clone git://git.sv.gnu.org/coreutils $COREUTILS_HOME

# Check if the build directory exists; if not, create it and run the build process
RUN if [ ! -d $COREUTILS_HOME/build ]; then \
        mkdir -p $COREUTILS_HOME/build && \
        cd $COREUTILS_HOME && \
        ./bootstrap && \
        FORCE_UNSAFE_CONFIGURE=1 CC=gcc CFLAGS="-O0 -gdwarf-2 -save-temps=obj -Wno-error -fno-asynchronous-unwind-tables -fno-exceptions" \
        ./configure --prefix=$COREUTILS_HOME/build && \
        make -j$(nproc) && \
        make install; \
    else \
        echo "Build directory already exists, skipping build."; \
    fi

# Copy the local IBCS repository from the host to the container
COPY ./ $IBCS_HOME/

# Set the working directory to IBCS
WORKDIR $IBCS_HOME

# Cache requirements.txt for pip installs
COPY ./requirements.txt /root/IBCS/requirements.txt

# Create a virtual environment in the user's home directory and install dependencies
RUN python3 -m venv /root/venv && \
    . /root/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install --no-cache-dir -r /root/IBCS/requirements.txt


# Install oh-my-zsh and set zsh as the default shell
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
chsh -s $(which zsh) && \
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc && \
echo "ZSH_THEME=\"agnoster\"" >> ~/.zshrc

# Set the default shell to bash for simplicity and speed (you can switch back to zsh if needed)
SHELL ["/bin/zsh", "-c"]

# Set the entrypoint or command
CMD ["zsh"]
