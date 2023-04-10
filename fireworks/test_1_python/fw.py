#!/usr/bin/env python
# -*- coding: utf-8 -*-

from fireworks import Firework, Workflow, FWorker, LaunchPad, ScriptTask
from fireworks.core.rocket_launcher import rapidfire


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
    return ";".join(
        [f"{k}={var_dict[k]}" for k in var_dict]
    )


def basic_wf():
    launchpad = setup()

    env = {
        "Ingrid": "CEO",
        "Jill": "Manager",
        "Jack": "Manager",
        "Kip": "Intern"
    }

    fw_1 = Firework(ScriptTask.from_str(
        dict_as_vars(env)+ ";" + "echo Ingrid is $Ingrid"
    ), name="fw_1")
    fw_2 = Firework(ScriptTask.from_str(
        dict_as_vars(env)+ ";" + "echo Jill is $Jill"
    ), name="fw_2")
    fw_3 = Firework(ScriptTask.from_str(
        dict_as_vars(env)+ ";" + "echo Jack is $Jack"
    ), name="fw_3")
    fw_4 = Firework(ScriptTask.from_str(
        dict_as_vars(env)+ ";" + "echo Kip is $Kip"
    ), name="fw_4")

    workflow = Workflow(
        [fw_1, fw_2, fw_3, fw_4],
        {
            fw_1: [fw_2, fw_3],
            fw_2: fw_4,
            fw_3: fw_4
        }
    )

    launchpad.add_wf(workflow)
    rapidfire(launchpad, FWorker())


if __name__ == "__main__":
    basic_wf()
