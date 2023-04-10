#!/usr/bin/env python
# -*- coding: utf-8 -*-

from fireworks import Firework, Workflow, FWorker, LaunchPad, ScriptTask
from fireworks.user_objects.queue_adapters.common_adapter import CommonAdapter
from fireworks.queue.queue_launcher import rapidfire, launch_rocket_to_queue


def setup():
    return LaunchPad(
        host="mongodb-loadbalancer.cctbx.production.svc.spin.nersc.org",
        port=3306,
        name="jpb_fw",
        username="jpb",
        password="asdf",
        authsource="jpb_fw"
    )


def dict_as_vars(var_dict):
    return ";".join([f"{k}={var_dict[k]}" for k in var_dict]) + ";"


def mpi_wf():
    launchpad = setup()

    qadapter = CommonAdapter(
        q_type = "SLURM",
        rocket_launch="rlaunch -l my_launchpad.yaml rapidfire",
        constraint="gpu",
        account="nstaff",
        walltime="'00:02:00'",
        qos="regular",
        # queue="gpu_regular",
        nodes="2"
    )

    fw_1 = Firework(ScriptTask.from_str(
        "srun -n 2 cctbx.python -m mpi4py.bench helloworld"
    ), name="mpi")

    workflow = Workflow(
        [fw_1],
        {}
    )

    launchpad.add_wf(workflow)
    # rapidfire(launchpad, FWorker(), qadapter)
    launch_rocket_to_queue(launchpad, FWorker(), qadapter)


if __name__ == "__main__":
    mpi_wf()
