#!/bin/bash
folder="$1"
ipa="$2"


help(){
    echo "Usage:"
    echo "  $0 provisionfilesfolder ipa"
}

if [ -z "$folder" ] || [ ! -d "$folder" ] || [ -z "$ipa" ] || [ ! -f "$ipa" ];then
    help
    exit 1
fi


provisions_desc=()
provisions=()
provision=""

while IFS= read -r -d $'\0' file; do
    data=$(security cms -D -i "$file" 2>/dev/null)
    id=`/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /dev/stdin <<< "$data"`
    provisions+=("$file")
    provisions_desc+=("$id $file")
done < <(find "$folder" -type f -name "*.mobileprovision"  -print0)

select p in "${provisions_desc[@]}"; do
    provision=${provisions[$REPLY]}
    break
done;

data=$(security cms -D -i "$provision" 2>/dev/null)
id=`/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /dev/stdin <<< "$data"`
identity=`/usr/libexec/PlistBuddy -c "Print :DeveloperCertificates:0" /dev/stdin <<< "$data" | openssl x509 -noout -inform DER -subject | sed 's/^.*CN=\([^\/]*\)\/.*$/\1/'`


ipa_out="${ipa%.ipa}.resigned.ipa"

bash -s "$ipa" "$identity" --verbose -b "${id#*.}" -p "$provision" "$ipa_out" < <(curl -fs "https://raw.githubusercontent.com/henry42/resign/63ed5695d9e88536d04354d5a93e65701b530391/resign.sh")
