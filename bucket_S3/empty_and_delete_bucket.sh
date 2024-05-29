#!/bin/bash

BUCKET_NAME="funny-terraform-bucket"

# Delete all object versions
echo "Deleting all object versions from the bucket..."
versions=$(aws s3api list-object-versions --bucket $BUCKET_NAME --query 'Versions[].[Key, VersionId]' --output text)
if [ -n "$versions" ]; then
    echo "$versions" | while read key version; do
        aws s3api delete-object --bucket $BUCKET_NAME --key "$key" --version-id "$version"
    done
else
    echo "No object versions found."
fi

# Delete all delete markers
echo "Deleting all delete markers from the bucket..."
markers=$(aws s3api list-object-versions --bucket $BUCKET_NAME --query 'DeleteMarkers[].[Key, VersionId]' --output text)
if [ -n "$markers" ]; then
    echo "$markers" | while read key version; do
        aws s3api delete-object --bucket $BUCKET_NAME --key "$key" --version-id "$version"
    done
else
    echo "No delete markers found."
fi

# Remove all objects (if any remain) from the bucket
echo "Removing all objects from the bucket..."
aws s3 rm s3://$BUCKET_NAME --recursive --include "*"

# Delete the bucket
echo "Deleting the bucket..."
aws s3api delete-bucket --bucket $BUCKET_NAME --region us-east-1

echo "Bucket $BUCKET_NAME deleted successfully."

