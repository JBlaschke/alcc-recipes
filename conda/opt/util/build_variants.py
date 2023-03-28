#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging

from os                   import pardir
from sys                  import argv
from json                 import loads
from shutil               import copytree
from typing               import Optional
from os.path              import join, abspath, realpath, dirname
from dataclasses          import dataclass
from conda.cli.python_api import Commands, run_command
from conda_build.api      import build, update_index


logger = logging.getLogger(__name__)
FORMAT = "[%(levelname)8s | %(filename)s:%(lineno)s - %(module)s.%(funcName)s() ] %(message)s"
logging.basicConfig(format=FORMAT)
logger.setLevel(10)


@dataclass
class Package:
    build: str
    build_number: int
    channel: str
    constrains: list[str]
    depends: list[str]
    fn: str
    md5: str
    name: str
    platform: str
    sha256: str
    size: int
    subdir: str
    url: str
    version: str
    timestamp: Optional[int] = None
    license: Optional[str] = None
    license_family: Optional[str] = None
    arch: Optional[str] = None
    legacy_bz2_md5: Optional[str] = None
    legacy_bz2_size: Optional[int] = None
    track_features: Optional[str] = None


def find_packages(package_name: str, channel: str = "defaults"):
    stdout, _, retcode = run_command(
        Commands.SEARCH, "-c", channel, "--json", package_name
    )
    assert retcode == 0

    packages = dict()
    for name, descriptor in loads(stdout).items():
        if name not in packages:
            packages[name] = list()

        for p in loads(stdout)[package_name]:
            packages[name].append(Package(**p))

    return packages


def versions(name: str, packages: dict[str, list[Package]]):
    if name not in packages.keys():
        raise RuntimeError(f"{name} not included in {packages.keys()}")

    return set((p.version for p in packages[name]))


def generate_variants(versions: set[str]):
    variants_str = "versions:"
    for v in versions:
        variants_str = variants_str + f"\n - {v}"

    return variants_str


CONDA_PKG_ROOT = abspath(join(dirname(realpath(__file__)), pardir, pardir))
CHANNEL_FOLDER = join(CONDA_PKG_ROOT, "opt", "conda", "local-channel")

def build_variants(name:str, channel:str):
    logger.info(f"Collecting versions for {name} on channel {channel}")
    package_versions = versions(name, find_packages(name, channel=channel))
    logger.debug(f"{package_versions=}")

    logger.info(f"Generating build variants for {name}")
    build_variants = generate_variants(package_versions)
    logger.debug(f"{build_variants=}")

    conda_pkg_path = join(CONDA_PKG_ROOT, name) 

    logger.info(f"Writing variants file: {conda_pkg_path}")
    with open(join(conda_pkg_path, "conda_build_config.yaml"), "w") as f:
        f.write(build_variants)

    build_folder = join(CONDA_PKG_ROOT, "var", "conda-build", name)
    logger.info(f"Building {name=} in {build_folder=}")
    build(conda_pkg_path, output_folder = build_folder)

    CHANNEL_FOLDER = join(CONDA_PKG_ROOT, "opt", "conda", "local-channel")
    for arch in ["noarch", "linux-64"]:
        src = join(build_folder, arch)
        dst = join(CHANNEL_FOLDER, arch)
        logger.info(f"Copying generated package from: {src} to {dst}")
        copytree(src, dst, dirs_exist_ok=True)


if __name__ == "__main__":
    packages = [
        "_libgcc_mutex",
        "_openmp_mutex",
        "libgcc-ng",
        "libstdcxx-ng",
        "libgomp",
        "libssh2",
        "ncurses",
        "openssl"
    ]
    channel = "conda-forge"

    logger.info(" ".join([
        f"Building shims for: {packages}",
        f"with versions numbers taken from {channel=}"
    ]))
    for p in packages:
        build_variants(p, channel)

    logger.info(f"Updating index at: {CHANNEL_FOLDER}")
    update_index(CHANNEL_FOLDER)
