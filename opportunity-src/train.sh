#!/bin/bash

train_steps=3
num_subjects=3
activities=(101 102 104 105)
subject_prefix="S"

for s in $(seq 3 $num_subjects)
do
  # Train
  # Cleanup old hmms
  rm -rf ./model/hmm*
  for i in $(seq 0 $train_steps)
  do
    mkdir ./model/hmm$i
  done

  # Init and train hmms
  for i in ${activities[@]}
  do
    echo "Initialize HMM..."
    HInit -A -D -w 1.0 -T 1 -S $subject_prefix$s-data/trainlist_act_$i.txt -M model/hmm0 model/proto/Activity$i

    echo "Training HMMS..."
    for j in $(seq 1 $train_steps)
    do
      HRest -A -D -T 1 -S $subject_prefix$s-data/trainlist_act_$i.txt -M model/hmm$j -H model/hmm$((j-1))/Activity$i Activity$i
    done
  done

  # Concat hmms into one file
  echo 'Compiling hmms into one file..'
  hmm_file=./model/hmm$train_steps/all
  counter=0

  rm -f $hmm_file
  for filename in ./model/hmm$train_steps/*
  do
    if [ $filename != $hmm_file ] && [ $filename != "./model/hmm$train_steps/*" ]; then
      if [ $counter -eq 0 ]; then
        #touch $hmm_file
        cp $filename $hmm_file
      else
        awk '/Activity/,/ENDHMM/' $filename >> $hmm_file
      fi
      let counter+=1
    fi
  done

  # Classify
  HVite -A -D -T 1 -w net.slf -H model/hmm$((train_steps))/all -i reco.mlf -S $subject_prefix$s-data/classifylist.txt def/dict.txt hmmlist.txt
  awk 'NR%3==0' reco.mlf | awk '{print $3}' > results.txt
  sed -n 's/^.*_act_\([0-9]*\).*$/\1/p' $subject_prefix$s-data/testlist.txt | grep --color=never -o '[0-9]\+' | awk '{print "Activity"$0}' > original.txt
  echo $subject_prefix$s >> testing.txt
  python accuracy.py >> testing.txt
  echo >> testing.txt

  echo 'Independent model training complete!'

  cp hmmlist.txt ./model/hmm$train_steps/
  cp tmm.hed ./model/hmm$train_steps/

  mkdir ./model/hmm$((train_steps+1))

  cd ./model/hmm$train_steps/
  HHEd -M ../hmm$((train_steps+1)) -H Activity101 -H Activity102 -H Activity104 -H Activity105 tmm.hed hmmlist.txt

  cd ../../
  mkdir ./model/hmm$((train_steps+2))
  for i in ${activities[@]}
  do
    HRest -A -D -T 1 -S $subject_prefix$s-data/trainlist_act_$i.txt -M model/hmm$((train_steps+2)) -H model/hmm$((train_steps+1))/Activity101 -H model/hmm$((train_steps+1))/Activity$i Activity$i
    if [ $i = 101 ]; then
      cp model/hmm$((train_steps+2))/Activity$i model/hmm$((train_steps+2))/BackActivity$i
    fi
  done
  mv -f model/hmm$((train_steps+2))/BackActivity101 model/hmm$((train_steps+2))/Activity101

  echo 'Tied training complete!'

  # Concat hmms into one file
  echo 'Compiling hmms into one file..'
  hmm_file=./model/hmm$((train_steps+2))/all

  rm -f $hmm_file
  counter=0
  for filename in ./model/hmm$((train_steps+2))/*
  do
    if [ $filename != $hmm_file ] && [ $filename != "./model/hmm$((train_steps+2))/*" ]; then
      if [ $counter -eq 0 ]; then
        #touch $hmm_file
        cp $filename $hmm_file
      else
        awk '/Activity/,/ENDHMM/' $filename >> $hmm_file
      fi
      let counter+=1
    fi
  done

  # Classify
  HVite -A -D -T 1 -w net.slf -H model/hmm$((train_steps+2))/all -i reco.mlf -S $subject_prefix$s-data/classifylist.txt def/dict.txt hmmlist.txt
  awk 'NR%3==0' reco.mlf | awk '{print $3}' > results.txt
  sed -n 's/^.*_act_\([0-9]*\).*$/\1/p' $subject_prefix$s-data/testlist.txt | grep --color=never -o '[0-9]\+' | awk '{print "Activity"$0}' > original.txt
  echo $subject_prefix$s >> testing.txt
  python accuracy.py >> testing.txt
  echo >> testing.txt
done
