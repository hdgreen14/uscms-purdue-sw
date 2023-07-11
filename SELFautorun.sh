#!/bin/bash


#defaults
batchloop=1
batchsize=(10)
events=1000
config="/home/green642/sonic/CMSSW_12_5_0_pre4/src/HeterogeneousCore/SonicTriton/data/models/particlenet_AK4_PT/config.pbtxt"  # Replace with your file name
cpu=0

#$startdir=$PWD
startname="output.txt" 

help(){
    echo "autoRun [options]"
	echo 
	echo "Options:"
	echo "-b          Choose preferred batch size (Default: 10)"
    echo "-c          Run with CPU (default: GPU)"
    echo "-e          Choose how many events per inference (Default: 1000)" #when implimenting, add something to check config's max batch size
    #and then probably output, like, WARNING: max events is less than desired events 
    echo "-h          Print this message and exit"
	#echo "-d [dir]    Directory containing run.py"
	echo "-r          Number of runs per batch size"
    echo "-o [name]   Choose output file for time report data (default: PWD/output.txt)"
   # echo "-s"         Show output
	exit $1
}
while getopts "b:cd:e:hr:o:s" opt; do
case "$opt" in
b)
batchsize="$OPTARG"
;;
c)
cpu=1
;;
e)
events="$OPTARG"
;;
h)
help 0
;;
r)
batchloop="$OPTARG"
;;
o)
startname="$OPTARG"
;;
esac
done

if [ -f "$startname" ]; then
   # echo "WARNING: A file will be overwritten."
#    read -p "Are you sure? " -n 1 -r
#    echo    # (optional) move to a new line
 #   if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$startname"
 #   fi
else
    touch "$startname"
fi 

if [ -f "$startname" ]; then
rm tempoutput.txt
else   
    touch tempoutput.txt
fi

cd  /home/green642/sonic/CMSSW_12_5_0_pre4/src/sonic-workflows
source /cvmfs/cms.cern.ch/cmsset_default.sh
cmsenv

for number in ${batchsize[@]}; do
    sed -i "6 s/\[ [0-9]* \]/[ $number ]/g" "$config" #changes the config line from [x] to [batchsize]
   #sed -i (edit the current config file instead of making a copy)
   #"line 6,  substitute/ [ 1 or more 0-9 digits ]/number/global"
   #global as in, do it for everything on the line. might not need this.
    for ((i = 1; i <= $batchloop; i++)); do
        echo 'Starting with '${number}', run '$i'/'$batchloop''
        echo -e 'Preferred Batch size: '${number}' || Run '$i' of '$batchloop' \n' >> $startname

        if [[ $cpu == 1 ]]; then
                cmsRun run.py maxEvents=${events} threads=4 device=cpu tmi=True 2>&1 | tee tempoutput.txt #
        else
        cmsRun run.py maxEvents=${events} threads=4 device=gpu tmi=True 2>&1 | tee tempoutput.txt #the 2>&1 redirects stderr (which has TimeReport) to stdout
        fi
        
        sed -n '/TimeReport>/,/^Mem/ { /^Key/ d; p; }' tempoutput.txt >> $startname
        echo "loop '$i' of '$batchloop'"
    done
    echo -e ' \n\n\n' >> $startname
    echo 'Done with '${number}''

    rm tempoutput.txt

done