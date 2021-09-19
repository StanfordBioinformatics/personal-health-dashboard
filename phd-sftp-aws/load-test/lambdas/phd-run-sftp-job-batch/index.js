const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const lambda = new AWS.Lambda();
const uuidv1 = require('uuid/v1');


const ddb = new AWS.DynamoDB.DocumentClient();

/*
let data = fs.createReadStream('/Users/amdixit/.ssh/amit.txt');
let remote = 'c.txt';
let host = process.env.HOST || 's-7846a3dbc01d42f5b.server.transfer.us-west-2.amazonaws.com';
let port = process.env.PORT || '22';
let userName = process.env.USER_NAME || 'amit';
let passPhrase = process.env.PASSPHRASE || 'amit';
let testStatusTBL = process.env.TEST_STATUS_TBL || 'phd-sftp-load-test-status';
let testDataBucket = process.env.TEST_DATA_BUCKET || 'phd-sftp-load-test';
*/
let fs = require('fs');


function sleep(ms) {
    console.log('Waiting for ', ms)
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function writeFile(bucket, key) {
    let params = {
        "Body": Buffer.from('kickoff-job', 'utf8'),
        "Bucket": bucket,
        "Key": key
    };
    await s3.putObject(params).promise();
}

async function deleteFile(bucket, key) {
    let params = {
        "Bucket": bucket,
        "Key": key
    };
    await s3.deleteObject(params).promise();
}

exports.handler = async (event, context, callback) => {
    console.log(event)

    try {
        await deleteFile(event.config.hostInfo.testDataBucket, `runs/${event.config.runId}`)


        for (let i = 0; i < event.config.numOfContainers; i++) {
            let jobs = [];
            for (let j = 0; j < event.config.threadsPerContainer; j++) {
                let requestId = uuidv1();
                jobs.push({
                    "requestId": requestId,
                    "remotePath": `out/${requestId}/${event.config.hostInfo.testDataPath.split("/").pop()}`
                })
            }
            let payload = {
                runId: event.config.runId,
                hostInfo: event.config.hostInfo,
                jobs: jobs
            }
            let params = {
                FunctionName: event.config.jobLambdaArn, /* required */
                InvocationType: 'Event',
                Payload: JSON.stringify(payload)
            };
            await lambda.invoke(params).promise();
        }

        await sleep(20000);
        await writeFile(event.config.hostInfo.testDataBucket, `runs/${event.config.runId}`)

    } catch (e) {
        console.log("handler", e)
    }

}
