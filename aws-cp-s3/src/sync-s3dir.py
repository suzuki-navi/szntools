import re
import sys

import boto3

src_profile = sys.argv[1]
src_s3_path = sys.argv[2]
dst_profile = sys.argv[3]
dst_s3_path = sys.argv[4]

buf_dir = sys.argv[5]

maxSize = 1_000_000_000
maxCount = 10_000

s3_path_pattern = 's3://([^/]+)(/.*)?'

match = re.match(s3_path_pattern, src_s3_path)
if not match:
    print("illegal s3 path", file = sys.stderr)
    sys.exit(1)
src_bucket = match.group(1)
src_path = ''
if match.group(2):
    src_path = match.group(2)[1:]
else:
    src_path = ""
if len(src_path) > 0 and src_path[-1:] != "/":
    src_path = src_path + "/"

match = re.match(s3_path_pattern, dst_s3_path)
if not match:
    print("illegal s3 path", file = sys.stderr)
    sys.exit(1)
dst_bucket = match.group(1)
dst_path = ''
if match.group(2):
    dst_path = match.group(2)[1:]
else:
    dst_path = ""
if len(dst_path) > 0 and dst_path[-1:] != "/":
    dst_path = dst_path + "/"

session = boto3.session.Session(profile_name = src_profile)
client = session.client("s3")
resource = session.resource("s3")

class PushBackIterator:
    def __init__(self, src):
        self._src = src
        self._buf = []
    def __iter__(self):
        return self
    def __next__(self):
        if len(self._buf) > 0:
            elem = self._buf[-1]
            self._buf = self._buf[:-1]
            return elem
        return self._src.__next__()
    def push_back(self, elem):
        self._buf.append(elem)

def s3_list_objects(bucket, prefix):
    objects = resource.Bucket(bucket).objects.filter(Prefix = prefix)
    for obj in objects:
        key = obj.key
        size = obj.size
        yield (key, size)

def parseParent(key):
    p = key.rfind("/")
    if p >= 0:
        return key[0:p]
    else:
        return False

def parseName(key):
    p = key.rfind("/")
    if p >= 0:
        return key[p+1:]
    else:
        return key

def parseTopName(key):
    p = key.find("/")
    if p >= 0:
        return key[:p]
    else:
        return key

def lengthParent(parent):
    if parent == False:
        return -1
    else:
        return len(parent)

def diff_parent_tree_list(parent1, parent2):
    list1 = []
    list2 = []
    while True:
        if parent1 == parent2:
            break
        elif lengthParent(parent1) < lengthParent(parent2):
            list2.append(parent2)
            parent2 = parseParent(parent2)
        else:
            list1.append(parent1)
            parent1 = parseParent(parent1)
    return (list1, list2)

def s3_list_objects_wrapping_1(it, parent):
    prev_parent = parent
    for (key, size) in it:
        parent = parseParent(key)
        if parent != prev_parent:
            (diff1, diff2) = diff_parent_tree_list(prev_parent, parent)
            for d in diff1:
                yield (d, -6)
            for d in reversed(diff2):
                yield (d, -4)
            prev_parent = parent
        yield (key, size)

def s3_list_objects_wrapping_2(it, parent, maxSize, maxCount):
    totalSize = 0
    totalCount = 0
    items = []
    while True:
        try:
            count = 1
            fileFlag = True
            (key, size) = next(it)
        except StopIteration:
            key = parent
            size = -6
        if size == -6:
            if totalSize >= 0:
                yield (key, totalSize, totalCount, False)
            break
        it2 = False
        if size == -4:
            it2 = PushBackIterator(s3_list_objects_wrapping_2(it, key, maxSize, maxCount))
            (key2, size2, count2, fileFlag2) = next(it2)
            if key2 == key:
                size = size2
                count = count2
                fileFlag = fileFlag2
                it2 = False
            else:
                it2.push_back((key2, size2, count2, fileFlag2))
                size = maxSize + 1
        if it2 == False and totalSize < 0:
            yield (key, size, count, fileFlag)
        elif totalSize >= 0:
            if it2 == False:
                items.append((key, size, count, fileFlag))
                totalSize += size
                totalCount += count
                if totalSize > maxSize or totalCount > maxCount:
                    totalSize = -1
            else:
                totalSize = -1
            if totalSize < 0:
                for (key2, size2, count2, fileFlag2) in items:
                    yield (key2, size2, count2, fileFlag2)
                items = []
        if it2 != False:
            for (key2, size2, count2, fileFlag2) in it2:
                yield (key2, size2, count2, fileFlag2)


src_parent = parseParent(src_path)
it0 = s3_list_objects(src_bucket, src_path)
it1 = s3_list_objects_wrapping_1(it0, src_parent)
it2 = s3_list_objects_wrapping_2(it1, src_parent, maxSize, maxCount)
len_src_path = len(src_path)
for (key, size, count, fileFlag) in it2:
    if key == False:
        key2 = ""
    elif (key + "/") == src_path:
        key2 = ""
    else:
        key2 = key[len_src_path:] + "/"
    print("# %12d %6d %s" % (size, count, key2))
    if fileFlag:
        if key == False:
            raise Exception
        elif (key + "/") == src_path:
            raise Exception
        else:
            key2 = key[len_src_path:]
        src_uri = "s3://" + src_bucket + "/" + src_path + key2
        dst_uri = "s3://" + dst_bucket + "/" + dst_path + key2
        cmd1 = "aws --profile %s s3 cp '%s' '%s'" % (src_profile, src_uri, buf_dir)
        cmd2 = "aws --profile %s s3 cp '%s' '%s'" % (dst_profile, buf_dir, dst_uri)
    else:
        if key == False:
            key2 = ""
        elif (key + "/") == src_path:
            key2 = ""
        else:
            key2 = key[len_src_path:] + "/"
        src_uri = "s3://" + src_bucket + "/" + src_path + key2
        dst_uri = "s3://" + dst_bucket + "/" + dst_path + key2
        cmd1 = "aws --profile %s s3 cp --recursive '%s' '%s'" % (src_profile, src_uri, buf_dir)
        cmd2 = "aws --profile %s s3 cp --recursive '%s' '%s'" % (dst_profile, buf_dir, dst_uri)
    print("rm -rf '%s'" % buf_dir)
    print("echo " + cmd1)
    print("     " + cmd1)
    print("echo " + cmd2)
    print("     " + cmd2)
    print("")

