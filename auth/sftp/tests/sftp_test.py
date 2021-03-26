# Author: Sushil Upadhyayula

import pysftp
import time
import os
from multiprocessing import Pool

#Values for Kubernetes cluster
myHostname = os.environ['HOST_NAME']
myPort = 2222
#PySFTP will block it unless you initialize this to None (doesn't prevent against man-in-the-middle attacks though)
myCnopts = pysftp.CnOpts()
myCnopts.hostkeys = None 

# Sends SFTP request for a single user
def connect(user):
	myUsername = user
	myPrivateKey = user + ".pem"
	time1 = time.time()
	with pysftp.Connection(host=myHostname, username=myUsername, private_key=myPrivateKey, port=myPort, cnopts = myCnopts) as sftp:
		time2 = time.time()
		print("Connection time: ", time2-time1)

		# Define the file that you want to upload from your local directorty
		localFilePath = 'sample.json'

		# Define the remote path where the file will be uploaded
		remoteFilePath = myUsername+'_data_6.json'

		sftp.put(localFilePath, remoteFilePath)
		time3 = time.time()
		print("Data transfer time: ", time3-time2)
		sftp.close()

if __name__ == '__main__':
	#Make username
	nConcurrentRequests = 100
	users = []
	userBase = "abc"
	for i in range(nConcurrentRequests):
		users.append(userBase+str(str(i).zfill(5))) #make the username

	print('Users: ', users)
	p = Pool(nConcurrentRequests) #Multi-processing
	p.map(connect, users)
	p.close()
	p.join()