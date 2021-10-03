#!/bin/bash

echo "[ START ] on $(date +'%d-%m-%Y_%H-%M')"

function checkMD() {
    local new=$1
    local old=$2

    [[ ! -f ${old} ]] && return 1

    $(diff $old $new > /dev/null)
    return $?
}

[[ ! -f .env ]] && {
    cp .env.example .env
    apt update && apt install jq curl -y
    [[ ! $? -eq 0 ]] && exit 1

    echo "Init complete, please check env in .env and rerun script again"
    echo "==="
    cat .env
    echo "==="
    exit 0
}

source .env

CP=0
case ${DEBUG} in
    true) DEBUG_CURL="-v";;
    false) DEBUG_CURL="-s";;
    *) DEBUG_CURL="-s";;
esac

[[ ! -z $1 ]] && DOMAIN=$1

[[ ! -d ${PATH_TO_COPY} ]] && {
    echo "Dir for cert nof found, created"
    mkdir $PATH_TO_COPY || exit 1
}

CERT=$(curl ${DEBUG_CURL} $API_SERVER -X POST -H "Authorization: Bearer $TOKEN" --form "domain=$DOMAIN" | jq -r '.data.chain')
[[ ! $? -eq 0 ]] && exit 1
echo -e $CERT > $CERT_NAME

KEY=$(curl ${DEBUG_CURL} $API_SERVER -X POST -H "Authorization: Bearer $TOKEN" --form "domain=$DOMAIN" | jq -r '.data.key')
[[ ! $? -eq 0 ]] && exit 1
echo -e $KEY > $KEY_NAME

CERTS=( $CERT_NAME $KEY_NAME )

for FILE in ${CERTS[*]}; do
    if ! checkMD $FILE $PATH_TO_COPY/$FILE; then
        cp $PATH_TO_COPY/$FILE $PATH_TO_COPY/$FILE.bak
        cp $FILE $PATH_TO_COPY/$FILE
        [[ $? -eq 0 ]] && ((CP=CP+1))
        echo "$FILE updated"
    else
        echo "update $FILE not needed"
    fi
done

[[ ! $CP == 0 ]] && {
    systemctl restart $SERVICE_RESTART
    [[ ! $? -eq 0 ]] && echo "service not restarted, restart manually"
}

echo "delete tempary files"
rm $CERT_NAME $KEY_NAME

echo "[ END ] on $(date +'%d-%m-%Y_%H-%M')"
echo ""
