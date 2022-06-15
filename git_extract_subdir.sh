#!/bin/sh

# https://stackoverflow.com/questions/65263626/push-commits-affecting-a-given-path-to-a-new-origin/65265319#65265319
# https://gist.github.com/trongthanh/2779392
# https://mattsch.com/2015/06/19/move-directory-from-one-repository-to-another-preserving-history/
# With filter-repo
# git filter-branch --subdirectory-filter <directory-to-keep> -- --all # --prune-empy
# move to subdirectory: check how to do
# git reset --hard
# git gc --aggressive
# git prune
# git clean -df
#  - go to new repo
# git remote add <branch> /path/to/repo
# git pull --allow-unrelated-histories <branch> main
#TODO: Start with one parameter only from repositories root dir

repo="$1"
subdir="$2"
new_repo="$3"

scriptname="git_extractsubdir"

if [ "$#" -eq "0" ]; then
    echo "$scriptname <path-to-repo> <RELATIVE-path-to-subdir> <path-to-new-repo>"
    echo "    the path to the subdir must be give relative to the original repository"
    echo "    the path to the subdir must NOT contain leading or trailing / or ."
    exit 0
fi

if [ "$#" -ne "3" ] && [ "$#" -ne "1" ]; then
    echo "Wrong number of input parameters"
    echo "    $scriptname <path-to-repo> <RELATIVE-path-to-subdir> <path-to-new-repo>"
    echo "    $scriptname <RELATIVE-path-to-subdir>"
    exit 1
fi

if [ ! -d "${repo:?}" ]; then
    echo "${scriptname}: Error: Repository ${repo:?} does not exist"
    exit 2
fi

repo_fullpath="$(cd "${repo:?}" && pwd)"
if [ -z ${repo_fullpath} ]; then
    echo "${scriptname}: Error: Could not create full path to repository ${repo:?}"
    exit 3
fi

subdir_given="${subdir:?}"
subdir="$(echo "${subdir_given:?}" | sed -e 's/^\.\///' -e 's/\/$//')"
if [ ! -d "${repo_fullpath:?}/${subdir:?}" ]; then
    echo "${scriptname}: Error: Subdirectory ${subdir:?} does not exist"
    exit 4
fi

if [ -d "${new_repo:?}" ]; then
    # directory already exists
    if [ "$(ls -A | wc -w)" -eq "0" ]; then
        # directory is empty and a new repo can be created there
        echo "The directory "${new_repo:?}" already exists and can be used"
    else
        # directory is not empty
        echo "The directory ${new_repo:?} already exists and can not be used:"
        echo "Empty that directory or use another one"
        exit 5
    fi
else
    # directory does not yet exist
    echo "The directory ${new_repo:?} does not yet exist and will be created..."
    mkdir -p ${new_repo:?}
    if [ "$?" -eq "0" ]; then
        echo "Created directory ${new_repo:?}"
    else
        echo "Directory ${new_repo:?} could not created:"
        exit 6
    fi
fi

new_repo_fullpath="$(cd "${new_repo:?}" && pwd)"
if [ -z ${new_repo_fullpath:?} ]; then
    echo "${scriptname}: Error: Could not create full path to new repository ${new_repo_fullpath:?}"
    exit 7
fi


# Give some output
echo "Number of given input parameters:       $#"
echo "Relative path to repo:                  $repo"
echo "Absolute path to repo:                  $repo_fullpath"
echo "Repo's subdir relative to repo (given): $subdir_given"
echo "Repo's subdir relative to repo (used):  $subdir"
echo "Relative path to new repo:              $new_repo"
echo "Absolute path to new repo:              $new_repo_fullpath"

#read  -n 1 -p "Press any key to continue..." mainmenuinput

cd "${new_repo_fullpath:?}"
if [ "$?" -ne "0" ]; then
    echo "Could not change to directory: ${new_repo_fullpath:?}"
    exit 9
fi


exit 0
