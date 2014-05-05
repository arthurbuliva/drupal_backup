#! /bin/bash
#
# drupalbackup.sh, v 0.1.3, last revised 14 May 2014
#
# Backs up drupal 6 installations
# 
# By Arthur Buliva - arthurbuliva@gmail.org

if [ $# -lt 2 ] 
then
    echo -e "\nUsage: $0 drupal_directory_path backup_directory_path\n"
    exit 1
fi

# Step 1
# Check if there is a sites/default/settings.php file in the specified directory
DRUPAL=$1
BACKUP="$2/"
SETTINGS="$DRUPAL/sites/default/settings.php"
BASENAME=`basename $DRUPAL`

if [ -f  $SETTINGS ] 
then
	echo -e "\nSettings file found at $SETTINGS\n"
	USERNAME=`grep db_url $SETTINGS | grep -vi "*" |  cut -d':' -f2 | sed 's/\///g'`
	PASSWORD=`grep db_url $SETTINGS | grep -vi "*" |  cut -d':' -f3 | cut -d"@" -f1`
	
	#We need the replacement patterns for Drupal passwords as specified in the settings file

	PASSWORD=`echo $PASSWORD | sed "s/%3a/:/g" | sed "s/%2f/\//g" | sed "s/%40/@/g" | \
	sed "s/%2b/+/g" | sed "s/%28/(/g" | sed "s/%29/)/g" | \
	sed "s/%3f/?/g" | sed "s/%3d/=/g" | sed "s/%26/&/g"`
	
	HOST=`grep db_url $SETTINGS | grep -vi "*" |  cut -d':' -f3 | cut -d"@" -f2 | cut -d"/" -f1`
	DATABASE=`grep db_url $SETTINGS | grep -vi "*" |  cut -d':' -f3 | cut -d"@" -f2 | cut -d"/" -f2 | sed "s/';//g"`
	
	#Now create a folder in the specified directory path
	BACKUPDIR="$BACKUP$BASENAME"
	mkdir -pv $BACKUPDIR
	
	#Dump the MySQL database into the backup folder
	echo -ne "Saving database\t"
	mysqldump -u $USERNAME -p$PASSWORD -h $HOST $DATABASE > "$BACKUPDIR/$DATABASE.sql"
	echo "    [DONE] "
	
	#Copy the files into the backup folder
	echo -ne "Copying files\t"
	cp -rf $DRUPAL $BACKUPDIR
	echo "    [DONE] "
	
	#Compress the entire foder
	echo -ne "Compressing folder\t"
	cd $BACKUP
	tar -cf $BASENAME.tar $BASENAME
	gzip $BACKUPDIR.tar
	echo "    [DONE] "
	
	#Remove temporary files
	echo -ne "Removing temporary files\t"
	rm -rf $BASENAME
	echo "    [DONE] "
	
	#Display end message
	echo -e "\nYour backup has completed. The file is $BACKUP/$BASENAME.tar.gz"
	
	exit 0
	
else
	echo -e "\nNo valid settings file found at $SETTINGS\n"
    exit 1
fi
