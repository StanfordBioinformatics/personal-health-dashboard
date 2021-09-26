'use strict';
const AWS = require("aws-sdk");
const ec2 = new AWS.EC2();
const s3 = new AWS.S3();
const fs = require('fs');
const { exec } = require("child_process");

let ddb = new AWS.DynamoDB.DocumentClient();
let ec2InstanceProfile = process.env.EC2_INSTANCE_PROFILE || 'arn:aws:iam::294170747177:instance-profile/prod-image-archiver-ec2-role';
let ec2SG = process.env.EC2_SG || 'sg-0b13b30f2345cf61e';
let ec2AMI = process.env.EC2_AMI || 'ami-0c2b8ca1dad447f8a';
let ec2InstanceType = process.env.EC2_INSTANCE_TYPE || 't3.large';
let subnet = process.env.EC2_SUBNET || 'subnet-f25b63df';

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

exports.handler = async(event, context, callback) => {
    console.log("event", JSON.stringify(event));
    try {
        let script = fs.readFileSync('./script.txt', { encoding: 'utf8', flag: 'r' });
        let keyScript = fs.readFileSync('./key_management.sh', { encoding: 'utf8', flag: 'r' });
        let rsaPy = fs.readFileSync('./rsa.py', { encoding: 'utf8', flag: 'r' });
        let keyGeneratePy = fs.readFileSync('./keyGenerate.py', { encoding: 'utf8', flag: 'r' });
        console.log("keyScript", keyScript)
        script = `#!/bin/bash
                export AWS_DEFAULT_REGION=${process.env.AWS_REGION}
                export PATH=/sbin:/bin:/usr/sbin:/usr/bin:$PATH
                
                ${script}                
                cat > key_management.sh<<'EOF'
                export AWS_DEFAULT_REGION=${process.env.AWS_REGION}
                ${keyScript}\nEOF\n
                cat > keyGenerate.py<<'EOF'
${keyGeneratePy}\nEOF\n                
cat > rsa.py<<'EOF'
${rsaPy}\nEOF\n
chmod +x key_management.sh
sudo sh -c "/usr/local/bin/src/key_management.sh ${event.numberOfKeys} ${event.studyID} /usr/local/bin/src/ ${process.env.DEDUP_TBL} ${process.env.NOTIF_BUCKET} ${process.env.MAPPING_BUCKET} ${process.env.PRIVATE_KEY_BUCKET} ${process.env.AUTH_HAWK_BUCKET} ${process.env.AUTH_BUCKET} ${process.env.CUSTOMER_KEY_BUCKET} ${process.env.USER_KEY_MAP_TBL}"
                `            
            //script = script + '\nEOF';
            script = script + `
        aws ec2 terminate-instances --instance-ids $INSTANCE_ID  --region ${process.env.AWS_REGION}
        `


        console.log("script", script)

        let params = {
            MaxCount: 1,
            MinCount: 1,
            IamInstanceProfile: {
                Arn: ec2InstanceProfile
            },
            ImageId: ec2AMI,
            InstanceType: ec2InstanceType,
            Monitoring: {
                Enabled: true
            },
            SecurityGroupIds: [
                ec2SG,
            ],
            SubnetId: subnet,
            UserData: (Buffer.from(script)).toString('base64'),
            TagSpecifications: [{
                ResourceType: "instance",
                Tags: [{
                    Key: 'PROCESS',
                    Value: 'KeyGenerator'
                }]
            }, ],
        };
        let resp = await ec2.runInstances(params).promise();
        console.log(resp)

    }
    catch (e) {
        console.log(e)
    }


};
