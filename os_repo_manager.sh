#!/usr/bin/env bash

print_hint() {
    echo "Try \`${0##*/} --help' for more information." >&2
}

PARSED_OPTIONS=$(getopt -n "${0##*/}" -o hp: --long help,project: -- "$@")

if [ $? != 0 ] ; then print_hint ; exit 1 ; fi

eval set -- "$PARSED_OPTIONS"

while true; do
    case "$1" in
        -h|--help)
            echo "${0##*/} [options]"
            echo ""
            echo "options:"
            echo "-h, --help                show brief help"
            echo "-p, --project=NAME        project package name"
            exit 0
            ;;
        -p|--project)
            shift
            TARGET_PROJECT=`echo $1`
            shift
            ;;
        --)
            break
            ;;
    esac
done

if [ -n "$TARGET_PROJECT" ]
then
    PROJECTS="|"$(curl -s https://git.openstack.org/cgit/ | \
                  grep reposection | \
                  awk -F 'reposection' '{print $2}' | \
                  awk -F 'td' '{print $1}' | \
                  cut -d ">" -f2 | \
                  cut -d "<" -f1 | \
                  tr "\\n" "|")
    if [[ ! $PROJECTS =~ "|"$TARGET_PROJECT"|" ]]
    then
        echo "${0##*/}: invalid project name" >&2 ; print_hint ; exit 1
    fi
fi

PROGRAMS=$(curl -s https://git.openstack.org/cgit/ | \
           grep sublevel-repo | awk -F 'title=' '{print $2}' | \
           awk -F ' href=' '{print $1}' | cut -d "'" -f2)

BASEDIR=`pwd`

for REPO in $PROGRAMS
do
    [ `pwd` != $BASEDIR ] && cd $BASEDIR
    PROJECT=$(echo $REPO | cut -d / -f1)
    PROGRAM=$(echo $REPO | cut -d / -f2)
    [ -n "$TARGET_PROJECT" ] && [ $TARGET_PROJECT != $PROJECT ] && continue
    if [ -d $PROJECT ]
    then
        cd $PROJECT
        if [ -d $PROGRAM ]
        then
            cd $PROGRAM
            [[ $(git branch | grep ^*) != "* master" ]] && git checkout master
            git fetch origin
            git pull origin master
        else
            git clone git://git.openstack.org/$REPO.git
        fi
    else
        mkdir $PROJECT
        cd $PROJECT
        git clone git://git.openstack.org/$REPO.git
    fi
done
cd $BASEDIR
