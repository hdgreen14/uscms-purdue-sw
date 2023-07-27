#!/bin/bash


#defaults
batchloop=1
batchsize=()
events=1000
config="/depot/cms/purdue-af/triton/models-hannah/deepmet/config.pbtxt"
#"/home/green642/temp/deepmet/config.pbtxt
#"/home/green642/sonic/CMSSW_12_5_0_pre4/src/HeterogeneousCore/SonicTriton/data/models/particlenet_AK4_PT/config.pbtxt"  # Replace with your file name
cpu=0
startname="output.txt" 
deepmet=1
ip=""

help(){
    echo "autoRun [options]"
	echo "Options:"
	echo "-b          Choose preferred batch size (Default: 10)"
    echo "-c          Run with CPU (default: GPU)"
    echo "-e          Choose how many events per inference (Default: 1000)" #when implementing, add something to check config's max batch size
    echo "-f          Choose config file to write batchsize into (not implemented yet)"
    #and then probably output, like, WARNING: max events is less than desired events 
    echo "-h          Print this message and exit"
    echo "-i          Change ip connection in run.py file"
    echo "-p          Using a PN Model (default: Deepmet)"
	#echo "-d [dir]    Directory containing run.py"
	echo "-r          Number of runs per batch size"
    echo "-o [name]   Choose output file for time report data (default: PWD/output.txt)"
   # echo "-s"         Show output
	exit $1
}
while getopts "b:cd:e:f:hi:pr:o:s" opt; do
case "$opt" in
b)
batchsize+="$OPTARG"
;;
c)
cpu=1
;;
e)
events="$OPTARG"
;;
f)
config="$OPTARG"
;;
h)
help 0
;;
i)
ip="$OPTARG"
;;
r)
batchloop="$OPTARG"
;;
p)
deepmet=0
;;
o)
startname="$OPTARG"
;;
esac
done

    if [ ! -f "$startname" ]; then
    touch $startname
    fi

if [[ -f "tempoutput.txt" ]]; then
rm tempoutput.txt
else   
    touch tempoutput.txt
fi

#sets batchsize default if needed
if [[  ${#batchsize[@]} -eq 0  ]]; then
    batchsize+=10
fi

#set ip address
    if [[ ! -z $ip ]]; then
        sed -i 's/\(options.register("address", "\)[^"]*/\1'$ip'/' run.py
    fi

#change config if needed
if [[ $deepmet -eq 0 ]]
    config="/home/green642/sonic/CMSSW_12_5_0_pre4/src/HeterogeneousCore/SonicTriton/data/models/particlenet_AK4_PT/config.pbtxt"
fi



source /cvmfs/cms.cern.ch/cmsset_default.sh
cmsenv
echo -e 'Config: \n Cpu: '$cpu' \n '

#for b in ${batchsize[@]}; do
    if [[ $deepmet == 0 ]]; then
    sed -i "5 s/\[ [0-9]* \]/[ "$batchsize" ]/g" "$config" #changes the config line from [x] to [batchsize]
    else
    sed -i 's/\(batch_size:\s*\)[0-9]*/\1'$batchsize'/' "$config" #ty chatgpt
    #basically this says, capture 'batch_size: [any characters until the digits] in a group, which we can access later using \1.'
    #then, sub it with that group and the batchsize. and as per usual, edit it with config
    fi
   #"line 6,  substitute/ [ 1 or more 0-9 digits ]/number/global"
   #global as in, do it for everything on the line. might not need this.
    for ((i = 1; i <= $batchloop; i++)); do
    
        dat=$(date -I)
        tim=$(date +"%T") 
        echo 'Starting with '$batchsize', run '$i'/'$batchloop' on '$dat' at start time: '$tim'' | tee -a $startname; #print time, date to file
        echo -e 'Preferred Batch size: '$b' || Run '$i' of '$batchloop' \n' >> $startname
        if [[ $cpu == 1 ]]; then

            echo "----- Running with CPU ----- " 
            cmsRun run.py maxEvents=${events} threads=4 device=cpu tmi=True 2>&1 | tee tempoutput.txt 


        else
        cmsRun run.py maxEvents=${events} threads=4 device=gpu tmi=True 2>&1 | tee tempoutput.txt #the 2>&1 redirects stderr (which has TimeReport) to stdout
        fi
        
        sed -n '/TimeReport>/,/^Mem/ { /^Key/ d; p; }' tempoutput.txt >> $startname
        echo "loop '$i' of '$batchloop'"
    
    echo -e ' \n\n\n' >> $startname
    echo 'Done with '$b', run end at '; date +"%T"

    rm tempoutput.txt

done
#done