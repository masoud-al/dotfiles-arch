#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '
[ -r /home/masoud/.byobu/prompt ] && . /home/masoud/.byobu/prompt   #byobu-prompt#
