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

    qadapter_1 = CommonAdapter(
        q_type = "SLURM",
        rocket_launch="rlaunch -l my_launchpad.yaml -w my_fworker_1.yaml singleshot",
        constraint="gpu",
        account="nstaff",
        walltime="'00:02:00'",
        qos="regular",
        nodes="2"
    )

    qadapter_2 = CommonAdapter(
        q_type = "SLURM",
        rocket_launch="rlaunch -l my_launchpad.yaml -w my_fworker_2.yaml singleshot",
        constraint="gpu",
        account="nstaff",
        walltime="'00:02:00'",
        qos="regular",
        nodes="4"
    )

    fw_1 = Firework(ScriptTask.from_str(
        "srun -n 2 cctbx.python -m mpi4py.bench helloworld"
    ), spec={"_category": "n2", "_fworker": "mpi_2_fworker"}, name="mpi_2")


    fw_2 = Firework(ScriptTask.from_str(
        "srun -n 4 cctbx.python -m mpi4py.bench helloworld"
    ), spec={"_category": "n4", "_fworker": "mpi_4_fworker"}, name="mpi_4")

    workflow = Workflow(
        [fw_1, fw_2],
        {fw_1: fw_2},
        name="multi_queue"
    )

    launchpad.add_wf(workflow)
    launch_rocket_to_queue(launchpad, FWorker(name="mpi_2_fworker", category="n2"), qadapter_1)
    launch_rocket_to_queue(launchpad, FWorker(name="mpi_4_fworker", category="n4"), qadapter_2)



if __name__ == "__main__":
    mpi_wf()
