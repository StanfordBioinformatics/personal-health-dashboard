#!/bin/bash

#Main - covid : 00000
#Data Collection : 00015
#Data Collection : 00030
#UPenn : 00045
#pip3 install -U PyCryptodome
#sudo sh -c "/usr/local/bin/src/key_management.sh 1 new /usr/local/bin/src/ phd-key-duplicate-check phd-notif-encryption-keys phd-ids-mapping phd-priv-keys phd-k8s-auth-prod-keys-hawk phd-k8s-auth-prod-keys phd-customer-keys phd-user-key-map"
export AWS_DEFAULT_REGION=us-west-2

numberOfUsers=$1

if [[ $# -eq 0 ]] ; then
    echo 'Please set arg1=numOfUsers'
    exit 0
fi

studyID=$2

#LBAddress='phd.innovations.stanford.edu:5222'

# Please edit the following variables to appropriate ones:
# Change this to the current path (Where you have this file itself (generator.sh), KeyGenerate.py, and rsa.py files)
path=$3
dedupTbl=$4
notifS3Bucket=$5
mappingS3Bucket=$6
privKeysS3Bucket=$7
authKeysHawkS3Bucket=$8
authKeysS3Bucket=$9
customerKeyBucket="${10}"
userKeyMapTbl="${11}"


#Create bucket on Clam to store id1, id2, username
#gsutil mb -p gbsc-gcp-project-clam gs://auth-duplicate-check

echo $numberOfUsers

for i in {1..$numberOfUsers}
do
    #Generate MyPHD-ID (Username) 1 and 2
	randLowercase=$(head -80 /dev/urandom| LC_ALL=C tr -dc 'a-z' | fold -w 16 | head -n 1)
    randLowerDigit=$(head -80 /dev/urandom| LC_ALL=C tr -dc 'a-z0-9' | fold -w 16 | head -n 1)
    username=$studyID$randLowercase$randLowerDigit
    randAll=$(head -80 /dev/urandom| LC_ALL=C tr -dc 'a-zA-Z0-9!?#' | fold -w 12 | head -n 1)
    pass=$randAll
    
    randLowercase=$(head -80 /dev/urandom| LC_ALL=C tr -dc 'a-z' | fold -w 16 | head -n 1)
    randLowerDigit=$(head -80 /dev/urandom| LC_ALL=C tr -dc 'a-z0-9' | fold -w 17 | head -n 1)
    username2=$studyID$randLowercase$randLowerDigit
    randAll=$(head -80 /dev/urandom| LC_ALL=C tr -dc 'a-zA-Z0-9!?#' | fold -w 12 | head -n 1)
    pass2=$randAll
    
    randDigit1=$(head -80 /dev/urandom| LC_ALL=C tr -dc '1-9' | fold -w 16 | head -n 1)
    randDigit2=$(head -80 /dev/urandom| LC_ALL=C tr -dc '1-9' | fold -w 17 | head -n 1)
    
    id1=$randDigit1
    id2=$randDigit2
	cval=$(shuf -i 1000-3000 -n 1)
	cval2=$(shuf -i 1-4 -n 1)
    rand_year=$(shuf -i 2019-2020 -n 1)
    rand_month=$(shuf -i 1-9 -n 1)
    rand_day=$(shuf -i 1-9 -n 1)
    startdate="$rand_year-0$rand_month-0$rand_day"
	#startdate='2019-04-01'
 
    #STEP0: Make sure these credentials are all unique; if not, regenerate
    echo "Checking ID duplication"

    id1Exist=`aws dynamodb get-item --table-name $dedupTbl --key "{\"id\": {\"S\": \"${id1}\"}}" --consistent-read`
    id2Exist=`aws dynamodb get-item --table-name $dedupTbl --key "{\"id\": {\"S\": \"${id2}\"}}" --consistent-read`
    user1Exist=`aws dynamodb get-item --table-name $dedupTbl --key "{\"id\": {\"S\": \"${username}\"}}" --consistent-read`
    user2Exist=`aws dynamodb get-item --table-name $dedupTbl --key "{\"id\": {\"S\": \"${username2}\"}}" --consistent-read`

    #if [ gsutil stat "gs://auth-duplicate-check/$username" == 1 ] || [ gsutil stat "gs://auth-duplicate-check/$id1" == 1 ] || [ gsutil stat "gs://auth-duplicate-check/$id2" == 1 ] ;  then
    while  [ ! -z "$id1Exist" ] || [ ! -z "$id2Exist" ] || [ ! -z "$user1Exist" ] || [ ! -z "$user2Exist" ]
    do
        randLowercase=$(head -80 /dev/urandom| LC_ALL=C tr -dc 'a-z' | fold -w 16 | head -n 1)
        randLowerDigit=$(head -80 /dev/urandom| LC_ALL=C tr -dc 'a-z0-9' | fold -w 16 | head -n 1)
        username=$studyID$randLowercase$randLowerDigit
        randAll=$(head -80 /dev/urandom| LC_ALL=C tr -dc 'a-zA-Z0-9!?#' | fold -w 12 | head -n 1)
        pass=$randAll
        
        randLowercase=$(head -80 /dev/urandom| LC_ALL=C tr -dc 'a-z' | fold -w 16 | head -n 1)
        randLowerDigit=$(head -80 /dev/urandom| LC_ALL=C tr -dc 'a-z0-9' | fold -w 17 | head -n 1)
        username2=$studyID$randLowercase$randLowerDigit
        randAll=$(head -80 /dev/urandom| LC_ALL=C tr -dc 'a-zA-Z0-9!?#' | fold -w 12 | head -n 1)
        pass2=$randAll
        
        randDigit1=$(head -80 /dev/urandom| LC_ALL=C tr -dc '1-9' | fold -w 16 | head -n 1)
        randDigit2=$(head -80 /dev/urandom| LC_ALL=C tr -dc '1-9' | fold -w 17 | head -n 1)
        
        id1=$randDigit1
        id2=$randDigit2

        id1Exist=`aws dynamodb get-item --table-name $dedupTbl --key "{\"id\": {\"S\": \"${id1}\"}}" --consistent-read`
        id2Exist=`aws dynamodb get-item --table-name $dedupTbl --key "{\"id\": {\"S\": \"${id2}\"}}" --consistent-read`
        user1Exist=`aws dynamodb get-item --table-name $dedupTbl --key "{\"id\": {\"S\": \"${username}\"}}" --consistent-read`
        user2Exist=`aws dynamodb get-item --table-name $dedupTbl --key "{\"id\": {\"S\": \"${username2}\"}}" --consistent-read`

    done
    
    echo "Duplication check is done"
    echo "MyPHD_ID and MyPHD_ID2 created"
    echo $username
    echo $username2

	# Create ssh public and private keys
	ssh-keygen -m PEM -t rsa -b 2048 -C "$username" -P "$pass" -f $path$username
    ssh-keygen -m PEM -t rsa -b 2048 -C "$username2" -P "$pass2" -f $path$username2

	# Create Data and Notif Public and Private keys
	python3 keyGenerate.py $username

	# Creating files #key used for encrypting data on phone
	dataEncryptKey=$(<"$username-DataPublic.pem")

	dataDecryptKey=$(<"$username-DataPrivate.pem")
	notifDecryptKey=$(<"$username-NotifPrivate.pem")
	notifEncryptKey=$(<"$username-NotifPublic.pem")
	sshpublic=$(<"$username.pub")
	sshprivate=$(<"$username")
    sshpublic2=$(<"$username2.pub")
    sshprivate2=$(<"$username2")


	#STEP1: Send these credentials to a bucket and upload to Google cloud for uniqueness tracking
	printf $username'\n'$pass'\n'$username2'\n'$pass2'\n'"$dataEncryptKey*********$notifDecryptKey*********$sshpublic*********$sshprivate*********$sshpublic2*********$sshprivate2*********$id1*********$id2*********$cval*********$cval2*********$startdate"  >> authentication/"$username.txt"
	touch authentication/$username
    touch authentication/$username2
	touch authentication/$id1
	touch authentication/$id2
    
        
    aws dynamodb put-item --table-name $dedupTbl  --item "{\"id\": {\"S\": \"${username}\"}}" 
    aws dynamodb put-item --table-name $dedupTbl  --item "{\"id\": {\"S\": \"${username2}\"}}" 
    aws dynamodb put-item --table-name $dedupTbl  --item "{\"id\": {\"S\": \"${id1}\"}}" 
    aws dynamodb put-item --table-name $dedupTbl  --item "{\"id\": {\"S\": \"${id2}\"}}" 

	#STEP1.1: Send customer keys to bucket for now.. later we have to put this in redcap
	aws s3 cp ./authentication/"$username.txt" s3://$customerKeyBucket/"$username"/     

	#STEP2: Send public keys to Eagle authentication k8s bucket - sftp pub key
	echo $sshpublic > authentication/"$username.pub"
	aws s3 cp ./authentication/"$username.pub" s3://$authKeysS3Bucket/"$username"/ 
 
    #STEP3: Send public keys to Hawk authentication k8s bucket 
    echo $sshpublic2 > authentication/"$username2.pub"
    #gsutil mv authentication/"$username2.pub" gs://k8s-auth-prod-keys-hawk/"$username2"/
	aws s3 cp ./authentication/"$username2.pub"  s3://$authKeysHawkS3Bucket/"$username2"/

	#STEP4: Send the ID/CVALs/Decryption key to owl project with new format  - private key for sftp, also to decrypt data
	echo  -e "$cval\t$cval2\t$startdate\t$dataDecryptKey" > authentication/"$id1".txt
	#gsutil mv authentication/"$id1.txt" gs://priv_keys/newDecryptKeys200722/
 	aws s3 cp ./authentication/"$id1.txt" s3://$privKeysS3Bucket/newDecryptKeys200722/ 

    aws dynamodb put-item --table-name $userKeyMapTbl  --item "{\"userName\": {\"S\": \"${username}\"},\"userid\": {\"S\": \"${id1}\"},\"decryptKey\": {\"S\": \"s3://$privKeysS3Bucket/newDecryptKeys200722/"$id1.txt"\"},\"encryptKey\": {\"S\": \"s3://$customerKeyBucket/"$username"/"$username.txt"\"},\"pubKey\": {\"S\": \"s3://$authKeysS3Bucket/"$username"/"$username.pub"\"} ,\"studyId\": {\"S\": \""$studyID"\"}}" 


    #STEP5: Send the Notif Encryption key to owl project bucket
    echo  -e "$notifEncryptKey" > authentication/"$id1-notifEnc".txt
    #gsutil mv authentication/"$id1-notifEnc".txt gs://notif_encryption_keys/
    aws s3 cp ./authentication/"$id1-notifEnc".txt s3://$notifS3Bucket/ 
    
    #STEP6: Create dataset on Owl BQ
    #bq  mk --dataset gbsc-gcp-project-owl:"$id1"
    
    #STEP7: Add id1<->username2 maps on owl
    #gsutil mv authentication/$username gs://ids-mapping/"$id1"/$username2".txt"
    aws s3 cp authentication/$username s3://$mappingS3Bucket/"$id1"/$username2".txt" 
    
    rm -f "$username-DataPrivate.pem"
    rm -f "$username-DataPublic.pem"
    rm -f "$username-NotifPrivate.pem"
    rm -f "$username-NotifPublic.pem"
    rm -f "$username"
    rm -f "$username2"
    rm -f "$username.pub"
    rm -f "$username2.pub"
    rm -f authentication/"$username.pub"
    rm -f authentication/"$username2"

echo "done"
done

