#!/usr/bin/env bash

set -e

DOCKER_TAR_DIR="<< parameters.docker_tar_dir >>"

if [ -z "<< parameters.image_file >><< parameters.image >>" ] && [ -z "$(ls -A "$DOCKER_TAR_DIR" 2>/dev/null)" ]; then
    echo "image_file or image parameters or docker tarballs must be present"
    exit 255
fi

REPORT_DIR=/clair-reports
mkdir $REPORT_DIR

DB=$(docker run -p 5432:5432 -d arminc/clair-db:latest)
CLAIR=$(docker run -p 6060:6060 --link "$DB":postgres -d arminc/clair-local-scan:latest)
CLAIR_SCANNER=$(docker run -v /var/run/docker.sock:/var/run/docker.sock -d ovotech/clair-scanner:latest tail -f /dev/null)

clair_ip=$(docker exec -it "$CLAIR" hostname -i | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
scanner_ip=$(docker exec -it "$CLAIR_SCANNER" hostname -i | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

if [ -n "<< parameters.whitelist >>" ]; then
    cat "<< parameters.whitelist >>"
    docker cp "<< parameters.whitelist >>" "$CLAIR_SCANNER:/whitelist.yml"

    WHITELIST="-w /whitelist.yml"
fi

function scan() {
    local image=$1
    # replace forward-slashes and colons with underscores
    munged_image=$(echo "$image" | sed 's/\//_/g' | sed 's/:/_/g')
    sanitised_image_filename="${munged_image}.json"
    local ret=0
    local docker_cmd=(docker exec -it "$CLAIR_SCANNER" clair-scanner \
        --ip "$scanner_ip" \
        --clair=http://"$clair_ip":6060 \
        -t "<< parameters.severity_threshold >>" \
        --report "/$sanitised_image_filename" \
        --log "/log.json" $WHITELIST
        --reportAll=true \
        --exit-when-no-features=false \
        "$image")

    # if verbose output is disabled, analyse status code for more fine-grained output
    if [ "<< parameters.disable_verbose_console_output >>" == "true" ];then
        "${docker_cmd[@]}" > /dev/null 2>&1 || ret=$?
    else
        "${docker_cmd[@]}" 2>&1 || ret=$?
    fi
    if [ $ret -eq 0 ]; then
        echo "No unapproved vulnerabilities"
    elif [ $ret -eq 1 ]; then
        echo "Unapproved vulnerabilities found"
        if [ "<< parameters.fail_on_discovered_vulnerabilities >>" == "true" ];then
            EXIT_STATUS=1
        fi
    elif [ $ret -eq 5 ]; then
        echo "Image was not scanned, not supported."
        if [ "<< parameters.fail_on_unsupported_images >>" == "true" ];then
            EXIT_STATUS=1
        fi
    else
        echo "Unknown clair-scanner return code $ret."
        EXIT_STATUS=1
    fi

    docker cp "$CLAIR_SCANNER:/$sanitised_image_filename" "$REPORT_DIR/$sanitised_image_filename" || true
}

EXIT_STATUS=0

for entry in "$DOCKER_TAR_DIR"/*.tar; do
    [ -e "$entry" ] || continue
    images=$(docker load -i "$entry" | sed -e 's/Loaded image: //g')
    for image in $images; do
        scan "$image"
    done
done

if [ -n "<< parameters.image_file >>" ]; then
    images=$(cat "<< parameters.image_file >>")
    for image in $images; do
        docker pull "$image"
        scan "$image"
    done
fi
if [ -n "<< parameters.image >>" ]; then
    image="<< parameters.image >>"
    docker pull "$image"
    scan "$image"
fi

exit $EXIT_STATUS
