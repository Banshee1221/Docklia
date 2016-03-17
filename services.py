"""Docklia
Usage:
    docklia.py --zone <timezone> (--server|-s)
    docklia.py --zone <timezone> (--client|-c)
    docklia.py (-h|--help)
Options:
    -h --help   Show this screen.
    --timezone  Specify the timezone inside the container, e.g. --timezone Africa/Johannesburg
    --server    Initialize the container as a Ganglia server with gmetad and gmond.
    --client    Initialize the container as a Ganglia client and only start gmond.
"""

from docopt import docopt
import os, stat

arguments = ""
if __name__ == '__main__':
        arguments = docopt(__doc__, version='1')

WORKDIR = os.getcwd()
TIMEZONE = arguments["<timezone>"].strip()
BASH = ""

if arguments['--server'] or arguments['-s']:
    BASH = "#!/bin/bash\n" \
            "ln -sf /usr/share/zoneinfo/"+TIMEZONE+" /etc/localtime\n" \
            "touch /var/log/ganglia/gmetad.log; touch /var/log/ganglia/gmond.log\n" \
            "service httpd start\n" \
            "gmetad -d 10 >> /var/log/ganglia/gmetad.log 2>&1 &\n" \
            "gmond -d 10 >> /var/log/ganglia/gmond.log 2>&1 &\n" \
            "bash"

elif arguments['--client'] or arguments['-c']:
    BASH = "#!/bin/bash\n" \
            "touch /var/log/ganglia/gmond.log\n" \
            "gmond -d 10 >> /var/log/ganglia/gmond.log 2>&1 &\n" \
            "bash"

out = open('services.sh', 'w+')
out.write(BASH)
out.close()
st = os.stat(WORKDIR+"/services.sh")
os.chmod(WORKDIR+"/services.sh", st.st_mode | stat.S_IEXEC)
os.system(WORKDIR+"/services.sh")
