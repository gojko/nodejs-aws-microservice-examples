# nodejs-aws-microservice-examples

Examples for Node.JS AWS microservices. To run the code, you'll need the [AWS CLI tools](https://aws.amazon.com/cli/). 

Lambda functions are bound to a specific region, so make sure to define the region in your config file (see the [AWS CLI Docs](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-config-files) for instructions). 
Also, you might need to use a profile that has admin access to IAM and Lambda object creation. I strongly suggest creating a secondary profile with such access, so you don't accidentally mess things up with your primary profile, and then activating
that profile before running scripts using

````
export AWS_DEFAULT_PROFILE=user2
````

See the _Named Profiles_ section in the AWS CLI docs for more information
