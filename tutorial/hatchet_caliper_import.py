import hatchet

gf = hatchet.GraphFrame.from_caliper("data/lulesh_mpi_x8.json")

# A Hatchet graph frame includes a call graph and a Pandas dataframe
print("The dataframe:")
print(gf.dataframe)

# Pretty-print the time metric on the call tree
print("Metric tree:")
print(gf.tree())

# All collected Adiak program metadata values are in the gf.metadata dict
print("Run metadata")
for k, v in gf.metadata.items():
    print("{:20} : {:.58}".format(k, v))
