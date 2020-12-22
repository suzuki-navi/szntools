import sys
import boto3

profile = "default"
if len(sys.argv) > 1:
    profile = sys.argv[1]

session = boto3.session.Session(profile_name = profile)

client = session.client("glue")

jobs = client.get_jobs()


header = [
    "started",
    "completed",
    "executionTime",
    "status",
    "name",
    "allocatedCapacity",
    "maxCapacity",
    "glueVersion",
    "errorMessage",
]

result = []

for job in jobs["Jobs"]:
    name = job["Name"]
    history = client.get_job_runs(JobName = name)
    for run in history["JobRuns"]:
        started = run["StartedOn"].strftime("%Y-%m-%d %H:%M:%S")
        if "CompletedOn" in run:
            completed = run["CompletedOn"].strftime("%Y-%m-%d %H:%M:%S")
        else:
            completed = ""
        executionTime = str(run["ExecutionTime"])
        if executionTime == "0":
            executionTime = ""
        status = run["JobRunState"]
        if "ErrorMessage" in run:
            errorMessage = run["ErrorMessage"]
        else:
            errorMessage = ""
        allocatedCapacity = str(run["AllocatedCapacity"])
        maxCapacity = str(run["MaxCapacity"])
        glueVersion = str(run["GlueVersion"])
        result.append([
            started,
            completed,
            executionTime,
            status,
            name,
            allocatedCapacity,
            maxCapacity,
            glueVersion,
            errorMessage,
        ])

result.sort(key = lambda r: r[0])

print("\t".join(header))
for r in result:
    print("\t".join(r))

