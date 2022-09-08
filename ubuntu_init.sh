#!/bin/bash

_VERSION="1.1"
_INSTALL_V2RAY=true
_CHANGE_APT=true
_CHANGE_PIP=true
_INSTALL_CONDA=true
_INSTALL_POETRY=true

_DOWNLOAD_DIR="/home/$USER/download"
_V2RAY_STAGE="nodejs"   # 1:"nodejs", 2:"docker", 3:"conda"
_DEFAULT_V2RAY_CONFIG=$_DOWNLOAD_DIR/v2ray/config.json
_ORING_APT_REPO=archive.ubuntu.com
_APT_MIRROR=mirrors.ustc.edu.cn
_BASE_APP="language-pack-zh-hans git curl wget aria2 python3 python3-pip zsh jq unzip build-essential"
_TIMEZONE="Asia/Shanghai"
_PIP3_MIRROR="https://mirrors.bfsu.edu.cn/pypi/web/simple"
_CONDA_VER=latest
_POETRY_VER=1.1.13

echo -e "version: $_VERSION"

echo -e "disable_coredump"
echo "Set disable_coredump false" | sudo tee -a /etc/sudo.conf

echo -e "_DOWNLOAD_DIR: ${_DOWNLOAD_DIR}"
echo -e "_DEFAULT_V2RAY_CONFIG: $_DEFAULT_V2RAY_CONFIG"


function start_v2ray()
{
if [ ${_INSTALL_V2RAY} == "true" ]; then
    echo "install v2ray"
    cd $_DOWNLOAD_DIR
    wget https://download.fastgit.org/v2fly/v2ray-core/releases/download/v5.0.8/v2ray-linux-64.zip
    unzip v2ray-linux-64.zip -d v2ray
    read -p "input config.json file, or just enter for ${_DOWNLOAD_DIR}/v2ray/config.json: " DIR
    if [ -z $DIR ]; then
        DIR=$_DEFAULT_V2RAY_CONFIG
    fi
    echo -e "will use config file: ${DIR}"
    cd $_DOWNLOAD_DIR/v2ray
    nohup ./v2ray run -c $DIR > runoob.log 2>&1 &
    # echo "install strip-json-comments-cli"
    # sudo npm install --global strip-json-comments-cli
    # echo "install hjson first"
    # pip install hjson
    # PORT=`hjson -j $DIR | jq '.inbounds[0].port'`
    echo "sleep 5 seconds for v2ray to start up"
    echo "read v2ray log"
    tail $_DOWNLOAD_DIR/v2ray/runoob.log
    read "input v2ray port(default 11080): " PORT
    #PORT=`strip-json-comments $DIR | jq '.inbounds[0].port'`
    if [ -z $PORT ]; then
      PORT=11080
    fi
    echo -e "v2ray port is ${PORT}"

    echo -e "export http and https proxy port"
    export http_proxy=http://localhost:${PORT}
    export https_proxy=http://localhost:${PORT}
    echo "test ip using icanhazip"
    curl https://icanhazip.com
fi
}


function init()
{
  mkdir -p $_DOWNLOAD_DIR
}

# adduser ${_NEW_USER}
# echo -e "set user: ${_NEW_USER} to group sudo"
# usermod -aG sudo ${_NEW_USER}

# echo -e "change to user ${_NEW_USER}"
# su -p ${_NEW_USER}

# whoami
function change_apt()
{
  if [ $_CHANGE_APT == "true" ]; then  
    echo -e "change apt repo from ${_ORING_APT_REPO} to ${_APT_MIRROR}"
    _REP="s/${_ORING_APT_REPO}/${_APT_MIRROR}/g"
    sudo sed -i ${_REP} /etc/apt/sources.list
  fi
}

function update_apt()
{
  echo -e "update apt repo"
  sudo apt update
  echo -e "upgrade all"
}
# sudo apt upgrade -y

function apt_install_base()
{
echo "install common app: ${_BASE_APP}"
export DEBIAN_FRONTEND=noninteractive
sudo apt install -y ${_BASE_APP} 
}

function set_chinese_env()
{
  echo "set chinese env" 
  echo "LANG=\"zh_CN.UTF-8\" \
  LANGUAGE=\"zh_CN:zh:en_US:en\"
  " | sudo tee -a /etc/environment
  sudo echo "en_US.UTF-8 UTF-8 \
  zh_CN.UTF-8 UTF-8 \
  zh_CN.GBK GBK \
  zh_CN GB2312" | sudo tee -a /var/lib/locales/supported.d/local
  sudo locale-gen
  echo "install chinese font"
  sudo apt-get install -y fonts-droid-fallback ttf-wqy-zenhei ttf-wqy-microhei fonts-arphic-ukai fonts-arphic-uming
}

function change_pip_mirror()
{
  if [ $_CHANGE_PIP == "true" ]; then
    echo "change pip mirror"
    pip config set global.index-url ${_PIP3_MIRROR}
  fi

  if [ $_V2RAY_STAGE == "nodejs" ]; then
    start_v2ray
  fi
}

function install_nodejs()
{
  echo "install nodejs 14"
  curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
  sudo apt-get install -y nodejs
}

