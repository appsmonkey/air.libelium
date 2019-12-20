# Amazon Web Srvices integration overview

To integrate Libelium Plug & Sense devices and its sensors with our platform we need to use several AWS provided services to recieve, handle and store the sensor readings sent by Libelium.

## Lambda function

Lambda function handles the data recieved by the API gateway and stores it into the database.
[Details are here](lambda.md)

## API gateway

API gateway recieves the data sent by Libelium and depending on its form and type forwards it to lambda function.
[Details are here](api_gateway.md)

## CloudFront

CloudFront serves as the endpoint to which Libelium sends HTTP request with data that needs to be securely forwarded onto API gateway.
[Details are here](cloudfront.md)
