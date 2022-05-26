#!/bin/sh

echo "Number of given input parameters:       $#"
echo "Path to repo                            $1"
echo "Repo's subdir relative to repo:         $2"
echo "Path to new repo consisting the subdir: $3"
echo "Working directory:                      $callerdir"

if [ "$#" -eq "0" ]; then
    echo "git_export_subdir <path-to-repo> <RELATIVE-path-to-subdir> <path-to-new-repo>"
    echo "the path to the subdir must be give relative to the original repository"
    echo "the path to the subdir must NOT contain leading or trailing / or ."
    exit 0
fi

if [ "$#" -lt "3" ]; then
    echo "Not enough input parameters"
    echo "git_export_subdir <path-to-repo> <RELATIVE-path-to-subdir> <path-to-new-repo>"
    exit 1
fi




if [ -d "${repo:?}" ]; then
    echo "Found repository: ${repo:?}"
else
    echo "Error: Repository ${repo:?} does not exist"
    exit 2
fi


if [ -d "${subdir:?}" ]; then
    echo "Found subdirectory: ${repo:?} -> ${subdir:?}"
else
    echo "Error: Subdirectory ${subdir:?} does not exist"
    exit 3
fi

repo="$1"
subdir="$2"
new_repo="$3"
callerdir="$(pwd)"

if [ -d "${new_repo:?}" ]; then
    # directory already exists
    if [ "$(ls -A | wc -w)" -eq "0" ]; then
        # directory is empty and a new repo can be created there
        echo "The directory "${new_repo:?}" already exists and can be used"
    else
        # directory is not empty
        echo "The directory ${new_repo:?} already exists and can not be used:"
        echo "Empty that directory or use another one"
        exit 4
    fi
else
    # directory does not yet exist
    echo "The directory ${new_repo:?} does not yet exist and will be created..."
    mkdir ${new_repo:?}
    if [ "$?" -eq "0" ]; then
        echo "Created directory ${new_repo:?}"
    else
        echo "Directory ${new_repo:?} could not created:"
        exit 5
    fi
fi

#read  -n 1 -p "Press any key to continue..." mainmenuinput

new_branch="${subdir:?}-$(date +%Y%m%d-%H%M%S)"
cd "${repo:?}"
repo_fullpath=$(pwd)


echo "Splitting ${subdir:?} in it's own branch..."
git subtree split -P ${subdir:?} -b ${new_branch:?}

if [ $? -eq "0" ]; then
    echo "Created new branch:"
    echo "Name:    ${new_branch:?}"
    echo "Content: ${subdir:?}"
else
    echo "Something went wrong at the creation of a new branch for the subdir"
    echo "Inspect ${repo:?} to find more information"
    exit 6
fi

cd "${callerdir:?}"
if [ "$?" -eq "0" ]; then
    echo "Changed to directory ${callerdir:?}"
else
    echo "Could not change to directory ${callerdir:?}"
    exit 7
fi

cd "${new_repo:?}"
if [ "$?" -eq "0" ]; then
    echo "Changed to new repository ${new_repo:?}"
else
    echo "Could not change to directory: ${new_repo:?}"
    exit 8
fi

git init
if [ "$?" -eq "0" ]; then
    echo "Initialized new respository ${new_repo:?}"
else
    echo "Could not initialize new respository ${new_repo:?}"
    exit 9
fi

git pull "${repo_fullpath:?}" "${new_branch:?}"
if [ "$?" -eq "0" ]; then
    echo "Successfully exported..."
    echo "the directory       ${subdir:?}..."
    echo "from repository     ${repo:?}..."
    echo "into new repository ${new_repo:?}"
    exit 0
else
    echo "Could not pull branch from repository"
    echo "Repository: ${repo:?}"
    echo "Branch:     ${new_branch:?}"
    exit 10
fi

exit 0
