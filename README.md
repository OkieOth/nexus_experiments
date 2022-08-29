# General
https://baykara.medium.com/how-to-automate-nexus-setup-process-5755183bc322
https://blog.sonatype.com/four-steps-to-get-started-with-nexus-repo-using-new-rest-apis
## Fix Unauthorized Issue
https://community.sonatype.com/t/docker-login-401-unauthorized/1345/7
# Usage
```bash
docker pull sonatype/nexus3

# running as non-root doesn't work :-/
docker run -d -p 8081:8081 --name my_nexus sonatype/nexus3

docker run -d -p 8081:8081 --name my_nexus -v nexus-data:/nexus-data sonatype/nexus3

docker stop --time=120 my_nexus
```

```bash
# swagger url
http://localhost:8081/service/rest/swagger.json
```

# Steps to allow local docker mirror
* enable in nexus a docker realm
* allow in nexus anomynous pulling
* ~~add the capability default role~~ (not needed currently)

# Automate initialisation
```bash
# confic allows to upload new scripts
docker run -d -p 8081:8081 \
    -v $(pwd)/config/nexus.properties:/nexus-data/etc/nexus.properties \
    --rm --name my_nexus sonatype/nexus3

# start nexus image
# grab current admin password
export old_pwd=$(docker exec my_nexus cat /nexus-data/admin.password) && echo "old password: $old_pwd"
# change admin password: https://stackoverflow.com/questions/38938131/use-nexus-3-api-to-change-admin-password

export new_pwd=nexusRocks999
export nexus_url=http://localhost:8081

curl -ifu admin:"${old_pwd}" \
  -XPUT -H 'Content-Type: text/plain' \
  --data "${new_pwd}" \
  ${nexus_url}/service/rest/v1/security/users/admin/change-password

# check if anomynous access is provided
curl -ifu admin:"${new_pwd}" \
  ${nexus_url}/service/rest/v1/security/anonymous

# enable script upload

# upload script to create docker repos to nexus
curl -u admin:${new_pwd} -X POST --header 'Content-Type: application/json' \
    ${nexus_url}/service/rest/v1/script \
    -d @scripts/docker_registry.json

# list available scripts
curl -ifu admin:"${new_pwd}" \
  ${nexus_url}/service/rest/v1/script

# list anomynous access
curl -ifu admin:"${new_pwd}" \
  ${nexus_url}/service/rest/v1/security/anonymous

```

# Configure local docker to use proxy
https://docs.docker.com/network/proxy/

```bash
touch ~/.docker/config.json
```

```json
{
	"auths": {
		"127.0.0.1:5000": {
			"auth": "hashAfterDockerLogin=="
		}
	},
	"proxies": {
	  "default": {
		"httpProxy": "http://127.0.0.1:5003",
		"noProxy": "*.test.example.com,.example2.com,127.0.0.0/8"
	  }
	}
}
```