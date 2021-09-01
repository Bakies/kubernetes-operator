#!/usr/bin/env bash

set -eo pipefail

[[ ! $# -eq 1 ]] && echo "Usage: $0 backup_number" && exit 1;
[[ -z "${BACKUP_DIR}" ]] && echo "Required 'BACKUP_DIR' env not set" && exit 1;
[[ -z "${JENKINS_HOME}" ]] && echo "Required 'JENKINS_HOME' env not set" && exit 1;
BACKUP_TMP_DIR=$(mktemp -d)

backup_number=$1
echo "Running backup"

# config.xml in a job directory is a config file that shouldnt be backed up
# config.xml in child directores is state that should. For example-
# branches/myorg/branches/myrepo/branches/master/config.xml should be retained while
# branches/myorg/config.xml should not
# Skip the seed job since there seems to be a race condition causing an error (A build with number 1 already exists) when the seed job runs at the start, I don't particularly care about job history there anyway
# Don't exit if tar exits 1, tar(1) describes the exit as the archive file does not represent exactly what is on disk. The archive is still created and should still be saved. 
set +e 
tar -C ${JENKINS_HOME} -czf "${BACKUP_TMP_DIR}/${backup_number}.tar.gz" --exclude jobs/*/workspace* --exclude jobs/*-seed-dsl --no-wildcards-match-slash --anchored --exclude jobs/*/config.xml -c jobs && \
exitcode=$?
# Exit if not success or warning described above
if [ "$exitcode" != "1" ] && [ "$exitcode" != "0" ]; then
    exit $exitcode
fi
set -e
mv ${BACKUP_TMP_DIR}/${backup_number}.tar.gz ${BACKUP_DIR}/${backup_number}.tar.gz

rm -r ${BACKUP_TMP_DIR}

[[ ! -s ${BACKUP_DIR}/${backup_number}.tar.gz ]] && echo "backup file '${BACKUP_DIR}/${backup_number}.tar.gz' is empty" && exit 1;

echo Done
exit 0
