#!/bin/bash
# requires xmllint and xmlstarlet
BESU_RELEASE_ARTIFACTORY='https://hyperledger.jfrog.io/artifactory/besu-binaries/besu'

link_xpath=$(cat << EOF 
//a[starts-with(@href,
 '$BESU_RELEASE_ARTIFACTORY')
 and
 contains(@href, '.tar.gz')]/parent::*
EOF
)

parsexml () {
    xmlstarlet sel -t "$1" "$2" -n
}

fetch_release_url () {
    curl -Ls https://github.com/hyperledger/besu/releases/latest | \
        xmllint -html -xmlout 2>/dev/null - | \
        parsexml -c "$link_xpath" \
        | tee \
        >(echo url: "$(parsexml -v "//a/@href")") \
        >(echo sha256sum: "$(parsexml -v "//code" )") \
        >/dev/null
}

check_var () {
if [ -z "$1" ]
then
      echo "Could not parse $2"
      echo "Cancelling..."
      exit 1
fi
}

while read -r id val; do
    if [[ $id == url* ]]; then
        export url=$val
    elif [[ $id == sha256sum* ]]; then
        export sha256sum=$val
    fi
done < <(fetch_release_url)

check_var "$url" "release url"
check_var "$sha256sum" "shasum string"

printf "Hyperledger/Besu Release URL:\n\t%s\n" "$url"
printf "Checksum:\n\t%s\n" "$sha256sum"

printf "Pulling latest release binary...\n"
curl -LO --progress-bar "$url"
printf "Success!\n"

tarfile=$(basename "$(find . -name "besu-*.tar.gz")")

printf "Verifying checksum...\n"
echo "$sha256sum $tarfile" | sha256sum --check
