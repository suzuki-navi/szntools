import os
import re
import subprocess
import sys

import yaml
import boto3
import botocore.exceptions

from .version import VERSION

def main():
    args = sys.argv
    args.pop(0)
    opts = parseArgs(args)
    config = loadConfig()
    if opts['help']:
        print(f'aws_ls_s3 {VERSION}')
    elif opts['s3_bucket'] == None:
        execProfileListS3Buckets(opts['profile'], config)
    elif opts['cat']:
        execCatS3Object(opts['profile'], opts['s3_bucket'], opts['s3_key'], opts['verbose'], opts['if_exists'], config)
    else:
        execListS3Object(opts['profile'], opts['s3_bucket'], opts['s3_key'], opts['recursive'], opts['verbose'], opts['if_exists'], config)

def parseArgs(args):
    profile = None
    s3_bucket = None
    s3_key = '/'
    recursive = False
    verbose = False
    cat = False
    if_exists = False
    help = False
    while args:
        arg = args.pop(0)
        if arg == '--profile':
            if not args:
                print('--profile: expected one argument', file = sys.stderr)
                sys.exit(1)
            profile = args.pop(0)
        elif arg == '-r' or arg == '--recursive':
            recursive = True
        elif arg == '-v':
            verbose = True
        elif arg == '--cat':
            cat = True
        elif arg == '--if-exists':
            if_exists = True
        elif arg == '--help':
            help = True
        else:
            m = re.compile(r's3://([^/]+)(/.*)?\Z').match(arg)
            if m:
                s3_bucket = m.group(1)
                if m.group(2):
                    s3_key = m.group(2)
            else:
                print(f'Illegal format parameter: {arg}', file = sys.stderr)
                sys.exit(1)
    return {
        'profile': profile,
        's3_bucket': s3_bucket,
        's3_key': s3_key,
        'recursive': recursive,
        'verbose': verbose,
        'cat': cat,
        'if_exists': if_exists,
        'help': help,
    }

def configFilePath():
    return os.environ["HOME"] + '/.aws/aws-ls-s3.yml'

def loadConfig():
    try:
        with open(configFilePath()) as file:
            return yaml.safe_load(file)
    except FileNotFoundError:
        pass
    return []

def saveConfig(config):
    with open(configFilePath(), 'w') as file:
        yaml.dump(config, file)

def bucketNameToProfile(bucketName, config):
    profileIdx = 0
    while profileIdx < len(config):
        for bucket in config[profileIdx]['buckets']:
            if bucket == bucketName:
                return config[profileIdx]['profile']
        profileIdx += 1
    return None

def execProfileListS3Buckets(profile, config):
    if profile == None:
        profile = 'default'

    profileIdx = 0
    while profileIdx < len(config):
        if config[profileIdx]['profile'] == profile:
            break
        profileIdx += 1
    if profileIdx == len(config):
        config.append({'profile': profile, 'buckets': []})
    else:
        config[profileIdx]['buckets'] = []

    session = boto3.session.Session(profile_name = profile)
    s3_client = session.client('s3')

    response = s3_client.list_buckets()
    for bucket in response['Buckets']:
        name = bucket['Name']
        if profileIdx >= 0:
            config[profileIdx]['buckets'].append(name)
        print(name)

    saveConfig(config)

def execCatS3Object(profile, s3_bucket, s3_key, verbose, if_exists, config):
    if profile == None:
        profile = bucketNameToProfile(s3_bucket, config)
        if profile == None:
            print(f'Unknown s3 bucket: {bucket}', file = sys.stderr)
            sys.exit(1)

    flag = True

    if if_exists:
        session = boto3.session.Session(profile_name = profile)
        s3_client = session.client('s3')

        obj_exists_flag = False
        try:
            if len(s3_key) > 1:
                s3_client.head_object(
                    Bucket = s3_bucket,
                    Key = s3_key[1:],
                )
                obj_exists_flag = True
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] == "404":
                pass
            else:
                raise
        if not obj_exists_flag:
            flag = False

    if flag:
        commands = ['aws', '--profile', profile, 's3', 'cp', f's3://{s3_bucket}{s3_key}', '-']
        if verbose:
            print(commands, file = sys.stderr)
        result = subprocess.call(commands)
        if result != 0:
            sys.exit(result)

def execListS3Object(profile, s3_bucket, s3_key, recursive, verbose, if_exists, config):
    if profile == None:
        profile = bucketNameToProfile(s3_bucket, config)
        if profile == None:
            print(f'Unknown s3 bucket: {bucket}', file = sys.stderr)
            sys.exit(1)

    dir_path = s3_key
    if not dir_path.endswith('/'):
        dir_path += '/'

    flag = True

    if if_exists:
        session = boto3.session.Session(profile_name = profile)
        s3_client = session.client('s3')

        dir_exists_flag = False
        res = s3_client.list_objects_v2(
            Bucket = s3_bucket,
            Delimiter = '/',
            Prefix = dir_path[1:],
        )
        while True:
            if res.get('Contents', None):
                dir_exists_flag = True
                break
            if res.get('CommonPrefixes', None):
                dir_exists_flag = True
                break
            if not 'ContinuationToken' in res:
                break
            res = s3_client.list_objects_v2(
                Bucket = s3_bucket,
                Delimiter = '/',
                Prefix = dir_path[1:],
                ContinuationToken = res['NextContinuationToken'],
            )
        if not dir_exists_flag:
            flag = False

    if flag:
        if recursive:
            commands = ['aws', '--profile', profile, 's3', 'ls', '--recursive', f's3://{s3_bucket}{dir_path}']
        else:
            commands = ['aws', '--profile', profile, 's3', 'ls', f's3://{s3_bucket}{dir_path}']
        if verbose:
            print(commands, file = sys.stderr)
        result = subprocess.call(commands)
        if result != 0:
            sys.exit(result)

