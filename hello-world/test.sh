#!/bin/sh
#
#optional cleanup before next run
#
#aws lambda delete-function --function-name hello-world-function
#aws iam delete-role --role-name hello-world-lambda-executor
#
#sleep 5

# step 1 - pack up the source code
#
rm hello-world.zip
cd src
zip ../hello-world.zip *
cd ..

# step 2 - make the lambda
#

role=`aws iam create-role \
--role-name=hello-world-lambda-executor \
--assume-role-policy-document '{"Version": "2012-10-17", "Statement": [{"Effect": "Allow","Principal": {"Service": "lambda.amazonaws.com"},"Action": "sts:AssumeRole"}]}' \
--query Role.Arn --output text`

echo created role $role
sleep 5

function=`aws lambda create-function \
--function-name hello-world-function \
--role $role \
--runtime nodejs \
--handler main.handler \
--zip-file fileb://hello-world.zip \
--query FunctionArn --output text`

echo created function $function

# step 3 - try it out
#

sleep 5

aws lambda invoke --function-name hello-world-function outfile

cat outfile

# step 4 - cleanup
#
rm outfile
rm hello-world.zip
