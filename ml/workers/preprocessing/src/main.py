import json
import os
from argparse import ArgumentParser

from google.cloud import pubsub_v1
from preprocessing import preprocess
from ti_preprocessing import ti_preprocess

KEYS = ['pid', 'study', 'args', 'last_sync', 'is_trainfer', 'last_sync_update']
PUBLISHER = pubsub_v1.PublisherClient()
PROJECT_ID = os.environ.get('GOOGLE_CLOUD_PROJECT', 'phd-project')
TRAINFERENCE_TOPIC = PUBLISHER.topic_path(PROJECT_ID, 'trainference')
TRAIN_TOPIC = PUBLISHER.topic_path(PROJECT_ID, 'inference')


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


def publish_message(payload, topic):
    print('Publishing message to: %s' % topic)
    serialized_data = json.dumps(payload)
    future = PUBLISHER.publish(topic, serialized_data.encode('utf-8'))
    return future.result(timeout=3.0)


def process_message(message):
    error = check_message(message)
    if error:
        print(error)
        return

    data = json.loads(message)
    # Run preprocessing.
    print('Received request to preprocess %s for study %s.' % (data['pid'], data['study']))

    payload_args = {
        'pid': data['pid'],
        'study': data['study'],
        'last_sync': data['last_sync'],
        'last_sync_update': data['last_sync_update']
    }

    if data['is_trainfer']:
        trainfer_args = ti_preprocess(data['pid'], data['study'], data['args'])
        payload = {'args': trainfer_args, **payload_args}
        publish_message(payload, TRAINFERENCE_TOPIC)
    else:
        train_args = preprocess(data['pid'], data['args'])
        publish_message({'args': train_args, **payload_args}, TRAIN_TOPIC)

    return 'Successfully preprocessed data for PID %s in study %s.' % (data['pid'], data['study'])


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
