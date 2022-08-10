import hatchet

# Load runs with 1 and 8 MPI ranks, respectively
gf1 = hatchet.GraphFrame.from_caliper("data/lulesh_mpi_x1.json")
gf8 = hatchet.GraphFrame.from_caliper("data/lulesh_mpi_x8.json")

# Divide the graph frames to determine scaling performance
gfd = gf1 / gf8

# Print the tree and invert the color map
print(gfd.tree(invert_colormap=True))
