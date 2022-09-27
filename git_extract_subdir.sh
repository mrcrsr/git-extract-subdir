#!/bin/sh

repo="$1"
new_repo="$2"
nargs="$#"

scriptname="git_extractsubdir"

CLONE="1"

if [ "$#" -eq "0" ]; then
    echo "$scriptname <path-to-repo> <path-to-new-repo> <subdir-1> <subdir-2> ... <subdir-n>"
    echo "    the path to the subdirs must be given relative to the original repository"
    exit 0
fi

if [ "$#" -lt "3" ]; then
    echo "Wrong number of input parameters"
    echo "    $scriptname <path-to-repo> <path-to-new-repo> <subdir-1> <subdir-2> ... <subdir-n>"
    echo "  Leaving..."
    exit 1
fi

if [ ! -d "${repo:?}" ]; then
    echo "${scriptname}: Error: Repository ${repo:?} does not exist"
    echo "  Leaving..."
    exit 2
fi

# Throw away first and second paramters: source repo and target repo
shift
shift

# Construct strings for subdirs to keep
for subdir in "$@"; do
    if [ ! -d "${repo:?}/${subdir:?}" ]; then
        echo "${scriptname}: Error: Subdirectory does not exist:"
        echo "  '${subdir:?}' in '${repo:?}'"
        echo "  Leaving..."
        exit 4
    fi
    filterrepo_keptdirs="$filterrepo_keptdirs --path $subdir"
done

if [ -n "$CLONE" ]; then
    if [ -d "${new_repo:?}" ]; then
        # directory already exists
        if [ "$(ls -A | wc -w)" -ne "0" ]; then
            # directory is not empty
            echo "${scriptname}: Error: The directory already exists and can not be used:"
            echo "  ${new_repo:?}"
            echo "  Empty that directory or use another one"
            echo "  Leaving..."
            exit 5
        fi
    fi

    git clone --no-local "${repo:?}" "${new_repo:?}"
    if [ "$?" -ne "0" ]; then
        echo "${scriptname}: Error: Could not clone repository:"
        echo "  ${repo:?}  -->  ${new_repo:?}"
        echo "  Leaving..."
        exit 9
    fi
else
    if [ ! -d "${new_repo:?}/.git" ]; then
        echo "${scriptname}: Error: Can't skip clone, target directory is not a git repository:"
        echo "  ${new_repo:?}"
        echo "  Leaving..."
        exit 9
    fi
fi

cd "${new_repo:?}"
if [ "$?" -ne "0" ]; then
    echo "${scriptname}: Error: Could change to cloned repository:"
    echo "  ${new_repo:?}"
    echo "  Leaving..."
    exit 9
fi

# Give some output
echo "Number of given input parameters:       $nargs"
echo "Relative path to repo:                  $repo"
echo "Relative path to new repo:              $new_repo"
echo "Parameter string for filter-repo:       $filterrepo_keptdirs"


# Call git filter-repo
echo "$scriptname: Calling 'git filter-repo'"
git filter-repo ${filterrepo_keptdirs}
echo "$scriptname: Calling 'git reset --hard'"
git reset --hard
# echo "$scriptname: Calling 'git gc --aggressive'"
# git gc --aggressive
echo "$scriptname: Calling 'git prune'"
git prune
echo "$scriptname: Calling 'git clean -df'"
git clean -df
echo "$scriptname: Finished"

#read  -n 1 -p "Press any key to continue..." mainmenuinput


exit 0
