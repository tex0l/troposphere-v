#!/bin/sh

lastLogfile="/var/log/backup.log"

log () {
  timestamp="[$(date -u)]"
  echo "$timestamp" "$1"
  echo "$timestamp" "$1" >> ${lastLogfile}
}

copyErrorLog() {
  cp ${lastLogfile} /var/log/backup-error-last.log
}

log "Backup task starting..."

# Check / make Restic parameters
log "B2 bucket is '${B2_BUCKET}'"
repository="b2:${B2_BUCKET}:/"
log "Restic repository is '${repository}'"

# Checking if repo is initialized
log "Checking if repository is initialized"
restic -r "${repository}" snapshots &>/dev/null
status=$?
# If not, initializing it
if [ $status != 0 ]; then
  log "Restic repository '${repository}' does not exist. Running restic init."
  restic -r "${repository}" init

  init_status=$?n
  log "Repo init status ${init_status}"

  if [ $init_status != 0 ]; then
    log "Failed to init the repository: '${repository}'"
    exit 1
  fi
fi

for dir in /data/*/
do
  log "Backuping '${dir}'"
  # Starting backup
  restic -r "${repository}" backup "${dir}" --hostname=$HOSTNAME $(echo ${RESTIC_JOB_ARGS}) >> ${lastLogfile} 2>&1

  # Checking if backup was successful
  rc=$?
  log "Finished backup of '${dir}'"
  if [ $rc -eq 0 ]; then
    log "Backup of '${dir}' successful"
  else
    log "Backup of '${dir}' failed with status ${rc}"
    restic unlock
    copyErrorLog
    # kill 1 # TODO: probably not a good idea to kill ??
  fi
  # End
done

log "Backuping '/scripts'"
dir=/scripts
env_files_list=/tmp/env_files
# Starting backup of env files
rm -f ${env_files_list}
find ${dir} | grep '.env' > ${env_files_list}
restic -r "${repository}" backup --files-from ${env_files_list} --tag scripts --hostname=$HOSTNAME $(echo ${RESTIC_JOB_ARGS}) >> ${lastLogfile} 2>&1
rc=$?
log "Finished backup of '${dir}'"
if [ $rc -eq 0 ]; then
  log "Backup of '${dir}' successful"
else
  log "Backup of '${dir}' failed with status ${rc}"
  restic unlock
  copyErrorLog
  # kill 1 # TODO: probably not a good idea to kill ??
fi

log "Forgetting old snapshots"
restic -r "${repository}" forget  --hostname="$HOSTNAME" $(echo ${RESTIC_FORGET_POLICY}) --prune >> ${lastLogfile} 2>&1
rc=$?
if [ $rc -eq 0 ]; then
  log "Forgetting old snapshots successful"
else
  log "Forgetting old snapshots failed with status ${rc}"
  restic unlock
  copyErrorLog
  # kill 1 # TODO: probably not a good idea to kill ??
fi

log "Finished backup task"
