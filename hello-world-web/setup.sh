#!/bin/sh


name=hello-world-web

#
#optional cleanup before next run
#
aws lambda delete-function --function-name $name
aws iam delete-role --role-name $name-executor

query='items[?name==`'$name'-api`].id'
old_api_id=`aws apigateway get-rest-apis --query $query --output text`
aws apigateway delete-rest-api --rest-api-id=$old_api_id

#
sleep 5

# step 1 - pack up the source code
#
rm $name.zip
cd src
zip ../$name.zip *
cd ..

# step 2 - make the lambda
#

role=`aws iam create-role \
--role-name=$name-executor \
--assume-role-policy-document file://json-templates/lambda-executor.json \
--query Role.Arn --output text`

echo created role $role, waiting for IAM propagation
sleep 10 

function=`aws lambda create-function \
--function-name $name \
--role $role \
--runtime nodejs \
--handler main.handler \
--zip-file fileb://$name.zip \
--query FunctionArn --output text`

echo created function $function

# step 3 - create the web api
#

account_id=`aws iam get-user --query User.UserId --output text`

api_id=`aws apigateway create-rest-api --name $name-api --query id --output text`

aws lambda add-permission \
--region us-east-1 \
--function-name $name \
--statement-id 1 \
--principal apigateway.amazonaws.com \
--action lambda:InvokeFunction \
--source-arn "arn:aws:execute-api:us-east-1:$account_id:$api_id/*/*/*"

query='items[?path==`/`].id'
root_resource=`aws apigateway get-resources --rest-api-id=$api_id --query $query --output text`

hello_resource=`aws apigateway create-resource --rest-api-id=$api_id --parent-id $root_resource --path-part hello --query id --output text`

aws apigateway put-method --rest-api-id $api_id --resource-id $hello_resource --http-method GET --authorization-type none

aws apigateway put-integration \
  --rest-api-id $api_id \
  --resource-id $hello_resource \
  --http-method GET \
  --type AWS \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$function/invocations"


aws apigateway put-method-response \
  --rest-api-id $api_id \
  --resource-id $hello_resource \
  --http-method GET \
  --status-code 200 \
  --response-models '{"text/plain": "Empty", "application/json": "Empty"}'


aws apigateway put-integration-response \
--rest-api-id $api_id \
--resource-id $hello_resource \
--http-method GET \
--status-code 200 \
--response-templates '{"application/json": ""}'


aws apigateway create-deployment \
--rest-api-id $api_id \
--stage-name prod

# step 3 - try it out
#

echo "calling the URL"

curl https://$api_id.execute-api.us-east-1.amazonaws.com/prod/hello

# step 4 - cleanup
#
rm $name.zip
