#!/bin/bash
#
# Argument = -u user -p password -k key -s secret -b bucket
#
# To Do - Add logging of output.
# To Do - Abstract bucket region to options
echo MONGODB_USER=$MONGODB_USER
echo MONGODB_HOST=$MONGODB_HOST
echo MONGODB_PASSWORD=$MONGODB_PASSWORD
echo MONGODB_DB=$MONGODB_DB
echo AWS_ACCESS_KEY=$AWS_ACCESS_KEY
echo AWS_ACCESS_SECRET=$AWS_ACCESS_SECRET
echo S3_REGION=$S3_REGION
echo S3_BUCKET=$S3_BUCKET

set -e

export PATH="$PATH:/usr/local/bin"

if [[ -z $MONGODB_USER ]] || [[ -z $MONGODB_PASSWORD ]] || [[ -z $AWS_ACCESS_KEY ]] || [[ -z $AWS_ACCESS_SECRET ]] || [[ -z $S3_REGION ]] || [[ -z $S3_BUCKET ]] || [[ -z $MONGODB_HOST ]]
then
  echo "Please make sure all fields are available: docker run -e MONGODB_DB=db_name -e MONGODB_HOST=host_with_port -e MONGODB_USER=username -p MONGODB_PASSWORD=password -e AWS_ACCESS_KEY=aws_access_key -e AWS_ACCESS_SECRET=aws_secret_key -e S3_REGION=s3_region -e S3_BUCKET=s3_bucket_name timchunght/mongodb-s3-backup"
  exit 1
fi

# Get the directory the script is being run from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $DIR
# Store the current date in YYYY-mm-DD-HHMMSS
DATE=$(date -u "+%F-%H%M%S")
FILE_NAME="backup-$DATE"
ARCHIVE_NAME="$FILE_NAME.tar.gz"

# Lock the database
# Note there is a bug in mongo 2.2.0 where you must touch all the databases before you run mongodump

# Dump the database
mongodump -u "$MONGODB_USER" -p "$MONGODB_PASSWORD" -h "$MONGODB_HOST" -d "$MONGODB_DB" --out $DIR/backup/$FILE_NAME

# Tar Gzip the file
tar -C $DIR/backup/ -zcvf $DIR/backup/$ARCHIVE_NAME $FILE_NAME/

# Remove the backup directory
rm -r $DIR/backup/$FILE_NAME

# Send the file to the backup drive or S3

HEADER_DATE=$(date -u "+%a, %d %b %Y %T %z")
CONTENT_MD5=$(openssl dgst -md5 -binary $DIR/backup/$ARCHIVE_NAME | openssl enc -base64)
CONTENT_TYPE="application/x-download"
STRING_TO_SIGN="PUT\n$CONTENT_MD5\n$CONTENT_TYPE\n$HEADER_DATE\n/$S3_BUCKET/$ARCHIVE_NAME"
SIGNATURE=$(echo -e -n $STRING_TO_SIGN | openssl dgst -sha1 -binary -hmac $AWS_ACCESS_SECRET | openssl enc -base64)

if [ $S3_REGION = "us-east-1" ]; then
  S3_REGION="s3"   
  
else
  S3_REGION="s3-$S3_REGION"
fi


curl -X PUT \
--header "Host: $S3_BUCKET.$S3_REGION.amazonaws.com" \
--header "Date: $HEADER_DATE" \
--header "content-type: $CONTENT_TYPE" \
--header "Content-MD5: $CONTENT_MD5" \
--header "Authorization: AWS $AWS_ACCESS_KEY:$SIGNATURE" \
--upload-file $DIR/backup/$ARCHIVE_NAME \
https://$S3_BUCKET.$S3_REGION.amazonaws.com/$ARCHIVE_NAME

echo "Done!"
