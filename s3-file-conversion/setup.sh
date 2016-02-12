#!/bin/sh
#
name=s3-file-conversion
#you may need to specify a unique bucket name
account_id=`aws iam get-user --query User.UserId --output text`
bucket=$name-$account_id

echo $name $bucket $account_id

aws s3api create-bucket --bucket $bucket

if [ $? -eq 0 ]; then
  echo created bucket $bucket
else
  echo "failed to create bucket $bucket - change the name in the script before proceeding"
  exit 1
fi


#optional cleanup before next run
#

#aws lambda delete-function --function-name $name-function
#aws iam delete-role-policy --role-name $name-lambda-executor --policy-name s3-bucket-access
#aws iam delete-role-policy --role-name $name-lambda-executor --policy-name logwatch-writer
#aws iam delete-role --role-name $name-lambda-executor
#aws s3 rm --recursive s3://$bucket/out/

#
# step 1 - pack up the source code
#

rm $name.zip
cd src
npm install
zip ../$name.zip *
cd ..



# step 2 - make the lambda
#

role=`aws iam create-role \
  --role-name=$name-lambda-executor \
  --assume-role-policy-document file://json-templates/lambda-exector-policy.json \
  --query Role.Arn --output text`

echo created role $role

aws iam put-role-policy \
  --role-name $name-lambda-executor \
  --policy-name logwatch-writer \
  --policy-document file://json-templates/log-writer.json

bucketpolicy=`sed s#\$\{bucket-name\}#$bucket# json-templates/s3-bucket-access.json`

aws iam put-role-policy \
  --role-name $name-lambda-executor \
  --policy-name s3-bucket-access \
  --policy-document "$bucketpolicy"

echo pausing so IAM role propagates to Lambda
sleep 10

function=`aws lambda create-function \
--function-name $name-function \
--role $role \
--runtime nodejs \
--handler main.handler \
--zip-file fileb://$name.zip \
--query FunctionArn --output text`

echo created function $function

## step 3: add the permission to invoke lambda to the S3 resource

aws lambda add-permission \
--region us-east-1 \
--function-name $name-function \
--statement-id 1 \
--principal s3.amazonaws.com \
--action lambda:InvokeFunction \
--source-arn arn:aws:s3:::$bucket \
--source-account $account_id

## step 4: wire in S3 events

bucketnotification=`sed s#\$\{function-arn\}#$function# json-templates/bucket-notification.json`

aws s3api put-bucket-notification-configuration \
  --bucket $bucket \
  --notification-configuration "$bucketnotification"


## step 5: now upload a file for conversion to lambda

aws s3 cp setup.sh s3://$bucket/in/for-conversion.txt

echo uploaded file to S3. Wait a few seconds and then list the results using
echo aws s3 ls  s3://$bucket/out/

rm $name.zip
