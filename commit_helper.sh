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
    errorEnd
fi

echo
echo "########################################"
echo "# ブランチの確認"
echo "########################################"
logExec 'git symbolic-ref --short HEAD'
branchName=`git symbolic-ref --short HEAD`
echo
echo "あなたが見ているブランチは [ $branchName ] です。"
echo "あなたは [ $branchName ] にコミットしようとしています。"
yn=""; read -r -p "間違いはありませんか？ (Y/N): " yn
case "$yn" in [yY]*) ;; *) errorEnd ;; esac

echo
echo "########################################"
echo "# コミット対象の確認"
echo "########################################"
repDif=`git log origin/$branchName..$branchName`
gitSts=`git status -s -uall`
if [ -z "${repDif}${gitSts}" ]; then
    ng "ワークツリーはクリーンです。"
    ng "コミットすべき対象がありません。"
    errorEnd
else
    echo "以下のファイルからコミット対象を手動でバックアップしてください。"
    logExec 'git status -sb -uall'
    echo "M_：Staged  _M：Unstaged  ??：Untracked"
    echo
    git status -s -uall
    echo
    yn=""; read -r -p "バックアップしたらEnterキーを押下：" yn
fi

echo
echo "########################################"
echo "# ワークツリーの状態確認"
echo "########################################"
repDif=`git log origin/$branchName..$branchName`
gitSts=`git status -s`
if [ -z "${repDif}${gitSts}" ]; then
    ng "ワークツリーはクリーンです。"
    ng "コミットすべき対象がありません。"
    errorEnd
else
    ok "ワークツリーに変更されているファイルがあることを確認"
    echo
    echo "＜ワークツリーの状態を出力＞"
    logExec 'git status -uall'
    git status -uall
    echo
    echo "変更しているファイルを一旦、全て初期化します。"
    yn=""; read -r -p "よろしいですか？ (Y/N): " yn
    case "$yn" in [yY]*) ;; *) errorEnd ;; esac

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
    case "$yn" in [yY]*) ;; *) errorEnd ;; esac

    echo
    echo "＜プッシュされていないコミットを全て削除＞"
    logExec 'git reset --hard origin/HEAD'
    git reset --hard origin/HEAD
else
    ok "プッシュしていないコミットが無いことを確認"
fi

echo
echo "########################################"
echo "# コミット対象ファイルのステージング"
echo "########################################"
echo "手動でバックアップしたコミット対象ファイルを格納してください。"
yn=""; read -r -p "格納したらEnterキーを押下：" yn
gitSts=`git status -s`
if [ -z "$gitSts" ]; then
    ng "ワークツリーはクリーンです。"
    ng "ステージングすべき対象がありません。"
    errorEnd
else
    ok "ワークツリーに変更されているファイルがあることを確認"
    echo
    echo "コミット対象は以下のファイルです。"
    logExec 'git status -sb -uall'
    echo "M_：Staged  _M：Unstaged  ??：Untracked"
    echo
    git status -s -uall
    echo
    yn=""; read -r -p "間違いないですか？ (Y/N): " yn
    case "$yn" in [yY]*) ;; *) errorEnd ;; esac
    echo "ステージングします。"
    logExec 'git add -A'
    git add -A
fi

echo
echo "########################################"
echo "# リモートリポジトリの修正をダウンロード"
echo "########################################"
logExec 'git fetch'
git fetch

echo
echo "########################################"
echo "# リモートリポジトリの修正をローカルリポジトリに取り込み"
echo "########################################"
logExec 'git merge --ff-only FETCH_HEAD'
git merge --ff-only FETCH_HEAD
if [ $? -ne 0 ]; then
    ng "ローカルリポジトリへの取り込みに失敗しました。"
    ng "Gitに詳しい人に確認してください。"
    errorEnd
fi

echo
echo "########################################"
echo "# コミット対象ファイルのコミット"
echo "########################################"
while :
do
    comment=""; read -r -p "コミットコメントを入力してください: " comment
    echo "**************************************"
    echo "$comment"
    echo "**************************************"
    yn=""; read -r -p "コミットコメントに間違いはないですか？ (Y/N): " yn
    case "$yn" in [yY]*) break ;; *) continue ;; esac
done
echo "コミットします。"
logExec "git commit -m $comment"
git commit -m $comment
if [ $? -ne 0 ]; then
    ng "コミットに失敗しました。"
    ng "Gitに詳しい人に確認してください。"
    errorEnd
fi

echo
echo "########################################"
echo "# リモートリポジトリの修正へ反映"
echo "########################################"
echo "プッシュします。"
logExec "git push"
git push
if [ $? -ne 0 ]; then
    ng "プッシュに失敗しました。"
    ng "Gitに詳しい人に確認してください。"
    errorEnd
fi

echo
echo "########################################"
echo "# 正常終了"
echo "########################################"
