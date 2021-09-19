import rsa
import sys
from base64 import b64encode, b64decode
keysize = 1024


#Generate Data Keys
(public, private) = rsa.newkeys(keysize)
print(private.exportKey('PEM'))
print(public.exportKey('PEM'))
f = open(str(sys.argv[1])+'-DataPrivate.pem','wb')
f.write(private.exportKey('PEM'))
f.close()

f = open(str(sys.argv[1])+'-DataPublic.pem','wb')
f.write(public.exportKey('PEM'))
f.close()

#Generate Notif Keys
(public, private) = rsa.newkeys(keysize)
print(private.exportKey('PEM'))
print(public.exportKey('PEM'))
f = open(str(sys.argv[1])+'-NotifPrivate.pem','wb')
f.write(private.exportKey('PEM'))
f.close()

f = open(str(sys.argv[1])+'-NotifPublic.pem','wb')
f.write(public.exportKey('PEM'))
f.close()
