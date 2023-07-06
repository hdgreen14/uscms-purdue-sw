#!/bin/bash

config="~/sonic/CMSSW_12_5_0_pre4/src/HeterogeneousCore/SonicTriton/data/models/particlenet_AK4_PT/config.pbtxt"  # Replace with your file name

batchsize=("10" "25" "50" "75")  # Replace with your desired numbers

cd  ~/sonic/CMSSW_12_5_0_pre4/src/sonic-workflows
for number in "${batchsize[@]}"; do
    sed -i "6 s/\[ [0-9]* \]/[ $number ]/g" "$config" 
    echo -e 'Preferred Batch size: ${batchsize[@]} \n' >> output.txt
    cmsRun run.py maxEvents=1000 threads=4 device=gpu tmi=True | tail -n 34 | head -n 25 >> output.txt
    echo -e ' \n\n\n' >> output.txt
done
