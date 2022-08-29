#!/bin/bash

scriptPos=${0%/*}

cd $scriptPos/..

docker run -d -p 8081:8081 -p 5000:5000 -p 5003:5003 -p 5004:5004 \
    -v $(pwd)/config/nexus.properties:/nexus-data/etc/nexus.properties \
    --rm --name my_nexus sonatype/nexus3

while ! docker logs my_nexus | grep "Started Sonatype Nexus" > /dev/null; do
    echo " ... wait for nexus to start"
    sleep 1
done

old_pwd=$(docker exec my_nexus cat /nexus-data/admin.password) && echo "old password: $old_pwd"
new_pwd=nexusRocks999
nexus_url=http://localhost:8081

if ! curl -ifu admin:"${old_pwd}" \
  -XPUT -H 'Content-Type: text/plain' \
  --data "${new_pwd}" \
  ${nexus_url}/service/rest/v1/security/users/admin/change-password; then
    echo "error while change admin password"
    exit 1
fi

if ! curl -u admin:${new_pwd} -X POST --header 'Content-Type: application/json' \
    ${nexus_url}/service/rest/v1/script \
    -d @scripts/docker_registry.json; then
    echo "error while upload script for docker registry"
    exit 1
fi

if ! curl -u admin:${new_pwd} -X POST --header 'Content-Type: application/json' \
    ${nexus_url}/service/rest/v1/script \
    -d @scripts/dockerhub_proxy.json; then
    echo "error while upload script for dockerhub proxy"
    exit 1
fi

if ! curl -vvv -u admin:${new_pwd} -X POST --header 'Content-Type: text/plain' \
    ${nexus_url}/service/rest/v1/script/docker_registry/run; then
    echo "error while activate docker registry"
    exit 1
fi

if ! curl -vvv -u admin:${new_pwd} -X POST --header 'Content-Type: text/plain' \
    ${nexus_url}/service/rest/v1/script/dockerhub_proxy/run; then
    echo "error while activate dockerhub proxy"
    exit 1
fi

if ! curl -u admin:${new_pwd} -X PUT --header 'Content-Type: application/json' \
    ${nexus_url}/service/rest/v1/security/anonymous \
    -d @scripts/dockerhub_proxy.json; then
    echo "error while upload script for dockerhub proxy"
    exit 1
fi

if ! curl -vvv -u admin:${new_pwd} -X PUT --header 'Content-Type: application/json' \
    ${nexus_url}/service/rest/v1/security/realms/active \
    -d @scripts/realms_active.json; then
    echo "error while activate needed realsm"
    exit 1
fi
