#!/bin/bash

export d=`date +%m%d%H%M`;
export server="50.116.10.172";
export dir="/var/backup";
export app="%APPLICATION%";
export dirapp=$dir/$app/app;
export dirdb=$dir/$app/db;

mkdir -p $dir;
mkdir -p $dir/$app;
mkdir -p $dirapp
mkdir -p $dirdb;

#zipt site
zip -r $dirapp/$d-%APPLICATION%.zip /var/%APPLICATION%
#dump db

rm -rf $dirdb/dump/*;

mongodump --host localhost --port 27017 --db=statsdb --out = $dirdb/dump

zip -9 -r $dirdb/$d-%APPLICATION%.mongo.zip $dirdb/dump


for f in $( ls -t $dirdb/*.mongo.zip | tail -n +5 ); do  rm $f; done
for f in $( ls -t $dirapp/*.zip | tail -n +5 ); do  rm $f; done

#bkd1
ssh root@$server mkdir -p $dir;
ssh root@$server mkdir -p $dir/$app;
ssh root@$server mkdir -p $dirapp;
ssh root@$server mkdir -p $dirdb;


for f in $( ls -tr $dirdb | tail -n 1 );
    #move file
    do  scp $dirdb/$f root@$server:$dirdb/$f;
done

#check if db copied
if ssh root@$server stat $dirdb/$f \> /dev/null 2\>\&1
then
    echo "db file copied"
else
    echo  "Backup: %APPLICATION% db  FAILED" | mail -s "Backup: %APPLICATION% db  FAILED" ayasinsky@helppain.net
fi

#check if db copier correctly

dbc=`shasum $dirdb/$f | cut --delimiter=' ' -f 1`;
rdbc=`ssh root@$server shasum $dirdb/$f | cut --delimiter=' ' -f 1`;
echo $dbc;
echo $rdbc;

if [ $dbc == $rdbc ]
then
     echo  "checksum good"
else
     echo  "Backup: %APPLICATION% db  checksum FAILED" | mail -s "Backup: %APPLICATION% db checksum FAILED" ayasinsky@helppain.net
fi

for f in $( ls -tr $dirapp | tail -n 1 );
    #move file
    do  scp $dirapp/$f root@$server:$dirapp/$f;
done

#check if app copied 
if ssh root@$server stat $dirapp/$f \> /dev/null 2\>\&1
then
    echo "all fine";
else
    echo  "Backup: %APPLICATION% app  FAILED" | mail -s "Backup: %APPLICATION% app  FAILED" ayasinsky@helppain.net
fi

dapp=`shasum $dirapp/$f | cut --delimiter=' ' -f 1`;
rapp=`ssh root@$server shasum $dirapp/$f | cut --delimiter=' ' -f 1`;
echo $dapp;
echo $rapp;

if [ $dapp == $rapp ]
then
     echo  "checksum good"
else
     echo  "Backup: %APPLICATION% app  checksum FAILED" | mail -s "Backup: %APPLICATION% app checksum FAILED" ayasinsky@helppain.net
fi


#remove all but last 20 backups
for f in $( ssh root@$server "ls -t $dirdb/*.mongo.zip | tail -n +5" );
    do ssh root@$server "rm $f";
done

#remove all but last 20 backups
for f in $( ssh root@$server "ls -t $dirapp/*.zip | tail -n +5" );
    do ssh root@$server "rm $f";
done

for f in $( ls -tr /var/mail );
    #clean email
    do  > /var/mail/$f ;
done