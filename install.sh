#!/bin/bash
set -e

# get script name
me=$(basename $0)

function myinit(){
  git init
  git add $me
  git commit -m "add setup script as initial commit" 1>/dev/null 2>&1

  git checkout -b conf_only 1>/dev/null 2>&1
  git checkout master 1>/dev/null 2>&1

  git remote add caddy https://github.com/firecyberice/caddy 1>/dev/null 2>&1
  git fetch caddy 1>/dev/null 2>&1

  git checkout -b running
  git rebase caddy/master 1>/dev/null 2>&1
  [ "$(git diff --name-only --diff-filter=U)" == "$me" ] && git rebase --skip
}

function myinstall(){
  [ -z $UPSTREAM ] && (echo -e "UPSTREAM not set"; exit 1)
  echo "UPSTREAM set to: $UPSTREAM"
  git remote add services ${UPSTREAM} 1>/dev/null 2>&1
  git fetch services 1>/dev/null 2>&1
  echo -e "\nadd services"
  myrebase services/master
}

function mysave(){
  echo "stash changes"
  set +e
  git stash 1>/dev/null 2>&1
  git checkout master 1>/dev/null 2>&1
  git checkout conf_only 1>/dev/null 2>&1
  git stash pop 1>/dev/null 2>&1
  set -e

  git add .
  git commit -m "change configs"

  echo -e "\n\napply config changes"
  git checkout running
  myrebase conf_only
}

function updateme(){
  echo "update caddy"
  git fetch caddy 1>/dev/null 2>&1

  git checkout running
  myrebase caddy/master

}
function myrebase(){
  local BRANCH="${1}"
  set +e
  git rebase ${BRANCH} 1>/dev/null 2>&1
  retval=$?
  while [ $retval -ne 0 ]; do
    echo "next conflict"
    resolveconflicts
    retval=$?
    echo ""
  done
  set -e
  echo -e "Final Status"
  git status
}

function resolveconflicts(){
  echo "list and remove untracked files"
  git clean -i
  echo "add updated files"
  git diff --name-only --diff-filter=U
  git diff --name-only --diff-filter=U | xargs --no-run-if-empty git checkout --ours
  git diff --name-only --diff-filter=U | xargs --no-run-if-empty git add
  git rebase --continue 1>/dev/null 2>&1
  return $?
}

function usage(){
cat << EOM
  usage:

  init            initialize basic setup
  install         install services from git repo (define env var UPSTREAM)
  resolve         resolve conflicts with "git checkout --ours <file> && git add <file> && git rebase --continue"
  save            save changed config to another git branch
  autorebase      loop over resolve if "git rebase --continue" is faulty.
  updated         update caddytest

EOM
}

# DIR=caddytest
if [[ $DEBUG == "true" ]]; then
  echo "$@"
  eval "$@"
  exit 0
#  exec "$@"
elif [ $# -eq 1 ]; then
  case "$1" in
    "init" )
      myinit
      ;;
    "install" )
      myinstall
      ;;
    "save" )
      mysave
      ;;
    "autorebase" )
      myrebase
      ;;
    "resolve" )
      resolveconflicts
      ;;
    "update" )
      updateme
      ;;
    * )
      usage
      ;;
  esac
else
  usage
fi
exit 0
