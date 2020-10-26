#!/bin/sh
cd `dirname $0`
source ./_common

echo
echo "########################################"
echo "# Gitディレクトリの確認"
echo "########################################"
git_dir=git_dir; read -r -p "Gitディレクトリを入力：" git_dir
if [ -e $git_dir"\.git" ]; then
    cd "$git_dir"
    ok "Gitディレクトリであることを確認。"
else
    ng "Gitディレクトリではありません。"
    exit 1
fi

echo
echo "########################################"
echo "# ワークツリーの状態確認"
echo "########################################"
gitSts=`git status -s`
if [ -z "$gitSts" ]; then
    ok "ワークツリーはクリーンです。"
else
    warn "ワークツリーはクリーンではありません。"
    echo
    echo "＜ワークツリーの状態を出力＞"
    logExec 'git status'
    git status
    echo
    echo "変更しているファイルを全て初期化します。"
    yn=""; read -r -p "よろしいですか？ (Y/N): " yn
    case "$yn" in [yY]*) ;; *) echo ; exit 1 ;; esac

    echo
    echo "＜ワークツリーを初期化＞"
    logExec 'git reset --hard HEAD'
    git reset --hard HEAD
    echo
    logExec 'git clean -df'
    git clean -df
fi

echo
echo "########################################"
echo "# ローカルリポジトリとリモートリポジトリの状態比較"
echo "########################################"
branchName=`git symbolic-ref --short HEAD`
repDif=`git log origin/$branchName..$branchName`
if [ ! -z "$repDif" ]; then
    warn "プッシュしていないコミットがあります。"
    echo
    echo "＜プッシュされていないコミットを表示＞"
    logExec "git log origin/$branchName..$branchName"
    git log origin/$branchName..$branchName
    echo
    echo "プッシュされていないコミットを全て削除します。"
    yn=""; read -r -p "よろしいですか？ (Y/N): " yn
    case "$yn" in [yY]*) ;; *) echo ; exit 1 ;; esac

    echo
    echo "＜プッシュされていないコミットを全て削除＞"
    logExec 'git reset --hard origin/HEAD'
    git reset --hard origin/HEAD
fi