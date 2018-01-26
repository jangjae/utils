cp .ctags  $HOME
cp ./.bashrc $HOME
cp .tmux.conf $HOME
tmux source-file ~/.tmux.conf
cp ./svn-config/config  $HOME/.subversion
cp ./vim/.vimrc  $HOME
cp -rf ./vim/.vim $HOME
# vundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
