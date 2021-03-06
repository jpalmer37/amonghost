import os
from glob import glob
import re
import sys

def parse_fasta2(handle):
    # Modified parse fasta to return a dictionary of lists containing the reference [0] and the query [1]
    res = {}
    nt = ''
    h = ''
    for i in handle:
        if i[0] == '$': # skip h info
            continue
        elif i[0] == '>' or i[0] == '#':
            if ">ref" in i:
                continue
            elif ">query" in i:                    #Append the reference sequence
                res.update({h:[]})
                res[h].append(nt)
                nt = ''                             # reset containers
            elif len(nt) > 0 and ">query" not in i:             #Append the query sequence // Occurs when reaching the header of a new sequence
                res[h].append(nt)
                nt = ''
                #Parse the new header
                h = i.strip('\n')[1:]

            else:
                h = i.strip('\n')[1:]         #Occurs on the first header
        else:
            nt += i.strip('\n').upper()

    res[h].append(nt)
    return res

    

#GP120 Reference sequence file
ref_file = open("hxb2_gp120_sequence.txt", 'r')

gp120 = ''
for i in ref_file:
    gp120 += i.strip('\n').upper()

#Variable regions
v1 = gp120[390:468]
v2 = gp120[468:588]
v3 = gp120[885:993]
v4 = gp120[1152:1254]
v5 = gp120[1377:1410]
print(len(v1), len(v2), len(v3), len(v4), len(v5))


v_regions = [(390,468), (468,588), (885,993) , (1152,1254), (1377,1410)]
c_regions = [(0,390),  (588,885) , (993, 1152), (1254, 1377), (1410, 1532)]

'''
print(v1, len(v1))
print(v2, len(v2))
print(v3, len(v3))
print(v4, len(v4))
print(v5, len(v5))


#Single file testing
fasta_in = open("/home/jpalme56/PycharmProjects/hiv-evolution-master/2PairwiseAlignments/CD_pairwise.fasta", 'r')
data = parse_fasta(fasta_in)
output = open("/home/jpalme56/PycharmProjects/hiv-evolution-master/VRegions/V1-sequences.txt",'w')
'''


alignments = glob('/home/jpalme56/PycharmProjects/hiv-evolution-master/2PairwiseAlignments/*.fasta')


#headers = open("/home/jpalme56/PycharmProjects/hiv-evolution-master/Excel-Temp/headers.txt",'w')

gap_prefix = re.compile('^[-]+')
gap_suffix = re.compile('[-]+$')


def get_boundaries (str):
    # return a tuple giving indices of subsequence without gap prefix and suffix
    res = [0,len(str)]
    left = gap_prefix.findall(str)
    right = gap_suffix.findall(str)
    if left:
        res[0] = len(left[0])

    if right:
        res[1] = len(str) - len(right[0])

    return res

count = 0

