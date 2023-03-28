#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging

from os           import pardir
from sys          import argv
from os.path      import join, abspath, realpath, dirname
import conda_devenv.devenv


logger = logging.getLogger(__name__)
FORMAT = "[%(levelname)8s | %(filename)s:%(lineno)s - %(module)s.%(funcName)s() ] %(message)s"
logging.basicConfig(format=FORMAT)
logger.setLevel(10)


CONDA_PKG_ROOT = abspath(join(dirname(realpath(__file__)), pardir, pardir))
CHANNEL_FOLDER = join(CONDA_PKG_ROOT, "opt", "conda", "local-channel")


if __name__ == "__main__":
    conda_devenv.devenv.main([
        f"--env-var=SITE_CHANNEL={CHANNEL_FOLDER}",
        f"--file={argv[1]}",
        f"--print-full"
    ])
