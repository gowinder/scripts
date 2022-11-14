#!/bin/bash

_VERSION="1.8"
_INSTALL_V2RAY=true
_CHANGE_APT=true
_CHANGE_PIP=true
_INSTALL_CONDA=true
_INSTALL_POETRY=true
_INSTALL_LSD=true

_DOWNLOAD_DIR="/home/$USER/download"
_V2RAY_STAGE="nodejs"   # 1:"nodejs", 2:"docker", 3:"conda"
_DEFAULT_V2RAY_CONFIG=$_DOWNLOAD_DIR/v2ray/config.json
_ORING_APT_REPO=archive.ubuntu.com
_APT_MIRROR=mirrors.ustc.edu.cn
_BASE_APP="language-pack-zh-hans git curl wget aria2 python3 python3-pip zsh jq unzip build-essential htop iftop git-flow libssl-dev pkg-config dnsutils inetutils-ping"
_TIMEZONE="Asia/Shanghai"
_PIP3_MIRROR="https://mirrors.bfsu.edu.cn/pypi/web/simple"
_CONDA_VER=latest
_POETRY_VER=1.1.13

_LOCAL_PROXY=""

echo -e "version: $_VERSION"

echo -e "disable_coredump"
echo "Set disable_coredump false" | sudo tee -a /etc/sudo.conf

echo -e "_DOWNLOAD_DIR: ${_DOWNLOAD_DIR}"
echo -e "_DEFAULT_V2RAY_CONFIG: $_DEFAULT_V2RAY_CONFIG"

function _echo()
{
  _NOTIC_='\033[1;34m'
  printf "${_NOTIC_} $1 \033[0m \n" 
}


function start_v2ray()
{
if [ ${_INSTALL_V2RAY} == "true" ]; then
    _echo "install v2ray"
    cd $_DOWNLOAD_DIR
    wget https://download.fastgit.org/v2fly/v2ray-core/releases/download/v5.0.8/v2ray-linux-64.zip
    unzip v2ray-linux-64.zip -d v2ray
    read -p "input config.json file, or just enter for ${_DOWNLOAD_DIR}/v2ray/config.json: " DIR
    if [ -z $DIR ]; then
        DIR=$_DEFAULT_V2RAY_CONFIG
    fi
    _echo "will use config file: ${DIR}"
    cd $_DOWNLOAD_DIR/v2ray
    nohup ./v2ray run -c $DIR > runoob.log 2>&1 &
    # echo "install strip-json-comments-cli"
    # sudo npm install --global strip-json-comments-cli
    # echo "install hjson first"
    # pip install hjson
    # PORT=`hjson -j $DIR | jq '.inbounds[0].port'`
    _echo "sleep 5 seconds for v2ray to start up"
    sleep 5
    _echo "read v2ray log"
    tail -n 1 $_DOWNLOAD_DIR/v2ray/runoob.log
    _V2RAY_STATUS=$(tail -n 1 $_DOWNLOAD_DIR/v2ray/runoob.log | awk '{print $NF}')
    _echo "v2ray status: ${_V2RAY_STATUS}"
    if [ $_V2RAY_STATUS == "started" ]; then
      
      read -p "input v2ray port(default 11080): " PORT
      #PORT=`strip-json-comments $DIR | jq '.inbounds[0].port'`
      if [ -z $PORT ]; then
        PORT=11080
      fi
      _echo "v2ray port is ${PORT}"

      _echo "export http and https proxy port"
      export http_proxy=http://localhost:${PORT}
      export https_proxy=http://localhost:${PORT}
      export _LOCAL_PROXY=http://localhost:${PORT}
      _echo "test ip using icanhazip"
      curl -x localhost:11080 https://icanhazip.com
    fi

fi
}


function init()
{
  touch ~/.zshrc
  mkdir -p $_DOWNLOAD_DIR
}

