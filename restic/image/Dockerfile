FROM restic/restic:0.9.5

RUN \
    mkdir -p /mnt/restic /var/spool/cron/crontabs /var/log; \
    touch /var/log/cron.log;

ENV RESTIC_PASSWORD=""
ENV BACKUP_CRON="0 */6 * * *"
ENV RESTIC_JOB_ARGS=""
ENV B2_BUCKET=""
ENV RESTIC_FORGET_POLICY="--keep-last 5"
# /data is the dir where the volumes are mounted
VOLUME /data
# /scripts is the dir the docker-compose files themselves are mounted to backup the .env
VOLUME /scripts

COPY backup.sh /bin/backup
COPY start-cron.sh /start-cron.sh

RUN chmod +x /start-cron.sh /bin/backup

WORKDIR "/"
