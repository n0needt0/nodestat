5 16 * * 2 (
cd /mnt/temp; 
rm -f -r *.dump*; 
/usr/local/mongodb/bin/mongodump -o myproject_tuesday.dump > /mnt/temp/mongodump.log; 
/usr/bin/zip -9 -r myproject_tuesday.dump.zip myproject_tuesday.dump > /mnt/temp/zip.log;
 /usr/bin/s3cmd put myproject_tuesday.dump.zip s3://mymongodbbackups
)