function set_timezone()
{
  echo "change timezone to ${_TIMEZONE}"
  sudo timedatectl set-timezone ${_TIMEZONE}
}

function install_docker()
{
  if [ $_V2RAY_STAGE == "docker" ]; then
    start_v2ray
  fi
  echo "install docker"
  curl -Ssl https://get.docker.com | sudo sh
  sudo usermod -aG docker ${_NEW_USER}

  echo "install docker compose"
  pip install docker-compose
}

function install_conda()
{
  if [ $_V2RAY_STAGE == "conda" ]; then
    start_v2ray
  fi

  if [ ${_INSTALL_CONDA} == "true" ]; then
      echo -e "install conda version=${_CONDA_VER}"
      cd $_DOWNLOAD_DIR
      wget "https://repo.continuum.io/miniconda/Miniconda3-${_CONDA_VER}-Linux-x86_64.sh"
      bash "Miniconda3-${_CONDA_VER}-Linux-x86_64.sh" -b -p ~/miniconda3
      # rm "Miniconda3-${_CONDA_VER}-Linux-x86_64.sh"
      # conda update -y conda
      # conda init bash
  fi
}

function install_poetry()
{
  if [ ${_INSTALL_POETRY} == "true" ]; then
      echo -e "install poetry version=${_POETRY_VER}"
      pip install poetry==${_POETRY_VER}
  fi
}


function install_neovim()
{
  echo "install neovim"
  cd $_DOWNLOAD_DIR 
  wget https://download.fastgit.org/neovim/neovim/releases/download/nightly/nvim-linux64.deb
  sudo apt-get install -y ./nvim-linux64.deb
}

function install_ezsh()
{
  echo "initiallize ezsh"
  git clone https://github.com/jotyGill/ezsh.git /tmp/ezsh
  cd /tmp/ezsh
  ./install.sh -c

  cat << EOF >> ~/.zshrc
LANG=zh_CN.UTF-8
LANGUAGE=zh_CN:en_US:en
LC_CTYPE="zh_CN.UTF-8" 
LC_NUMERIC=zh_CN.UTF-8
LC_TIME=zh_CN.UTF-8
LC_COLLATE="zh_CN.UTF-8"
LC_MONETARY=zh_CN.UTF-8
LC_MESSAGES="zh_CN.UTF-8"
LC_PAPER=zh_CN.UTF-8
LC_NAME=zh_CN.UTF-8
LC_ADDRESS=zh_CN.UTF-8
LC_TELEPHONE=zh_CN.UTF-8
LC_MEASUREMENT=zh_CN.UTF-8
LC_IDENTIFICATION=zh_CN.UTF-8
LC_ALL=
EOF

  echo "export conda env"
  cat << EOF >> ~/.zshrc
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/go/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/go/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/go/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/go/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
EOF
}

function install_rust()
{
  echo "install rust"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo sh
  cat << EOF >> ~/.zshrc
export PATH="$PATH:$HOME/.cargo/env"
EOF

}

function install_bat()
{
  echo "install bat"
  sudo apt install -y bat
  mkdir -p ~/.local/bin
  ln -s /usr/bin/batcat ~/.local/bin/bat
}

function install_lsd()
{
  echo "install lsd"
  cd $_DOWNLOAD_DIR
  wget https://github.com/Peltoche/lsd/releases/download/0.23.0/lsd_0.23.0_amd64.deb
  sudo dpkg -i ./lsd_0.23.0_amd64.deb
  cat << EOF >> ~/.zshrc
alias ls="lsd -alh"
EOF
}

function install_delta()
{
  echo "install delta"
  sudo apt-get install -y git-delta
  cat << EOF >> ~/.gitconfig
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only
[add.interactive]
    useBuiltin = false # required for git 2.37.0

[delta]
    navigate = true    # use n and N to move between diff sections
    light = false      # set to true if you're in a terminal w/ a light background color (e.g. the default macOS terminal)

[merge]
    conflictstyle = diff3

[diff]
    colorMoved = default
EOF

}

function install_fd()
{
  echo "install fd"
  sudo apt install -y fd-find
  ln -s $(which fdfind) ~/.local/bin/fd
}

function install_du_dust()
{
  echo "install dust"
  cargo install du-dust
}

function install_ripgrep()
{
  echo "install ripgrep"
  sudo apt install -y ripgrep
}

function install_cheat()
{
  echo "install cheat"
  cd /tmp \
  && wget https://github.com/cheat/cheat/releases/download/4.3.3/cheat-linux-amd64.gz \
  && gunzip cheat-linux-amd64.gz \
  && chmod +x cheat-linux-amd64 \
  && sudo mv cheat-linux-amd64 /usr/local/bin/cheat
}

function install_tldr()
{
  echo "install tldr"
  npm install -g tldr
}

function install_lvim()
{
  bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)
  
}

function do_main()
{
  init

  change_apt

  update_apt

  apt_install_base

  set_chinese_env

  change_pip_mirror

  install_nodejs

  set_timezzone

  install_docker

  install_conda

  install_poetry

  install_neovim

  install_rust
  
  install_bat
  
  install_lsd

  install_delta

  install_fd

  install_du_dust

  install_ripgrep

  install_cheat

  install_tldr
  
  install_ezsh
}


do_main

