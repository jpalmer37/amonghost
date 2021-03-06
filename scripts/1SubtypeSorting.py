from seqUtils import *

fasta_file = open("/home/jpalmer/PycharmProjects/hiv-evolution-master/hiv-db.fasta", 'r')


data = parse_fasta(fasta_file)  #Returns headers and sequences as key/value pairs

predict = {}
filtered = {}

count = 0
seqcount = 0
#Sort by subtype
for i in data:
    info = i.split(".")
    seqcount += 1
    if info[0] not in predict.keys():
        predict[info[0]] = {}
        predict[info[0]][i] = data[i]
    else:
        predict[info[0]][i] = data[i]

print(seqcount)

subcount = 0
for i in predict.keys():
    subcount += 1
    for x in predict[i].keys():
        header = x.split(".")

        if header[0] != "-" and header[2] != "-" and len(predict[i][x]) > 1400:   #Removing sequences without a date sequences & less than 1400 nt
            if i not in filtered.keys():
                filtered[i] = {x:predict[i][x]}
            else:
                filtered[i][x] = predict[i][x]

#Delete the subtype if there is no data remaining
print(subcount)

'''
#Testing for sequence lengths
for i in subtypes:
    for x in subtypes[i].keys():
        print(len(subtypes[i][x]))
'''
#filtered = 0

#For output
for i in filtered:

    output_file = open("/home/jpalmer/PycharmProjects/hiv-evolution-master/1_SubtypeSequences/" + i + "++.fasta", 'w')
    for x in filtered[i]:
        count += 1

        output_file.write(">"+ x)
        output_file.write("\n")
        output_file.write(filtered[i][x])
        output_file.write("\n")
        
    output_file.close()

print(filtered)
print(count)



