#!/bin/bash

# Define variables
timestamp=$(date +"%Y%m%d_%H%M%S")
wordpress_path="/var/www/html"
backup_path="/home/ubuntu/backup"
mysql_user="wpuser"
mysql_password="password"
mysql_db="wpdb"
s3_bucket="mashmaristore"
s3_prefix="backups/mashmari.in"

# Export WordPress files with timestamp
echo "Exporting WordPress files..."
tar cf - -C $wordpress_path . | pv -s $(du -sb $wordpress_path | awk '{print $1}') | gzip > $backup_path/wordpress_files_$timestamp.tar.gz

# Export MySQL database with timestamp
echo "Exporting MySQL database..."
mysqldump -u $mysql_user -p$mysql_password $mysql_db | gzip > $backup_path/wordpress_database_$timestamp.sql.gz
echo "Export complete. Files: wordpress_files_$timestamp.tar.gz, Database: wordpress_database_$timestamp.sql.gz"

# Upload files to S3
echo "Uploading files to S3..."
aws s3 cp $backup_path/wordpress_files_$timestamp.tar.gz s3://$s3_bucket/$s3_prefix/
aws s3 cp $backup_path/wordpress_database_$timestamp.sql.gz s3://$s3_bucket/$s3_prefix/

# Delete backups older than 30 days
find $backup_path -name "*.gz" -type f -mtime +30 -exec rm {} \;

echo "Export complete. Files uploaded to S3 bucket: $s3_bucket/$s3_prefix"