test = "ATGAGAGTGAAGGAGAAATATCAGCACTTGTGGAGATGGGGGTGGAGATGGGGCACCATGCTCCTTGGGATGTTGATGAT\
CTGTAGTGCTACAGAAAAAGGGGGTTGTGGGTCACAGTCTATTATGGGGTACCTGTGTGGAAGGAAGCAACCACCACTCTATTTT\
GTGCATCAGATGCTAAAGCATATGATACAGAGGTACATAATGTTTGGGCCACACATGCCTGTGTACCCACAGACCCCAAC\
CCACAAGAAGTAGTATTGGTAAATGTGACAGAAAATTTTAACATGTGGAAAAATGACATGGTAGAACAGATGCATGAGGA\
TATAATCAGTTTATGGGATCAAAGCCTAAAGCCATGTGTAAAATTAACCCCACTCTGTGTTAGTTTAAAGTGCACTGATT\
TGAAGAATGATACTAATACCAATAGTAGTAGCGGGAGAATGATAATGGAGAAAGGAGAGATAAAAAACTGCTCTTTCAAT\
ATCAGCACAAGCATAAGAGGTAAGGTGCAGAAAGAATATGCATTTTTTTATAAACTTGATATAATACCAATAGATAATGA\
TACTACCAGCTATAAGTTGACAAGTTGTAACACCTCAGTCATTACACAGGCCTGTCCAAAGGTATCCTTTGAGCCAATTC\
CCATACATTATTGTGCCCCGGCTGGTTTTGCGATTCTAAAATGTAATAATAAGACGTTCAATGGAACAGGACCATGTACA\
AATGTCAGCACAGTACAATGTACACATGGAATTAGGCCAGTAGTATCAACTCAACTGCTGTTAAATGGCAGTCTAGCAGA\
AGAAGAGGTAGTAATTAGATCTGTCAATTTCACGGACAATGCTAAAACCATAATAGTACAGCTGAACACATCTGTAGAAA\
TTAATTGTACAAGACCCAACAACAATACAAGGAATCCGTATCCAGAGAGGACCAGGGAGAGCATTTGTTACAATA\
GGAAAAATAGGAAATATGAGACAAGCACATTGTAACATTAGTAGAGCAAAATGGAATAACACTTTAAAACAGATAGCTAG\
CAAATTAAGAGAACAATTTGGAAATAATAAAACAATAATCTTTAAGCAATCCTCAGGAGGGGACCCAGAAATTGTAACGC\
ACAGTTTTAATTGTGGAGGGGAATTTTTCTACTGTAATTCAACACAACTGTTTAATAGTACTTGGTTTAATAGTACTTGG\
AGTACTGAAGGGTCAAATAACACTGAAGGAAGTGACACAATCACCCTCCCATGCAGAATAAAACAAATTATAAACATGTG\
GCAGAAAGTAGGAAAAGCAATGTATGCCCCTCCCATCAGTGGACAAATTAGATGTTCATCAAATATTACAGGGCTGCTAT\
TAACAAGAGATGGTGGTAATAGCAACAATGAGTCCGAGATCTTCAGACCTGGAGGAGGAGATATGAGGGACAATTGGAGA\
AGTGAATTATATAAATATAAAGTAGTAAAAATTGAACCATTAGGAGTAGCACCCACCAAGGCAAAGAGAAGAGTGGTGCA\
GAGAGAAAAAAGA"




'''
#Read and parse all subtype alignments
for file in alignments:

    with open(file) as handle:
        data = parse_fasta2(handle)
    print(file)



    filename = file.split("/")[6]
    
    outputv = open("/home/jpalme56/PycharmProjects/hiv-evolution-master/3_RegionSequences/VRegions/"+ filename.split("pairwise")[0] + "2.csv", "w")
    outputc = open("/home/jpalme56/PycharmProjects/hiv-evolution-master/4_ConservedRegions/" + filename.split("pairwise")[0] + "CRegions2.fasta", "w")

    for header, seq in data.items():
        #Extract the reference and query sequences
        ref, query = seq

        accno = header[-8:]

        if "." in accno:
            accno = accno.split(".")[1]


        outputv.write(accno + ",")
        outputc.write(">" + header + "\n")

        #Determines the start and end positions of the reference sequence in the alignment
        left, right = get_boundaries(ref)

        #Work only with relevant sections
        r120 = ref[left:right]  # cut down to gp120
        q120 = query[left:right]


        # generate map from alignment to reference coordinates
        ri = 0  # reference index

        #{nucleotide #: actual position}
        index = {}

        #Scan the reference for the variable region location
        for ai, x in enumerate(r120):
            # ai = alignment index, literal position

            if x != '-':
                # otherwise alignment has a gap, do not increment reference index
                index.update({ri: ai})
                ri += 1

        
        #Output
        for n1, n2 in v_regions:

            if n1 != 1377:
                outputv.write(q120[index[n1]:index[n2]] + ",")
            else:
                outputv.write(q120[index[n1]:index[n2]] + "\n")

        for n1, n2 in c_regions:

            if n1 != 1410:
                outputc.write(q120[index[n1]:index[n2]])
            else:
                outputc.write(q120[index[n1]:index[n2]] + "\n")
'''

