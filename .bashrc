# bashrc
# bashrc functions and aliases
# this is the extent of this project

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
    "!!")
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
