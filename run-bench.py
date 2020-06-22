#!/usr/bin/env python3
import datetime
import os
import subprocess

overall = False
if not os.path.exists("results"):
	os.mkdir("results")

if not os.path.exists("results/archived"):
	os.mkdir("results/archived")

if not os.path.exists("logs/"):
	os.mkdir("logs/")

if not os.path.exists("logs/archived"):
	os.mkdir("logs/archived")

if not os.path.exists("logs/overall"):
	os.mkdir("logs/overall")

if not os.path.exists("logs/metrics"):
	os.mkdir("logs/metrics")

programs = [
    'matrixAdd_org',
    'matrixAdd_smc',
    'matrixMul_org',
    'matrixMul_smc'
]

x = datetime.datetime.now()
day_time = "{}_{}_{}-{}-{}".format(x.month, x.day, x.hour, x.minute, x.second)

if overall:
    if not os.path.exists("logs/overall/{}".format(day_time)):
        os.mkdir("logs/overall/{}".format(day_time))
else:
    if not os.path.exists("logs/metrics/{}".format(day_time)):
        os.mkdir("logs/metrics/{}".format(day_time))

print("=========================")
if overall:
    print("Begin [OVERALL] profiling")
else:
    print("Begin [METRICS] profiling")
print("=========================")
print()

for app in programs:

    if overall:
        common = [
                'nvprof', 
                '--log-file', 
                'logs/overall/{}/overall_{}.csv'.format(day_time, app), 
                '--csv', '--print-gpu-trace'
                ]
    else:
        common = [  'sudo'  ,
                    'nvprof', '--metrics', 
                    'all', '--log-file', 'logs/metrics/{}/metric_{}.csv'.format(day_time, app), 
                    '--csv', '--print-gpu-trace'
                    ]
    
    instance = [ "./" + app]
    subprocess.run(common + instance)
    
if overall:
    os.system('./1_latency.py logs/overall/{} > results/overall_{}'\
            .format(day_time, day_time))
else:
    os.system('./2_metrics.py logs/metrics/{} {} > results/met_{}.csv'\
            .format(day_time, 1, day_time))