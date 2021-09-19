const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const ddb = new AWS.DynamoDB.DocumentClient(); 

const Client = require('ssh2-sftp-client');
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


exports.handler = async (event, context, callback) => {
    //async function handler() {
    console.log(event)
    try {

        await getData(event.hostInfo);
        await getConfig(event.hostInfo);
        let readyToFire = false;
        while (!readyToFire) {
            await sleep(1000);
            let params = {
                Bucket: event.hostInfo.testDataBucket,
                Key: "runs/" + event.runId
            };
            await s3.getObject(params).promise().then((data) => {
                readyToFire = true;
            }).catch((e) => {
                readyToFire = false;
            });
        }
        let parallelRuns = event.jobs.map(async (job) => {
            return await runJob(event.runId, event.hostInfo, job)
        })

        await Promise.all(parallelRuns);
        return;
    } catch (e) {
        console.log("handler", e)
    }

}


async function getData(hostConfig) {
    return new Promise((resolve, reject) => {
        const destPath = `${hostConfig.tmpDataPath}/${(hostConfig.testDataPath).split('/').pop()}`
        let params = {
            Bucket: hostConfig.testDataBucket,
            Key: hostConfig.testDataPath,
        };
        const s3Stream = s3.getObject(params).createReadStream();
        const fileStream = fs.createWriteStream(destPath);
        s3Stream.on('error', reject);
        fileStream.on('error', reject);
        fileStream.on('close', () => { resolve(destPath); });
        s3Stream.pipe(fileStream);
    });
}

async function getConfig(hostConfig) {

    return new Promise((resolve, reject) => {
        const destPath = `${hostConfig.tmpDataPath}/${(hostConfig.privateKeyPath).split('/').pop()}`
        let params = {
            Bucket: hostConfig.testDataBucket,
            Key: hostConfig.privateKeyPath,
        };
        const s3Stream = s3.getObject(params).createReadStream();
        const fileStream = fs.createWriteStream(destPath);
        s3Stream.on('error', reject);
        fileStream.on('error', reject);
        fileStream.on('close', () => { resolve(destPath); });
        s3Stream.pipe(fileStream);
    });
}

async function runJob(runId, hostConfig, jobConfig) {
    let jobStatus = {
        "requestId": jobConfig.requestId,
        "status": "Ready",
        "runId": runId
    }
    let stTime = (new Date() * 1);
    let params = {
        TableName: hostConfig.testStatusTBL,
        Item: jobStatus
    };
    try {
        await ddb.put(params).promise();

        stTime = (new Date() * 1);
        let resp = await initiateFTP(hostConfig, jobConfig);

        jobStatus['executionTime'] = ((new Date() * 1) - stTime) / 1000;
        jobStatus['status'] = 'Completed';
        jobStatus['connectTime'] = resp['connectTime'];
        jobStatus['uploadTime'] = resp['uploadTime'];

        await ddb.put(params).promise();
    } catch (e) {
        jobStatus['status'] = 'Error';
        jobStatus['msg'] = e.message;
        jobStatus['executionTime'] = ((new Date() * 1) - stTime) / 1000;
        await ddb.put(params).promise();
        throw e;
    }


}

async function initiateFTP(hostConfig, jobConfig) {
    let sftp = new Client();
    let data = fs.createReadStream(`${hostConfig.tmpDataPath}/${(hostConfig.testDataPath).split('/').pop()}`);
    let ftpMetric = {}
    return new Promise((resolve, reject) => {
        let stTime = (new Date() * 1);
        sftp.connect({
            host: hostConfig.host,
            port: hostConfig.port,
            username: hostConfig.userName,
            passphrase: hostConfig.passPhrase,
            readyTimeout: 20000, // integer How long (in ms) to wait for the SSH handshake
            retries: 2, // integer. Number of times to retry connecting
            retry_factor: 2, // integer. Time factor used to calculate time
            retry_minTimeout: 2000, // integer. Minimum timeout between attempts,
            privateKey: fs.readFileSync(`${hostConfig.tmpDataPath}/${(hostConfig.privateKeyPath).split('/').pop()}`)
        }).then(() => {
            ftpMetric['connectTime'] = ((new Date() * 1) - stTime) / 1000;
            stTime = new Date() * 1
            return sftp.fastPut(`${hostConfig.tmpDataPath}/${(hostConfig.testDataPath).split('/').pop()}`, `${jobConfig.remotePath}`);
        }).then((data) => {
            console.log(data)
            ftpMetric['uploadTime'] = ((new Date() * 1) - stTime) / 1000;
            return sftp.end();
        }).then((data) => {
            resolve(ftpMetric)
        }).catch(err => {
            console.log(err.message)
            reject(err)
        });
    })

}

//handler()
