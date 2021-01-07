import re
from setuptools import setup, find_packages

with open('requirements.txt') as requirements_file:
    install_requirements = requirements_file.read().splitlines()

def find_version():
    f = open("aws_ls_s3/version.py", "r")
    text = f.read()
    f.close()
    version_match = re.search(r"^VERSION\s*=\s*['\"]([^'\"]*)['\"]", text, re.M)
    if version_match:
        return version_match.group(1)
    raise RuntimeError("Unable to find version string.")

setup(
    name        = "aws-ls-s3",
    version     = find_version(),
    description = "ls command for aws s3",
    author      = "suzuki-navi",
    packages    = find_packages(),
    install_requires = install_requirements,
    entry_points = {
        "console_scripts": [
            "aws-ls-s3 = aws_ls_s3.main:main",
        ]
    },
)
