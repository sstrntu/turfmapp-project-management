#!/bin/bash

# Stop on Error
set -e

# Configure those to match your TURFMAPP Docker container names
TURFMAPP_DOCKER_CONTAINER_POSTGRES="turfmapp_postgres_1"
TURFMAPP_DOCKER_CONTAINER_APP="turfmapp_app_1"

# Extract tgz archive
TURFMAPP_BACKUP_ARCHIVE_TGZ=$1
TURFMAPP_BACKUP_ARCHIVE=$(basename "$TURFMAPP_BACKUP_ARCHIVE_TGZ" .tgz)
echo -n "Extracting tarball $TURFMAPP_BACKUP_ARCHIVE_TGZ ... "
tar -xzf "$TURFMAPP_BACKUP_ARCHIVE_TGZ"
echo "Success!"

# Import Database
echo -n "Importing postgres database ... "
cat "$TURFMAPP_BACKUP_ARCHIVE/postgres.sql" | docker exec -i "$TURFMAPP_DOCKER_CONTAINER_POSTGRES" psql -U postgres
echo "Success!"

# Restore Docker Volumes
echo -n "Importing user-avatars ... "
docker run --rm --volumes-from "$TURFMAPP_DOCKER_CONTAINER_APP" -v "$(pwd)/$TURFMAPP_BACKUP_ARCHIVE:/backup" ubuntu cp -rf /backup/user-avatars /app/public/
echo "Success!"
echo -n "Importing project-background-images ... "
docker run --rm --volumes-from "$TURFMAPP_DOCKER_CONTAINER_APP" -v "$(pwd)/$TURFMAPP_BACKUP_ARCHIVE:/backup" ubuntu cp -rf /backup/project-background-images /app/public/
echo "Success!"
echo -n "Importing attachments ... "
docker run --rm --volumes-from "$TURFMAPP_DOCKER_CONTAINER_APP" -v "$(pwd)/$TURFMAPP_BACKUP_ARCHIVE:/backup" ubuntu cp -rf /backup/attachments /app/private/
echo "Success!"

echo -n "Cleaning up temporary files and folders ... "
rm -r "$TURFMAPP_BACKUP_ARCHIVE"
echo "Success!"

echo "Restore complete!"