function config()
{
  read -p "install v2ray and set local proxy(y/n)? default y: " _ANS 
  if [ $_ANS == "n" ]; then
    _INSTALL_V2RAY="false"
  fi

  read -p "all default(y/n)? this will change apt mirror and pip mirror, default y: " _ANS
  if [ $_ANS == "n" ]; then
    read -p "change apt mirror to $_APT_MIRROR (y/n)? default y: " _ANS
    if [ $_ANS == "n" ]; then
      _CHANGE_APT="false"
    fi

    read -p "change pip mirror to $_PIP3_MIRROR (y/n)? default y:" _ANS
    if [ $_ANS == "n" ]; then
      _CHANGE_PIP="false"
    fi
  fi
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
    _echo "change apt repo from ${_ORING_APT_REPO} to ${_APT_MIRROR}"
    _REP="s/${_ORING_APT_REPO}/${_APT_MIRROR}/g"
    sudo sed -i ${_REP} /etc/apt/sources.list
  fi
}

function update_apt()
{
  _echo "update apt repo"
  sudo apt update
  _echo "upgrade all"
}
# sudo apt upgrade -y

function apt_install_base()
{
_echo "install common app: ${_BASE_APP}"
export DEBIAN_FRONTEND=noninteractive
DEBIAN_FRONTEND=nointeractive sudo DEBIAN_FRONTEND=nointeractive apt install -y ${_BASE_APP} 
}

function set_chinese_env()
{
  _echo "set chinese env" 
  echo "LANG=\"zh_CN.UTF-8\" \
  LANGUAGE=\"zh_CN:zh:en_US:en\"
  " | sudo tee -a /etc/environment
  sudo echo "en_US.UTF-8 UTF-8 \
  zh_CN.UTF-8 UTF-8 \
  zh_CN.GBK GBK \
  zh_CN GB2312" | sudo tee -a /var/lib/locales/supported.d/local
  sudo locale-gen
  _echo "install chinese font"
  sudo apt-get install -y fonts-droid-fallback ttf-wqy-zenhei ttf-wqy-microhei fonts-arphic-ukai fonts-arphic-uming
}

function change_pip_mirror()
{
  if [ $_CHANGE_PIP == "true" ]; then
    _echo "change pip mirror"
    pip config set global.index-url ${_PIP3_MIRROR}
  fi
}

function install_nodejs()
{
  if [ $_V2RAY_STAGE == "nodejs" ]; then
    start_v2ray
  fi

  _echo "install nodejs 14"
  curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
  sudo apt-get install -y nodejs
}

function set_timezone()
{
  _echo "change timezone to ${_TIMEZONE}"
  sudo timedatectl set-timezone ${_TIMEZONE}
}

function install_docker()
{
  if [ $_V2RAY_STAGE == "docker" ]; then
    start_v2ray
  fi
  _echo "install docker"
  curl -Ssl https://get.docker.com | sudo sh
  sudo usermod -aG docker $USER

  _echo "install docker compose"
  pip install docker-compose

  _echo "install lazy docker "
  curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
}

function install_conda()
{
  if [ $_V2RAY_STAGE == "conda" ]; then
    start_v2ray
  fi

  if [ ${_INSTALL_CONDA} == "true" ]; then
      _echo "install conda version=${_CONDA_VER}"
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
      _echo "install poetry version=${_POETRY_VER}"
      pip install poetry==${_POETRY_VER}
  fi
}


function install_neovim()
{
  _echo "install neovim"
  _echo "uninstall old version first"
  sudo apt-get -y autoremove neovim
  cd $_DOWNLOAD_DIR 
  wget https://download.fastgit.org/neovim/neovim/releases/download/nightly/nvim-linux64.deb
  sudo apt-get install -y ./nvim-linux64.deb
}

function install_ezsh()
{
  _echo "initiallize ezsh"
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

  if [ -z $_LOCAL_PROXY ]; then
    _echo "export localproxy: $_LOCAL_PROXY"
    export https_proxy=$_LOCAL_PROXY
    export http_proxy=$_LOCAL_PROXY
  else
    _echo "no localproxy"
  fi

  ~/miniconda3/bin/conda init zsh
}

function install_rust()
{
  _echo "install rust"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo sh
  # sudo apt-get install -y rust-all

}

