# personal-health-dashboard SFTP Server Load Test

We wanted to measure the scalability aspect of AWS Transfer service to see what kind of concurrent 
traffic can be supported by each server and when to put more servers into the pool.


# Methodology
We used two lambdas together with an S3 bucket and Dynamodb to run the test.

phd-run-sftp-job - Implements a logic that would allow X number of concurrent connections 
to the sftp server. The first step is to download the 100 mb test data from the bucket
then based on a s3 file based trigger the lambda initiates and uploads 100 mb data on each concurrent
connection.

phd-run-sftp-job - Implements logic to call phd-run-sftp-job in a loop for a batch of Y request. When phd-run-sftp-job receives the request it downlaods the 100 mb test data and then waits for the s3 file based
trigger before initiating the connection and uploading the data. phd-run-sftp-job-batch sets the s3 file trigger
once it has spun of Y number of lambdas and each are ready with their test data downloaded. Each lambda writes the result into dynamodb with connection time and total time taken for the upload.

We preferred lambda to the test because that gives us completeled isolate run time env which is close relica of  real life traffic.

## [load-test results](results/sftp-load-test-results.png)



