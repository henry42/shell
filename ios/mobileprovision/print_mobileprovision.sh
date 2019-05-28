#!/bin/bash

MAP="
FILE FileName
Platform :Platform
AppIDName :AppIDName
ApplicationIdentifierPrefix :ApplicationIdentifierPrefix
Name :Name
CreationDate :CreationDate
TeamName :TeamName
TimeToLive :TimeToLive
UUID :UUID
Version :Version
TeamIdentifier :TeamIdentifier
ProvisionsAllDevices :ProvisionsAllDevices
ExpirationDate :ExpirationDate
Entitlements :Entitlements
keychain-access-groups :Entitlements:keychain-access-groups
get-task-allow :Entitlements:get-task-allow
application-identifier :Entitlements:application-identifier
com.apple.developer.team-identifier :Entitlements:com.apple.developer.team-identifier"


usage(){
    echo usage:
    echo "    " $0 mobileprovisionfile [col1 col2 col3 ...]
    echo "------"
    echo "Col | ShortFor $MAP"
    echo "------"
}




if [ -z "$1" ];then
  usage
  exit 1
fi

if [ ! -f '/usr/libexec/PlistBuddy' ];then
  echo "Error: no PlistBuddy"
  exit 1
fi

which security > /dev/null

if [ $? -eq 1 ];then
  echo "Error: where is security?"
  exit 1
fi


data=$(security cms -D -i "$1" 2>/dev/null)

value(){
  echo "$MAP" | grep "^$1" | head -1 | awk '{print $2}'
}

if [ "${#*}" -eq 1 ];then
  echo "$data"
  exit 0
fi

name="";
ind=0

if [ -z "$OFS" ];then
  OFS=","
fi

for arg in "$@"; do
  if [ $ind -gt 0 ];then

    if [ $ind -gt 1 ];then
      printf "$OFS"
    fi

    if [ "$arg" == "FILE" ];then
      v="$1"
    else
      tmp=`value $arg`
      if [ -z "$tmp" ]; then
        tmp="$arg"
      fi
      v="$(/usr/libexec/PlistBuddy -c "Print $tmp" /dev/stdin <<< "$data" )"
    fi
    printf "%s" "$v"
  fi
  ind=`expr $ind + 1`
done

printf "\n"
