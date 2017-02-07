#!/usr/bin/env python
# -*- coding: utf-8 -*-

from setuptools import setup
import os

# Allow setup.py to be run from any path
os.chdir(os.path.normpath(os.path.join(os.path.abspath(__file__), os.pardir)))

setup(
    name='JSON.sh',
    scripts=[
        'JSON.sh',
    ],
    version='0.3.2',
    description="JSON parser written in shell",
    long_description="",
    author='Dominic Tarr (http://bit.ly/dominictarr)',
    author_email='dominic.tarr@gmail.com',
    url='https://github.com/dominictarr/JSON.sh',
    classifiers=[
        "Programming Language :: Unix Shell",
        "License :: OSI Approved :: MIT License",
        "License :: OSI Approved :: Apache Software License",
        "Intended Audience :: System Administrators",
        "Intended Audience :: Developers",
        "Operating System :: POSIX :: Linux",
        "Topic :: Utilities",
        "Topic :: Software Development :: Libraries",
    ],
)
