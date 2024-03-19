#!/bin/bash

# prerequisite
# sudo apt install pv

# Define variables
wordpress_path="/var/www/html"
mysql_user="wpuser"
mysql_password="password"
mysql_db="wpdb"

# Export WordPress files
echo "Exporting WordPress files..."
tar cf - -C $wordpress_path . | pv -s $(du -sb $wordpress_path | awk '{print $1}') | gzip > wordpress_files.tar.gz

# Export MySQL database
echo "Exporting MySQL database..."
mysqldump -u $mysql_user -p$mysql_password $mysql_db | pv | gzip > wordpress_database.sql.gz

echo "Export complete. Files: wordpress_files.tar.gz, Database: wordpress_database.sql.gz"
