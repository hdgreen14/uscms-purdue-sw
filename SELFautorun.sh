#!/bin/bash

config="/home/green642/sonic/CMSSW_12_5_0_pre4/src/HeterogeneousCore/SonicTriton/data/models/particlenet_AK4_PT/config.pbtxt"  # Replace with your file name

batchsize=("10" "25" "50")  # Replace with your desired numbers

cd  /home/green642/sonic/CMSSW_12_5_0_pre4/src/sonic-workflows
for number in ${batchsize[@]}; do
    echo 'Starting with '${number}''
    sed -i "6 s/\[ [0-9]* \]/[ $number ]/g" "$config" 
    echo -e 'Preferred Batch size: '${number}' \n' >> output.txt
    cmsRun run.py maxEvents=1000 threads=4 device=gpu tmi=True  &> tempoutput.txt | sed -n '/TimeReport>/,/^Mem/ { /^Key/ d; p; }' >> output.txt
   
    echo -e ' \n\n\n' >> output.txt
    echo 'Done with '${number}''
done