startTime=$(date +%s)
elapsedTime=0
count=0
total=0
while [ $elapsedTime -lt 5  ]
do
	fork=$(2>/dev/null ./forkbench 0 1024)
    total=$(echo "$total+$fork" | bc)
    currentTime=$(date +%s)
    elapsedTime=$(($currentTime-$startTime))
    count=$(($count+1))
done

fork=$(echo "scale=2;$total/$count" | bc)
echo $fork