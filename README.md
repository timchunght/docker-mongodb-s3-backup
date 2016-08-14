# Mongodb to Amazon S3 Backup Script

## Usage

`docker run -n MONGODB_HOST -e MONGODB_USER=username -p MONGODB_PASSWORD=password -e AWS_ACCESS_KEY=aws_access_key -e AWS_SECRET_KEY=aws_secret_key -e S3_REGION=s3_region -e S3_BUCKET=s3_bucket_name timchunght/docker-mongodb-s3-backup`

Where `S3_REGION` is in the format `ap-southeast-1`

## Cron

### Daily

Add the following line to `/etc/cron.d/db-backup` to run the script every day at midnight (UTC time) 

    0 0 * * * root /usr/bin/docker webcastio/mongodb-s3-backup -n MONGODB_HOST -u MONGODB_USER -p MONGODB_PASSWORD -k AWS_ACCESS_KEY -s AWS_SECRET_KEY -b S3_BUCKET

# License 

(The MIT License)