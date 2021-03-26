# About
This contains code for the front-end authentication piece of the PHD system

## Infrastructure
All infrastructure is provisioned using Terraform. For deployment details, visit [tf README](tf/README.md)

## SFTP Tests
Tests already run:
 - Sending 1-4096 concurrent requests of 100MB JSON file from 8 locations worldwide (simulate initial upload)
 - Sending 16-4096 concurrent requests of < 1MB JSON file from 8 locations worldwide (simulate continuous updates)
 - Sending 16-409 concurrent requests of 80% <1MB and 20% 100MB JSON files from 8 locations worldwide (simulate real workflow)
 
 
What it does: Sends user-specified number of requests to the SFTP server (uploading a 100MB JSON file - sample.JSON)
To run:
1. Specify nConcurrentRequests in line 36
2. Run with "python sftp_test.py" *Note: Don't use Python 3

*Note: You have to have a JSON file to test with. I just used this: https://github.com/seductiveapps/largeJSON/blob/master/100mb.json
