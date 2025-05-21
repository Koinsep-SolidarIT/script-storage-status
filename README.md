# script-storage-status
a script which runs daily and reports the status of your storage devices

this is a script which i run daily to collect storage data from various linux servers, insert them to a mysql database and display them via some php pages.
to collect the data on the remote servers, you need HDsentinel, which can be downloaded for free from here: https://www.hdsentinel.com/download.php

first of all, create the database and the tables. my database is called sentinel and you can find the scripts in /sql folder.

second, copy all_storage.sh and import_storage_data.sh to your /usr/local/bin folder
edit import_storage_data.sh to match your database credentials.
setup the passwordless ssh login to the remote server.
you can find a guide here: https://www.strongdm.com/blog/ssh-passwordless-login

try to run it ./import_storage_data.sh <remote server ip or name> <port>
check the results.log which will be created in /usr/local/bin

then, copy the contents of folder www to your /var/www/html/storage folder.
edit db.php to match your database credentials
go to <your web server>/storage to view the results.

i run a crontab every day, to call all_storage.sh
inside all_storage.sh i have all the servers i want to connect.
you can see it live here:
https://noc.ad110.gr/storage/

![Screenshot 2025-05-21 at 12 57 03 PM](https://github.com/user-attachments/assets/aeaef320-4b62-4a15-835f-df1a069eb9de)