function install_bat()
{
  _echo "install bat"
  sudo apt install -y bat
  _echo "link bat"
  mkdir -p ~/.local/bin
  ln -s /usr/bin/batcat ~/.local/bin/bat
}

function install_lsd()
{
  if [ $_INSTALL_LSD == "true" ]; then
    _echo "download lsd"
    cd $_DOWNLOAD_DIR
    wget https://github.com/Peltoche/lsd/releases/download/0.23.0/lsd_0.23.0_amd64.deb
    _echo "install lsd"
    sudo dpkg -i ./lsd_0.23.0_amd64.deb
  fi
}

function install_delta()
{
  _echo "install delta"
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
  _echo "install fd"
  sudo apt install -y fd-find
  ln -s $(which fdfind) ~/.local/bin/fd
}

function install_du_dust()
{
  _echo "install du-dust"
  cargo install du-dust
}

function install_ripgrep()
{
  _echo "install ripgrep"
  sudo apt install -y ripgrep
}

function install_cheat()
{
  _echo "install cheat"
  cd /tmp \
  && wget https://github.com/cheat/cheat/releases/download/4.3.3/cheat-linux-amd64.gz \
  && gunzip cheat-linux-amd64.gz \
  && chmod +x cheat-linux-amd64 \
  && sudo mv cheat-linux-amd64 /usr/local/bin/cheat
}

function install_tldr()
{
  _echo "install tldr"
  sudo npm install -g tldr
}

function install_lvim()
{
  _echo "install lunarvim"
  bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)
  wget https://raw.githubusercontent.com/gowinder/scripts/main/lvim/config.lua -O ~/.config/lvim/config.lua 
}

function install_cz()
{
  sudo npm install -g commitizen
  sudo npm install -g cz-conventional-changelog
  sudo npm install -g cz-conventional-changelog
  echo '{ "path": "cz-customizable" }' > ~/.czrc
}

function install_dog()
{
  _echo "install dog"
  mkdir -p /tmp
  cd /tmp/
  git clone https://github.com/ogham/dog.git /tmp/dog
  cd /tmp/dog
  cargo update
  cargo build --release
  sudo cp target/release/dog /usr/local/bin
}

function install_sss()
{
  mkdir -p /tmp 
  cd /tmp 
  wget https://raw.githubusercontent.com/gnos-project/gnos-sockets/master/sss 
  chmod +x sss
  mv sss /usr/local/bin/
}

function install_duf()
{
  cd /tmp
  wget https://github.com/muesli/duf/releases/download/v0.8.0/duf_0.8.0_linux_amd64.deb 
  sudo dpkg -i ./duf_0.8.0_linux_amd64.deb
}

function install_glow()
{
  _echo "install glow"
  echo 'deb [trusted=yes] https://repo.charm.sh/apt/ /' | sudo tee /etc/apt/sources.list.d/charm.list
  sudo apt update && sudo apt install -y glow
}

function install_zoxide()
{
  _echo "install zoxide"
  sudo apt install -y zoxide
}

function install_gtop()
{
  _echo "install gtop"
  sudo npm install -g gtop
}

function install_bandwhich()
{
  _echo "install bandwhich"
  cargo install bandwhich
  sudo ln -s $(which bandwhich) /usr/sbin/bandwhich
}

function install_gping()
{
  _echo "install gping"
  carge install gping
}

function install_fkill()
{
  _echo "install fkill"
  sudo npm install -g fkill
}

function update_env()
{
  if [ $_INSTALL_LSD == "true" ]; then
      _echo "add lsd alias"
  cat << EOF >> ~/.zshrc
alias ls="lsd -alh"
eval "$(zoxide init zsh)"
EOF
  fi
}

function do_main()
{
  init

  config

  change_apt

  update_apt

  apt_install_base

  set_chinese_env

  change_pip_mirror

  install_nodejs

  set_timezone

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

  install_dog

  install_sss

  install_duf

  install_glow

  install_zoxide
  
  install_gtop

  install_fkill

  install_lvim

  install_ezsh

  install_cz

  update_env
}


do_main

