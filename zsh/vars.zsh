
#Runtime environment
export LD_LIBRARY_PATH=.:$HOME/lib

#gcc  http://gcc.gnu.org/onlinedocs/gcc/Environment-Variables.html
export LIBRARY_PATH=$HOME/lib
export CPATH=$HOME/include
export C_INCLUDE_PATH=$CPATH
export CPLUS_INCLUDE_PATH=$C_INCLUDE_PATH
#OBJC_INCLUDE_PATH



#make
export LDFLAGS="-L$HOME/lib"
export CFLAGS="-I$HOME/include"

#cmake
#export CMAKE_INCLUDE_PATH
export  CMAKE_PREFIX_PATH=$HOME

#GRUBI
#export GUROBI_HOME=$HOME/Libs/gurobi560/linux64
#export PATH=${GUROBI_HOME}/bin:$PATH
#export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${GUROBI_HOME}/lib"
#export GRB_LICENSE_FILE=$HOME/gurobi.`hostname`.lic


#sage http://www.sagemath.org/doc/reference/cmd/environ.html


export WINEARCH=win32
export WINEPREFIX=$HOME/.wine32


# ccach and colorgcc from https://wiki.archlinux.org/index.php/Ccache
#export PATH="/usr/lib/colorgcc/bin:$PATH"    # As per usual colorgcc installation, leave unchanged (don't add ccache)
#export CCACHE_PATH="/usr/bin"                 # Tell ccache to only use compilers here
#export CCACHE_DIR=/tmp/ccache                 # Tell ccache to use this path to store its cache

unset GREP_OPTIONS

#export FOAM_INST_DIR=/opt/OpenFOAM
#source /opt/OpenFOAM/OpenFOAM-2.3.0/etc/bashrc


export PATH=~/bin:~/.cargo/bin:$PATH

export PATH=~/.local/bin:$PATH

#Zephyr
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export ZEPHYR_SDK_INSTALL_DIR=$HOME/Prgs/zephyr-sdk
