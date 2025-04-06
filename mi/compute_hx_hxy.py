# SCRIPT TO COMPUTE ENTROPY HX & JOINT ENTROPY H_XY FOR MUTUAL INFO (MI = H_X + H_Y - HXY)

import numpy as np
import scipy.io
from shannon_helpers import *
from mpi4py import MPI
import time

# CHANGE THESE PARAMS ####
#------------------------# 
# Number of histogram bins used to approximate 
# the probability distribution of the flow variable
NUM_BINS = 30 

# Mat file in which the flow time series data is present 
#INPUT_FILE_NAME = "/work/home/username/case_directory/filename.mat" 
INPUT_FILE_NAME = "NR_u_data.mat"

# Specify the name of the variable corresponding to the 
# flow quantity's time series in the mat file here
#VARIABLE_TO_PROCESS = "u_fluct"
VARIABLE_TO_PROCESS = "u_CC_fluc_mat"


# Specify the prefix of the output filename 
OUTPUT_FILE_PREFIX = "mi_bins_" #
#------------------------#

## Function to calculate Mutual Information
def calc_mi(comm, infile_name, vel_comp, num_bins, out_prefix):
	start_time = time.time()

	upf=None
	num_samples = None
	num_features = None
	rank = comm.Get_rank()
	size = comm.Get_size()

	if rank == 0:
		a = scipy.io.loadmat(infile_name)
		mdata = a[vel_comp]
    (nx, nz, nt) = mdata.shape
		(num_samples, num_features) = (nt, nx*nz)
		upf_dataset = np.reshape(mdata, (num_features, num_samples))
    upf_dataset = upf_dataset.transpose()
		upf = np.block([upf_dataset])

	upf = comm.bcast(upf, root=0)
	num_samples = comm.bcast(num_samples, root=0)
	num_features = comm.bcast(num_features, root=0)

	if num_bins is None:
		num_bins = int(np.ceil(np.log2(num_samples)) + 1) # Sturge's rule
	
	print(f'Begin: Rank({rank})')
	chunk_size = int(num_features/size)
	beg_idx = rank * chunk_size
	end_idx = (rank+1) * chunk_size
	if rank == size-1:
	  end_idx = num_features
	
	hx = np.zeros(num_features)
	for i in range(beg_idx, end_idx):
		print(f'HX: i: {i+1}/{num_features}')
		hx[i] = entropy(np.expand_dims(upf[:,i], axis=1), bins=num_bins, method='bin')
	hx_csr = scipy.sparse.csr_matrix(hx)
	scipy.io.savemat(f'{out_prefix}{vel_comp}_{rank}_hx_new.mat', {'hx' : hx_csr})
	
	hxy = np.zeros([num_features, num_features])
	for i in range(beg_idx, end_idx):
		print(f'HXY: i: {i+1}/{num_features}')
		for j in range(i + 1, num_features):
			if i != j:
				x = np.expand_dims(upf[:,i], axis=1)
				y = np.expand_dims(upf[:,j], axis=1)
				hxy[i,j] = entropy(data=np.concatenate([x, y], axis=1), bins=num_bins, method='bin')
				hxy[j,i] = hxy[i,j]
	hxy_csr = scipy.sparse.csr_matrix(hxy)
	scipy.io.savemat(f'{out_prefix}{vel_comp}_{rank}_hxy_new.mat', {'hxy' : hxy_csr})

	print(f'Rank: {rank} :: Total Running time = {round(time.time() - start_time, 2)} seconds')
	
def main():
  comm = MPI.COMM_WORLD
	infile_name = INPUT_FILE_NAME
	vel_comp = VARIABLE_TO_PROCESS
	outfile_prefix = OUTPUT_FILE_PREFIX
	num_bins = NUM_BINS
	calc_mi(comm, infile_name, vel_comp, num_bins, outfile_prefix)

if __name__ == '__main__':
	main()
