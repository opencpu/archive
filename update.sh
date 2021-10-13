#!/bin/bash
set -e

RPM_PLATFORMS="centos-7 centos-8 fedora-34"
DEB_PLATFORMS="ubuntu-18.04 ubuntu-20.04 debian-11"
VERSIONS="latest"

# On Linux, you need to add user to the 'docker' group (or use sudo)
# https://docs.docker.com/engine/installation/linux/linux-postinstall/
docker="docker"
$docker --version

for version in ${VERSIONS}
do
	tag="${version}"

	for target in ${DEB_PLATFORMS};	do
		$docker pull opencpu/${target}:${tag}
		$docker run --name ${target} opencpu/${target}:${tag} echo "started ${target}"
		mkdir -p ./${target}
		$docker cp ${target}:'~/opencpu-server_*.deb' ./${target}/
		$docker cp ${target}:'~/opencpu-lib_*.deb' ./${target}/
		chown -R $USER ./${target}/*
		$docker stop ${target}
		$docker rm ${target}
		$docker rmi opencpu/${target}:${tag}
		(cd ${target}; tree -I index.html -L 1 -T "OpenCPU Server Archive: ${target}" -H . > index.html)
	done

	for target in ${RPM_PLATFORMS};	do
		$docker pull opencpu/${target}:${tag}
		$docker run --name ${target} opencpu/${target}:${tag} echo "started ${target}"
		mkdir -p ./${target}
		$docker cp ${target}:/root/RPMS/x86_64 .
		chown -R $USER *
		cp -Rf x86_64/* ${target}/
		rm -Rf x86_64
		rm -Rf ./${target}/*-debuginfo-*.rpm ./${target}/*-debugsource-*.rpm ./${target}/opencpu-2.*.rpm ./${target}/repodata
		$docker stop ${target}
		$docker rm ${target}
		$docker rmi opencpu/${target}:${tag}
		(cd ${target}; tree -I index.html -L 1 -T "OpenCPU Server Archive: ${target}" -H . > index.html)
	done

done
# Main index
tree -L 1 -I index -T "OpenCPU Server Archive" -dH . > index.html

# Commit and deploy YOLO
#git add .
#git commit -a --amend -m "Update ${VERSIONS} at $(date)" --date="now"
#git push -f origin gh-pages

