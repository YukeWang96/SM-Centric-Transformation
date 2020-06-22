#!/usr/bin/env python
import pandas as pd
import sys
import os


# extract the time information of the directory
def extrat_time(dir):
    files = sorted(os.listdir(dir))
    mem_times = []
    cpt_times = []
    f = []

    for fname in files:
        if not '.csv' in fname:
            continue

        # print(fname)
        f.append(fname)
        curr_csv = pd.read_csv(dir + "/" + fname, header=3)
        duration = curr_csv.Duration.tolist()
        cuda_type = curr_csv.Name.tolist()

        use_s = False
        use_us = False
        use_ms = False
        mem_time = 0
        cpt_time = 0

        for tpe, time in zip(cuda_type, duration):
            if "ms" in str(time):
                use_ms = True
                continue
            elif "us" in str(time):
                use_us = True
                continue
            elif "s" in str(time):
                use_s = True
                continue

            if "memcpy" in str(tpe) or  "memset" in str(tpe):
                mem_time += float(time)
            else:
                cpt_time += float(time)

        if use_us:
            mem_times.append(mem_time/1e3)
            cpt_times.append(cpt_time/1e3)
        elif use_ms:
            mem_times.append(mem_time)
            cpt_times.append(cpt_time)
        elif use_s:
            mem_times.append(mem_time * 1e3)
            cpt_times.append(cpt_time * 1e3)
        else:
            print("error")
    
    return f, mem_times, cpt_times


if __name__ == "__main__":
    files, mem_time, cpt_time = extrat_time(sys.argv[1])
    ans = []
    for f, m, c in zip(files, mem_time, cpt_time):
        ans.append((f, m, c))
    
    print("Filename, Mem(ms), Compute(ms)")
    for item in sorted(ans):
        print("{}, {:3f}, {:3f}".format(item[0], float(item[1]), float(item[2])))