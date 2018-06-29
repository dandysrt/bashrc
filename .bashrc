# bashrc
# bashrc functions and aliases
# this is the extent of this project

me=$USER
_sed_replace(){
    replace=$1
    with=$2
    sedstring="s/$replace/$with/g"
    sed $sedstring
}

_to_upper(){
    awk '{print toupper($0)}'
}

_to_lower(){
    awk '{print tolower($0)}'
}

# The following three are useful for large directories
_tree_less(){
    tree -C $@ | less -R
}

_ls_less(){
    ls -l --color $@ | less -R
}

#find what you're looking for
_ls_grep_less(){
    if [ $# -ne 2 ]
    then
        ls -a -l --color | grep $1 | less -R 2> /dev/null
    else
        ls -a -l --color $1 | grep $2 | less -R 2> /dev/null
    fi
}

# open multiple pages and turn on line numbers
# probably better to do this in vimrc...
# but haven't you learned by now? I'M LAZY
_my_vim(){
    /usr/bin/vim -p --cmd 'set nu' $@
}

# this searches the current or provided directory and exports the result to two variables
# results are limited to 30, can easily be changed if you feel so inclined
_dir_search(){
    if [ $# -lt 2 ]
    then
        out=$(realpath $(tree -if 2> /dev/null | egrep $@ --color='always') 2> /dev/null | head -n30)
    else
        dir=$1
        shift
        out=$(realpath $(tree -if $dir 2> /dev/null | egrep $@ --color='always') 2> /dev/null | head -n30)
    fi
    echo $out
    # the fearsome looking sed is for removing colorization from the result (tends to break things)
    export result=$(echo $out | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")
    export R=$(echo $out | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")
}

# this is because I'm lazy and dimwitted and sometimes
# forget to forward slash between directories
_concat_path_str(){
    string=""
    for a in $@
    do
        string+="$a/"
    done
    echo $string
}

# overwrite the normal cd with this for best effect
_cd(){
    # export our current directory in case we have unfinished business
    export PREVIOUS_DIR=$(pwd)
    case $1 in
    # shortcuts can be just about any character(s)
    "~~")
        shift
        cd /to/frequently/used/dir/$(_concat_path_str $@)
        ;;
    *)
        cd $(_concat_path_str $@)
        ;;
    esac

    # if you're dimwitted like me and sometimes
    # try to cd to a file
    path=$_
    file=${path%?}
    if [ -f $file ]
    then
        _my_vim $file
    fi
}

# return to the previous working directory
_back(){
    _cd $PREVIOUS_DIR
}

# requires atom isntallation as-is
# may be replaced with any cli-executable text editor
_atom_open_if_contains(){
    no_results=0
    results=""
    if [[ $# -gt 1 ]]
    then
        dir=$1; shift
        no_results=$(ls -a $dir | grep $@ | wc -l)
        results=$(ls -a $dir | grep $@)
    else
        no_results=$(ls -a ./ | grep $@ | wc -l)
        results=$(ls -a ./ | grep $1)
    fi
    if [[ $no_results -gt 1 ]]
    then
        echo "Search returned multiple results:"
        echo
        for r in $results
        do
            echo $r
        done
        echo
    elif [[ $no_results -lt 1 ]]
    then
        echo "No results containing\"${@}\":"
        echo
        ls ./
    else
        shift
        atom $(realpath $results) $@
    fi
}


# allows checking out of a branch with a partial match
_git_checkout(){
    temp_b=$(_get_git_branch);
    shift;
    term=$(for x in $(echo $@); do found=$(echo $x | grep -v ^\-); if [[ ! -z $found ]]; then echo $found; break; fi; done;);
    branch=$(git branch | grep -v origin | grep $term);
    if [[ -z $branch ]]; then branch=$term; fi;
    git checkout $branch 2>/tmp/giterr
    if [[ $(echo $?) -lt 1 ]]
    then
        export lastb=$(temp_b);
        if [[ -z $(cat /tmp/giterr) ]]
        then
            git pull
        fi
    elif [[ ! -z $(cat /tmp/giterr | grep stash) ]]
    then
        ((cat /tmp/giterr 1>&3) 3>&2)
        echo
        echo "...Stashing changes"
        echo
        git stash
        echo
        _git_checkout "stub" $branch
    else
        ((cat /tmp/giterr 1>&3) 3>&2)
    fi
    rm /tmp/giterr
}

_git_stuff(){
    case $1 in
        "branch")
            if [[ -z $2 || $2 == "--list" ]]
            then
                echo "local branches:";
                git branch;
                echo "remote branches:";
                git branch -r;
            else
                git $@
            fi
            ;;
        "rmlast")
            git reset HEAD~1
            ;;
        "undo")
            git fetch origin;
            git reset --hard origin/${2};
            ;;
        "checkout")
            _git_checkout $@
            ;;
        "co")
            _git_checkout $@
            ;;
        "rn")
            _git_rename $1
            ;;
        "rename")
            _git_rename $1
            ;;
        "pull")
            git fetch && git pull
            ;;
        *)
            git $@
            ;;
        esac
}

_mute_err(){
    $@ 2>/dev/null;
}

_get_git_branch(){
    echo "$(git status | grep 'On branch' | cut -d\  -f3)";
}

_git_rename(){
    old_branch=$(_get_git_branch);
    new_branch=$1;
    git branch -m $old_branch $new_branch;
    git push origin :${old_branch};
    git push --set-upstream origin $new_branch;
}

_ls_l(){
    ls -l $@
}
