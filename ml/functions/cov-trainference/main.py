import os
import json
from google.cloud import bigquery, storage, pubsub_v1

KEYS = ['pid', 'study', 'args', 'last_sync', 'is_trainfer', 'last_sync_update']

def validate_json(json):
    # Same lengths.
    if len(json) != len(KEYS): return False

    # Same keys.
    for key in KEYS:
        if key not in json: return False

    return True


def check_request():
    if not request.is_json:
        return True, ('Request must include a JSON.', status.HTTP_400_BAD_REQUEST)
    if not validate_json(request.get_json()):
        return True, ('Request contained malformed JSON.', status.HTTP_400_BAD_REQUEST)

    return False, None


def preprocessing(request):
    """Responds to any HTTP request.
    Args:
        request (flask.Request): HTTP request object.
    Returns:
        The response text or any set of values that can be turned into a
        Response object using
        `make_response <http://flask.pocoo.org/docs/1.0/api/#flask.Flask.make_response>`.
    """

    request_json = request.get_json()
    print(request_json)
    last_sync_string1="01-01-01"
    project_id = os.getenv('GCP_PROJECT')
    client = storage.Client()
    #pull the last sync
    try:
        last_sync_bucket = client.get_bucket('last_sync_dates')
        last_sync_fname =  request_json['pid']
        last_sync_blob = last_sync_bucket.get_blob(last_sync_fname)
        last_sync_string1 = last_sync_blob.download_as_string().decode("utf-8")
        print ("Here is your last sync: ", last_sync_string1 )
    except:
        print("An exception occurred for loading last sync")
    #pull the latest record HR record timestamp
    #Send to BigQuery
    bq_client = bigquery.Client(project_id)
    QUERY1 = 'SELECT max (datetime) as max_datetime  FROM ( SELECT CONCAT(Start_Date,\" \" ,Start_Time) as datetime FROM `{}.{}.Heartrate`)'.format(project_id, request_json['pid'])
    print("Query1: ", QUERY1)
    query_job=bq_client.query(QUERY1)
    print("Query Job: ", query_job)
    row_df = query_job.result().to_dataframe()
    print("row_df: ", row_df)
    print("Head: ", row_df.head())
    print("Val1: ", row_df.max_datetime[0])

    QUERY2 = 'SELECT max (datetime) as max_datetime  FROM ( SELECT CONCAT(Start_Date,\" \" , substr(Start_Time,0,8)) as datetime FROM `{}.{}.Step`)'.format(project_id, request_json['pid'])
    query_job2=bq_client.query(QUERY2)
    row_df2 = query_job2.result().to_dataframe()
    print("row_df2: ", row_df2)
    print("Head: ", row_df2.head())
    print("Val2: ", row_df2.max_datetime[0])

    if row_df.max_datetime[0] > row_df2.max_datetime[0]:
        new_sync = row_df2.max_datetime[0]
    else:
        new_sync = row_df.max_datetime[0]

    print("New Sync: ", new_sync)

    if new_sync > last_sync_string1:
        try:
            result = publish_message(json.dumps({
                'pid': request_json['pid'],
                'study': request_json['study'],
                'args': request_json['args'],
                'last_sync': new_sync,
                'is_trainfer': 'True',
                'last_sync_update': request_json['last_sync_update']
            }))
            print(result)
        except:
            print("An issue occurred while publishing a message")
            pass

    if request.args and 'message' in request.args:
        return request.args.get('message')
    elif request_json and 'message' in request_json:
        return request_json['message']
    else:
        return f'End of Scheduler!'


def publish_message(data):
    publisher = pubsub_v1.PublisherClient()
    project_id = os.getenv('GCP_PROJECT')
    topic_id = os.getenv('GCP_TOPIC', 'preprocessing')
    topic_path = publisher.topic_path(project_id, topic_id)

    future = publisher.publish(topic_path, data.encode('utf-8'))
    return future.result(timeout=5.0)
