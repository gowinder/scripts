#!/bin/bash

# _NEW_USER=go
_INSTALL_V2RAY=0
_DEFAULT_V2RAY_CONFIG=~/download/v2ray/config.json
_ORING_APT_REPO=archive.ubuntu.com
_APT_MIRROR=mirrors.ustc.edu.cn
_BASE_APP="language-pack-zh-hans git curl wget aria2 python3 python3-pip zsh jq unzip build-essential"
_TIMEZONE="Asia/Shanghai"
_PIP3_MIRROR="https://mirrors.bfsu.edu.cn/pypi/web/simple"
_INSTALL_CONDA=1
_CONDA_VER=latest
_INSTALL_POETRY=1
_POETRY_VER=1.1.13

echo -e "disable_coredump"
echo "Set disable_coredump false" | sudo tee -a /etc/sudo.conf


# adduser ${_NEW_USER}
# echo -e "set user: ${_NEW_USER} to group sudo"
# usermod -aG sudo ${_NEW_USER}

# echo -e "change to user ${_NEW_USER}"
# su -p ${_NEW_USER}

# whoami

echo -e "change apt repo from ${_ORING_APT_REPO} to ${_APT_MIRROR}"
_REP="s/${_ORING_APT_REPO}/${_APT_MIRROR}/g"
sudo sed -i ${_REP} /etc/apt/sources.list

#sudo -u ${_NEW_USER} bash -c '
# su - $_NEW_USER << SHT

echo -e "update apt repo"
sudo apt update
echo -e "upgrade all"
# sudo apt upgrade -y

echo "install common app: ${_BASE_APP}"
export DEBIAN_FRONTEND=noninteractive
sudo apt install -y ${_BASE_APP}

echo "set chinese env"
echo "LANG=\"zh_CN.UTF-8\"
LANGUAGE=\"zh_CN:zh:en_US:en\"
" | sudo tee -a /etc/environment
sudo echo "en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
zh_CN.GBK GBK
zh_CN GB2312
" | sudo tee -a /var/lib/locales/supported.d/local
sudo locale-gen
echo "install chinese font"
sudo apt-get install -y fonts-droid-fallback ttf-wqy-zenhei ttf-wqy-microhei fonts-arphic-ukai fonts-arphic-uming

echo "change pip mirror"
pip config set global.index-url ${_PIP3_MIRROR}
mkdir -p ~/download

echo "install nodejs lts"
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs

if [ ${_INSTALL_V2RAY}=="1" ]; then
    echo "install v2ray"
    cd download
    wget https://download.fastgit.org/v2fly/v2ray-core/releases/download/v5.0.8/v2ray-linux-64.zip
    unzip v2ray-linux-64.zip -d v2ray
    read -p "input config.json file, or just enter for ~/download/v2ray/config.json" DIR
    if [ $DIR=="" ]; then
        DIR=$_DEFAULT_V2RAY_CONFIG
    fi
    echo -e "will use config file: ${DIR}"
    cd ~/download/v2ray
    nohup ./v2ray run -c $DIR > runoob.log 2>&1 &
    echo "install strip-json-comments-cli"
    sudo npm install --global strip-json-comments-cli
    # echo "install hjson first"
    # pip install hjson
    # PORT=`hjson -j $DIR | jq '.inbounds[0].port'`
    echo "get v2ray port"
    PORT=`strip-json-comments $DIR | jq '.inbounds[0].port'`
    echo -e "v2ray port is ${PORT}"

    echo -e "export http and https proxy port"
    export http_proxy=http://localhost:${PORT}
    export https_proxy=http://localhost:${PORT}
    echo "test ip using icanhazip"
    curl https://icanhazip.com
fi

cd ~

echo "change timezone to ${_TIMEZONE}"
sudo timedatectl set-timezone ${_TIMEZONE}

echo "install docker"
curl -Ssl https://get.docker.com | sudo sh
sudo usermod -aG docker ${_NEW_USER}

echo "install docker compose"
pip install docker-compose

if [ ${_INSTALL_CONDA}=="1" ]; then
    echo -e "install conda version=${_CONDA_VER}"
    cd ~/download
    wget "https://repo.continuum.io/miniconda/Miniconda3-${_CONDA_VER}-Linux-x86_64.sh"
    bash Miniconda3-${CONDA_VER}-Linux-x86_64.sh
    rm Miniconda3-${CONDA_VER}-Linux-x86_64.sh
    conda update -y conda
    conda init bash
fi

if [ ${_INSTALL_POETRY}=="1" ]; then
    echo -e "install poetry version=${_POETRY_VER}"
    pip install poetry==${_POETRY_VER}
fi

echo "install neovim"
sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt-get update
sudo apt-get install -y neovim

echo "initiallize ezsh"
git clone https://github.com/jotyGill/ezsh.git /tmp/ezsh
cd /tmp/ezsh
./install.sh -c
if [ ${_INSTALL_CONDA}=="1" ]; then
    conda init zsh
fi