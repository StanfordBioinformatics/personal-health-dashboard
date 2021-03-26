import json
import os
from argparse import ArgumentParser

from google.cloud import storage as st
from trainference import trainference

KEYS = ['pid', 'study', 'args', 'last_sync', 'last_sync_update']


def validate_json(s):
    data = json.loads(s)
    # Same lengths.
    if len(data) != len(KEYS): return False

    # Same keys.
    for key in KEYS:
        if key not in data: return False

    return True


def check_message(message):
    if not message:
        return 'Message must include data.'
    if not validate_json(message):
        return 'Message "{}" contains malformed JSON.'.format(message)

    return None


def update_last_sync_date(last_sync_bucket, filename, last_sync_date_str, is_trainfer_str, args_str):
    stCL = st.Client()
    bucket = stCL.get_bucket(last_sync_bucket)
    new_blob = bucket.blob(filename)
    new_blob.upload_from_string('%s\n%s\n%s' % (last_sync_date_str, is_trainfer_str, args_str))


def update_last_sync(last_sync_bucket, filename, last_sync_date_str):
    stCL = st.Client()
    bucket = stCL.get_bucket(last_sync_bucket)
    new_blob = bucket.blob(filename)
    new_blob.upload_from_string('%s' % (last_sync_date_str))


def update_result(result_bucket, filename, result_str):
    stCL = st.Client()
    bucket = stCL.get_bucket(result_bucket)
    new_blob = bucket.blob(filename)
    new_blob.upload_from_string('%s' % (result_str))


def process_message(message):
    error = check_message(message)
    if error:
        print(error)
        return

    data = json.loads(message)
    # # Run inference.
    # data = get_data(data['pid'], data['last_sync'])
    # load_registered_model(data['mlflow_id'])
    (last_sync, result) = trainference(data['pid'])

    if (result == "NOT-FITBIT"):
        print ("NOT-FITBIT")
        return

    #Update Results
    #Update Last Sync
    update_result("<Result Bucket>", data['pid'], result) 
    update_last_sync("Last Sync Bucket", data['pid'], last_sync)

    # update_last_sync_date(data['last_sync_update']['last_sync_bucket'],
    #                       data['last_sync_update']['filename'],
    #                       data['last_sync_update']['last_sync_date_str'],
    #                       data['last_sync_update']['is_trainfer_str'],
    #                       data['last_sync_update']['args_str'])

    # p = Process(target = load_registered_model, args = (data['name'],))
    # p.start()
    print('Now performing trainference with user "%s".' % data['pid'])


def parse_args():
    arg_parser = ArgumentParser(description='Server for preprocessing data.')
    arg_parser.add_argument('-d', '--debug', action='store_true',
                            help='enable debugging mode (not intended for production)')
    arg_parser.add_argument('-m', '--message', dest='message', action='store', type=str,
                            help='PubSub message - json encoded str')
    args = arg_parser.parse_args()

    return args


if __name__ == '__main__':
    args = parse_args()
    process_message(args.message)
