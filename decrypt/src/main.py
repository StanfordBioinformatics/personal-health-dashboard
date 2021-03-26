from argparse import ArgumentParser

def process_message(message):
    print('this is a no-op and required custom logic for decryption.')

def parse_args():
    arg_parser = ArgumentParser(description='Server for decrypting data.')
    arg_parser.add_argument('-d', '--debug', action='store_true',
                            help='enable debugging mode (not intended for production)')
    arg_parser.add_argument('-m', '--message', dest='message', action='store', type=str,
                            help='PubSub message - json encoded str')
    args = arg_parser.parse_args()

    return args


if __name__ == '__main__':
    args = parse_args()
    process_message(args.message)
