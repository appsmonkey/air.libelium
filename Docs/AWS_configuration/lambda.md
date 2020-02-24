# Lambda Function

AWS Lambda is an event-driven, serverless computing platform provided by Amazon as a part of the Amazon Web Services. It is a computing service that runs code in response to events and automatically manages the computing resources required by that code.

## Implementation

```python
import json
import boto3
```
Firstly we are going to import dependencies needed by our function. 

**boto3** is Amazon library that allows us to use AWS specific functions and functionalty, in this scenario we need it to update IoT device shadow with the data received by Lambda function.

**json** allows us to manipulate JSON objects, it is needed here because the data that is received by our function is in JSON format.

```python
client = boto3.client('iot-data')
```

_client_ object that is initiated here is used to connect to MQTT brocker and pass the new data to the shadow.

```python
def lambda_handler(event, context):

    topic_base = "dt/air/sarajevo/"
    thing = event.pop('thingName', None)
```

_lambda_handler_ is the main part of our lambda function it contains the code that is going to be executed whenever the lambda receives some data prom the API gateway, and it is going to update the coresponding _thing shadow_ with that data.

Every thing has its own MQTT topic, on which it is subscribed and listens for new messages. All of our things' topics beggin with the following string: **"dt/air/sarajevo/"**
and finnish with the *thingName*

We extract thing name from the *event* object that represents the data received by lambda function.

```python
    if thing is not None:
        topic=topic_base+thing

        response = client.publish(
            topic=topic,
            qos=0,
            payload=json.dumps(event)
        )
```

If the event object really contains the thingName, we construct the full topic path by adding thing name to topic base string.

After the topic path is ready we pass it to *client* object together with the data which we want to update thing shadow with, and client publishes it. If all goes well the thing shadow will be updated as soon as the data is published.
