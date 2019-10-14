#!/bin/sh

lastLogfile="/var/log/restore.log"

log () {
  timestamp="[$(date -u)]"
  echo "$timestamp" "$1"
  echo "$timestamp" "$1" >> ${lastLogfile}
}

copyErrorLog() {
  cp ${lastLogfile} /var/log/restore-error-last.log
}

log "Restore task starting..."

# Check / make Restic parameters
log "B2 bucket is '${B2_BUCKET}'"
repository="b2:${B2_BUCKET}:/"
log "Restic repository is '${repository}'"

# Checking if repo is initialized
log "Checking if repository is initialized"
restic -r "${repository}" snapshots --path="${PATH_TO_RESTORE}" &>/dev/null
status=$?
# If not, initializing it
if [ $status != 0 ]; then
  log "Restic repository '${repository}' does not exist. Running restic init."
  exit 1
fi

for dir in /data/*/
do
  log "Backuping '${dir}'"
  # Starting backup
  restic -r "${repository}" backup "${dir}" ${RESTIC_JOB_ARGS} >> ${lastLogfile} 2>&1

  # Checking if backup was successful
  rc=$?
  log "Finished backup"
  if [ $rc -eq 0 ]; then
    log "Backup Successful"
  else
    log "Backup Failed with Status ${rc}"
    restic unlock
    copyErrorLog
    # kill 1 # TODO: probably not a good idea to kill ??
  fi
  # End
done
