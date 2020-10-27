#!/bin/sh
cd `dirname $0`
source ./_common

echo
step "########################################"
step "# Gitディレクトリの確認"
step "########################################"
git_dir=git_dir; read -r -p "Gitディレクトリを入力：" git_dir
if [ -e $git_dir"\.git" ]; then
    cd "$git_dir"
    ok "Gitディレクトリであることを確認。"
else
    ng "Gitディレクトリではありません。"
    errorEnd
fi

echo
step "########################################"
step "# ブランチの確認"
step "########################################"
logExec 'git symbolic-ref --short HEAD'
branchName=`git symbolic-ref --short HEAD`
echo
echo "あなたが見ているブランチは [ $branchName ] です。"
echo "あなたは [ $branchName ] にコミットしようとしています。"
yn=""; read -r -p "間違いはありませんか？ (Y/N): " yn
case "$yn" in [yY]*) ;; *) errorEnd ;; esac

echo
step "########################################"
step "# コミット対象の確認"
step "########################################"
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
    while :
    do
        yn=""; read -r -p "バックアップしましたか？ (Y/N): " yn
        case "$yn" in [yY]*) break ;; *) continue ;; esac
    done
fi

echo
step "########################################"
step "# ワークツリーの状態確認"
step "########################################"
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
step "########################################"
step "# ローカルリポジトリとリモートリポジトリの状態比較"
step "########################################"
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
step "########################################"
step "# コミット対象ファイルのステージング"
step "########################################"
while :
do
    echo "手動でバックアップしたコミット対象ファイルを格納してください。"
    yn=""; read -r -p "格納しましたか？ (Y/N): " yn
    case "$yn" in [yY]*) break ;; *) continue ;; esac
done
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
step "########################################"
step "# リモートリポジトリの修正をダウンロード"
step "########################################"
logExec 'git fetch'
git fetch
if [ $? -ne 0 ]; then
    ng "フェッチに失敗しました。"
    ng "Gitに詳しい人に確認してください。"
    errorEnd
else
    ok "フェッチしました。"
fi

echo
step "########################################"
step "# リモートリポジトリの修正をローカルリポジトリに取り込み"
step "########################################"
logExec 'git merge --ff-only FETCH_HEAD'
git merge --ff-only FETCH_HEAD
if [ $? -ne 0 ]; then
    ng "ローカルリポジトリへの取り込みに失敗しました。"
    ng "Gitに詳しい人に確認してください。"
    errorEnd
else
    ok "マージしました。"
fi

echo
step "########################################"
step "# コミット対象ファイルのコミット"
step "########################################"
while :
do
    comment=""; read -r -p "コミットコメントを入力してください: " comment
    echo
    echo "**************************************"
    echo "$comment"
    echo "**************************************"
    echo
    yn=""; read -r -p "コミットコメントに間違いはないですか？ (Y/N): " yn
    case "$yn" in [yY]*) break ;; *) continue ;; esac
done
echo "コミットします。"
logExec "git commit -m \"$comment\""
git commit -m "$comment"
if [ $? -ne 0 ]; then
    ng "コミットに失敗しました。"
    ng "Gitに詳しい人に確認してください。"
    errorEnd
else
    ok "コミットしました。"
fi

echo
step "########################################"
step "# リモートリポジトリの修正へ反映"
step "########################################"
echo "プッシュします。"
logExec "git push"
git push
if [ $? -ne 0 ]; then
    ng "プッシュに失敗しました。"
    ng "Gitに詳しい人に確認してください。"
    errorEnd
else
    ok "プッシュしました。"
fi

echo
echo "########################################"
echo "# 正常終了"
echo "########################################"
