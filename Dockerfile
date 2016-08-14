FROM ubuntu:14.04

MAINTAINER Timothy Chung <timchunght@gmail.com>
RUN echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.0.list
RUN apt-get update --fix-missing

RUN apt-get install -y --force-yes mongodb-org=3.0.12 mongodb-org-server=3.0.12 mongodb-org-shell=3.0.12 mongodb-org-mongos=3.0.12 mongodb-org-tools=3.0.12 openssl curl

ADD ./backup.sh /mongodb-s3-backup/backup.sh
WORKDIR /mongodb-s3-backup
RUN chmod +x /mongodb-s3-backup/backup.sh


ENTRYPOINT ./backup.sh
