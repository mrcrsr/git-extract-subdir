#!/bin/sh

repo="$1"
subdir="$2"
new_repo="$3"
callerdir="$(pwd)"

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

repo_fullpath="$(cd "${repo:?}" && pwd)"
if [ -z ${repo_fullpath} ]; then
    echo "Error: Could not create full path to repository ${repo:?}"
    exit 100
fi


if [ -d "${repo_fullpath:?}/${subdir:?}" ]; then
    echo "Found subdirectory: ${repo:?} -> ${subdir:?}"
else
    echo "Error: Subdirectory ${subdir:?} does not exist"
    exit 3
fi


if [ -d "${new_repo_fullpath:?}" ]; then
    # directory already exists
    if [ "$(ls -A | wc -w)" -eq "0" ]; then
        # directory is empty and a new repo can be created there
        echo "The directory "${new_repo_fullpath:?}" already exists and can be used"
    else
        # directory is not empty
        echo "The directory ${new_repo_fullpath:?} already exists and can not be used:"
        echo "Empty that directory or use another one"
        exit 4
    fi
else
    # directory does not yet exist
    echo "The directory ${new_repo_fullpath:?} does not yet exist and will be created..."
    mkdir ${new_repo_fullpath:?}
    if [ "$?" -eq "0" ]; then
        echo "Created directory ${new_repo_fullpath:?}"
    else
        echo "Directory ${new_repo_fullpath:?} could not created:"
        exit 5
    fi
fi

new_repo_fullpath="$(cd "${new_repo_fullpath:?}" && pwd)"
if [ -z ${new_repo_fullpath:?} ]; then
    echo "Error: Could not create full path to new repository ${new_repo_fullpath:?}"
    exit 100
fi

#read  -n 1 -p "Press any key to continue..." mainmenuinput

new_branch="${subdir:?}-$(date +%Y%m%d-%H%M%S)"

# Give some output
echo "Number of given input parameters:       $#"
echo "Relative path to repo:                  $repo"
echo "Absolute path to repo:                  $repo_fullpath"
echo "Repo's subdir relative to repo:         $subdir"
echo "New branch name in repo:                $new_branch"
echo "Relative path to new repo:              $new_repo"
echo "Absolute path to new repo:              $new_repo_fullpath"
echo "Starting directory:                     $callerdir"

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
    exit 6
fi

cd "${callerdir:?}"
if [ "$?" -eq "0" ]; then
    echo "Changed to directory ${callerdir:?}"
else
    echo "Could not change to directory ${callerdir:?}"
    exit 7
fi

cd "${new_repo_fullpath:?}"
if [ "$?" -eq "0" ]; then
    echo "Changed to new repository ${new_repo_fullpath:?}"
else
    echo "Could not change to directory: ${new_repo_fullpath:?}"
    exit 8
fi

git init
if [ "$?" -eq "0" ]; then
    echo "Initialized new respository ${new_repo_fullpath:?}"
else
    echo "Could not initialize new respository ${new_repo_fullpath:?}"
    exit 9
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
    exit 10
fi

exit 0
