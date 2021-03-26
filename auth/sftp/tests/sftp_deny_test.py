# Author: Sushil Upadhyayula

import pysftp
import paramiko
import time
from M2Crypto import RSA
from multiprocessing import Pool

#Values for Kubernetes cluster
myHostname = os.environ['HOST_NAME']
myPort = 5222
#PySFTP will block it unless you initialize this to None (doesn't prevent against man-in-the-middle attacks though)
myCnopts = pysftp.CnOpts()
myCnopts.hostkeys = None
keysDir = "keys"

class SFTP:
	def __init__(self):
		super().__init__()
		self.error_count = 0

	# Sends SFTP request for a single user
	def connect(self, user):
		myUsername = user
		myPrivateKey = f"{keysDir}/{user}"
		time1 = time.time()
		try:
			with pysftp.Connection(host=myHostname, username=myUsername, private_key=myPrivateKey, port=myPort, cnopts=myCnopts) as sftp:
				time2 = time.time()
				print("Connection time: ", time2-time1)
				sftp.close()
		except (paramiko.ssh_exception.SSHException, pysftp.exceptions.ConnectionException):
			print(f'{user}: timed out which is expected.')
			self.error_count += 1
		else:
			print(f'Error: {user} should have timed out but did not.')

if __name__ == '__main__':
	#Make username
	nConcurrentRequests = 200
	users = [os.environ['USERNAME']] * 200
	# for i in range(nConcurrentRequests):
	# 	username = userBase + str(str(i).zfill(5))
	# 	users.append(username)  #make the username
	# 	key = RSA.gen_key(2048, 65537)
	# 	key.save_pem(f'{keysDir}/{username}.pem', cipher=None)
	# 	key.save_pub_key(f'{keysDir}/{username}.pub')

	print('Users: ', users)
	p = Pool(nConcurrentRequests) #Multi-processing
	sftp_instance = SFTP()
	p.map(sftp_instance.connect, users)
	p.close()
	p.join()

	print(f'sftp_instance.error_count: {sftp_instance.error_count}')
	print(f'nConcurrentRequests: {nConcurrentRequests}')
	assert sftp_instance.error_count == nConcurrentRequests
