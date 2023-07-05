
#!/bin/bash

filename="~/sonic/CMSSW_12_5_0_pre4/src/HeterogeneousCore/SonicTriton/data/models/particlenet_AK4_PT/config.pbtxt"  # Replace with your file name

numbers=("10" "25" "50" "75" "100" "125" "150")  # Replace with your desired numbers

cd  ~/sonic/CMSSW_12_5_0_pre4/src/sonic-workflows
for number in "${numbers[@]}"; do
    sed -i "5 s/[*]/[ $number ]/g" "$filename"
    cmsRun run.py maxEvents=1000 threads=4 device=gpu tmi=True | tail 33 from bottom
done

