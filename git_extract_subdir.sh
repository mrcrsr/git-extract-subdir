#!/bin/sh

#TODO: Start with one parameter only from repositories root dir

repo="$1"
subdir="$2"
new_repo="$3"
CALLLED_FROM_GIT_ROOTDIR_WITH_ONE_PARAM="false"

scriptname="git_extractsubdir"


if [ "$#" -eq "1" ]; then
    repo="."
    subdir="$1"
    new_repo=""
    CALLLED_FROM_GIT_ROOTDIR_WITH_ONE_PARAM="true"
fi

if [ "$#" -eq "0" ]; then
    echo "$scriptname <path-to-repo> <RELATIVE-path-to-subdir> <path-to-new-repo>"
    echo "    the path to the subdir must be give relative to the original repository"
    echo "    the path to the subdir must NOT contain leading or trailing / or ."
    echo " "
    echo "$scriptname <RELATIVE-path-to-subdir>"
    echo "    call from a git's root directory"
    echo "    the new repo will be created in the parent directory"
    exit 0
fi

if [ "$#" -ne "3" ] && [ "$#" -ne "1" ]; then
    echo "Wrong number of input parameters"
    echo "    $scriptname <path-to-repo> <RELATIVE-path-to-subdir> <path-to-new-repo>"
    echo "    $scriptname <RELATIVE-path-to-subdir>"
    exit 1
fi

if [ -d "${repo:?}" ]; then
    echo "Found repository: ${repo:?}"
else
    echo "Error: Repository ${repo:?} does not exist"
    exit 2
fi

repo_fullpath="$(cd "${repo:?}" && pwd)"
if [ -z ${repo_fullpath} ]; then
    echo "Error: Could not create full path to repository ${repo:?}"
    exit 3
fi

subdir_given="${subdir:?}"
subdir="$(echo "${subdir_given:?}" | sed -e 's/^\.\///' -e 's/\/$//')"
if [ -d "${repo_fullpath:?}/${subdir:?}" ]; then
    echo "Found subdirectory: ${repo:?} -> ${subdir:?}"
else
    echo "Error: Subdirectory ${subdir:?} does not exist"
    exit 4
fi

new_branch="${subdir:?}-$(date +%Y%m%d-%H%M%S)"

if [ "$CALLLED_FROM_GIT_ROOTDIR_WITH_ONE_PARAM" = "true" ]; then
    new_repo="../${new_branch:?}.git"
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
    mkdir ${new_repo:?}
    if [ "$?" -eq "0" ]; then
        echo "Created directory ${new_repo:?}"
    else
        echo "Directory ${new_repo:?} could not created:"
        exit 6
    fi
fi

new_repo_fullpath="$(cd "${new_repo:?}" && pwd)"
if [ -z ${new_repo_fullpath:?} ]; then
    echo "Error: Could not create full path to new repository ${new_repo_fullpath:?}"
    exit 7
fi


# Give some output
echo "Number of given input parameters:       $#"
echo "Relative path to repo:                  $repo"
echo "Absolute path to repo:                  $repo_fullpath"
echo "Repo's subdir relative to repo (given): $subdir_given"
echo "Repo's subdir relative to repo (used):  $subdir"
echo "New branch name in repo:                $new_branch"
echo "Relative path to new repo:              $new_repo"
echo "Absolute path to new repo:              $new_repo_fullpath"

#read  -n 1 -p "Press any key to continue..." mainmenuinput

cd "${repo_fullpath:?}"

echo "Splitting ${subdir:?} in it's own branch..."
git subtree split -P ${subdir:?} -b ${new_branch:?}

if [ $? -eq "0" ]; then
    echo "Created new branch:"
    echo "Name:    ${new_branch:?}"
    echo "Content: ${subdir:?}"
else
    echo "Something went wrong at the creation of a new branch for the subdir"
    echo "Inspect ${repo_fullpath:?} to find more information"
    exit 8
fi

cd "${new_repo_fullpath:?}"
if [ "$?" -eq "0" ]; then
    echo "Changed to new repository ${new_repo_fullpath:?}"
else
    echo "Could not change to directory: ${new_repo_fullpath:?}"
    exit 9
fi

git init
if [ "$?" -eq "0" ]; then
    echo "Initialized new respository ${new_repo_fullpath:?}"
else
    echo "Could not initialize new respository ${new_repo_fullpath:?}"
    exit 10
fi

git pull "${repo_fullpath:?}" "${new_branch:?}"
if [ "$?" -eq "0" ]; then
    echo "Successfully exported..."
    echo "the directory       ${subdir:?}..."
    echo "from repository     ${repo_fullpath:?}..."
    echo "into new repository ${new_repo_fullpath:?}"
    exit 0
else
    echo "Could not pull branch from repository"
    echo "Repository: ${repo_fullpath:?}"
    echo "Branch:     ${new_branch:?}"
    exit 11
fi

exit 0
