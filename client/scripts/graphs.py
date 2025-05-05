import pygal
import subprocess
import json
import os

#compte le nombre de log pour définir le ratio de nettoyage de cleanXlabels
dossier = "/var/log/sys_info"
with os.scandir(dossier) as entries:
    nb_fichiers = sum(1 for entry in entries if entry.is_file())
ratio = nb_fichiers//5
if ratio == 0: ratio = 1

svg_path = "/var/log/sys_info/svg/"

def cleanXLabels(labels):
    labels = list(labels)
    for i in range(len(labels)):
        if i % ratio != 0:
            labels[i] = "" #décharge les labels x par rapport au ratio
        else:
            labels[i] = labels[i][11:] #enlève le jour
    return labels

def renderGraph(graph, data, name):
    graph.x_labels = list(cleanXLabels(data.keys()))
    graph.height = 720
    graph.width = 900
    graph.render_to_file(svg_path+name+'.svg')

def getSondeData(sonde):
    # recup de la dernière log avec la même commande que dans detection.sh
    logs = subprocess.run("find /var/log/sys_info -maxdepth 1 -type f -printf '%T@ %Tc %p\n' | sort -n | cut -d ' ' -f7", shell=True, capture_output=True, text=True)
    
    result = dict()

    for log in logs.stdout.splitlines():
        # recup de la date
        timestamp = log.removeprefix("/var/log/sys_info/log_").removesuffix(".json")

        # Ouvrir et lire la dernière log
        with open(log, "r", encoding="utf-8") as fichier:
            result[timestamp] = json.load(fichier)[sonde]

    return result

#graph de la consomation générale de ressource hardware
def buildSvgChartSys(data):
    line_chart = pygal.StackedLine(fill=True)
    line_chart.title = 'Hardware usage'

    cpu=[]
    ram=[]
    disk=[]

    #parcours des logs pour former le graph
    for timestamp, infos in data.items():
        cpu.append(infos['cpu']['usage_percent'])
        ram.append(infos['memory']['percent'])
        disk.append(infos['disk']['percent'])

    line_chart.add("CPU",  cpu)
    line_chart.add("disk",  disk)
    line_chart.add("memory",  ram)
    renderGraph(line_chart, data, "hardware_usage")

#graph de la consomation cpu de chaque procs
def buildSvgChartProc(data):
    line_chart = pygal.Line()
    line_chart.title = 'Proc cpu usage'

    procs=dict()
    procs_to_show=[]

    #parcours des logs pour former le dictionnaire pid->percent
    for timestamp, infos in data.items():
        for proc in infos:
            if proc['status'] == 'running':
                procs_to_show.append(proc['pid']) 
            if proc['pid'] in procs.keys():
                procs[proc['pid']].append(proc['cpu_percent'])
            else:
                procs[proc['pid']] = [proc['cpu_percent']]

    #parcours du dictionnaire pour former le graph
    for pid, percent in procs.items():
        if pid in procs_to_show:
            line_chart.add(str(pid), percent)

    renderGraph(line_chart, data, "proc_cpu_usage")

#graph sur le total pour la liste d'une sonde
def buildSvgTotal(data,name,filename):
    line_chart = pygal.StackedLine(fill=True)
    line_chart.title = name

    x=[]

    #parcours des logs pour former le graph
    for timestamp, infos in data.items():
        x.append(len(infos))

    line_chart.add(name, x)
    renderGraph(line_chart, data, filename)

def main():

    #graph utilisation hardware
    data_sys = getSondeData("sonde_sys")
    buildSvgChartSys(data_sys)

    #graph utilisation cpu des procs
    data_proc = getSondeData("sonde_proc")
    buildSvgChartProc(data_proc)

    #graphs total port used
    data_port = getSondeData("sonde_port")
    buildSvgTotal(data_port,"Total port used","total_ports_used")

    #graphs total user connected
    data_user = getSondeData("sonde_user")
    buildSvgTotal(data_user,"Total user(s) connected","total_users_connected")

    #graphs total procs
    buildSvgTotal(data_proc,"Total processus","total_procs")

if __name__ == '__main__':
    main()
