#配置你的源仓库地址
orgin_git="https://github.com/pursonchen/sync-fork.git"

yum -y install jq

#Syncing a Fork with the main repository
function sync_fork() {
   current_branch=$(git rev-parse --abbrev-ref HEAD)
  
   git fetch upstream
   git checkout master
   git merge upstream/master
   git push # origin
   git checkout $current_branch
}

#Get the source address in the package. Json.
#orgin_git=$(cat package.json | jq '.repository.url')
orgin_git=${orgin_git##*+}
orgin_git=${orgin_git%%"\""}

#Check if the local repository exists upstream.
#If it exists, it is in direct sync.
#If not, add upstream to fork.
my_remote_repository=$(git remote -v)
echo $my_remote_repository
if [[ $my_remote_repository =~ "upstream" ]]
then
   sync_fork
else
   git remote add upstream $orgin_git
   sync_fork
fi
