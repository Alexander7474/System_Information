import psutil
import json
import platform
import subprocess

def sonde_sys():
    system_info = {
        "cpu": {
            "arch": platform.machine(),
            "model": subprocess.check_output("sudo dmidecode -s processor-version", shell=True, text=True),
            "usage_percent": psutil.cpu_percent(interval=1),
            "num_cores": psutil.cpu_count(logical=True)
        },
        "memory": {
            "total": psutil.virtual_memory().total,
            "available": psutil.virtual_memory().available,
            "used": psutil.virtual_memory().used,
            "percent": psutil.virtual_memory().percent
        },
        "disk": {
            "total": psutil.disk_usage('/').total,
            "used": psutil.disk_usage('/').used,
            "free": psutil.disk_usage('/').free,
            "percent": psutil.disk_usage('/').percent
        },
        "network": {
            "bytes_sent": psutil.net_io_counters().bytes_sent,
            "bytes_recv": psutil.net_io_counters().bytes_recv,
            "packets_sent": psutil.net_io_counters().packets_sent,
            "packets_recv": psutil.net_io_counters().packets_recv
        }
    }
    return system_info

def sonde_proc():
    procs_info = []
    cpt_proc = 0
    for proc in psutil.process_iter():
        with proc.oneshot():
            proc_info = [{
                "name": proc.name(),  # execute internal routine once collecting multiple info
                "cpu_time": proc.cpu_times(),  # return cached value
                "cpu_percent": proc.cpu_percent(),  # return cached value
                "create_time": proc.create_time(),  # return cached value
                "pid": proc.pid,  # return cached value
                "status": proc.status()  # return cached value
            }]
        cpt_proc+=1
        procs_info.extend(proc_info)    

    #cpt_proc_json = [{
    #            "total_proc": cpt_proc
    #    }]

    #procs_info.extend(cpt_proc_json)

    return procs_info

if __name__ == "__main__":
    data = sonde_sys()

    print("\"sonde_proc\": ")
    print(json.dumps(sonde_proc(), indent=4)+",")

    print("\"sonde_sys\": ")
    print(json.dumps(data, indent=4))
