import numpy as np
import tensorflow as tf

np_data = np.arange(82).reshape([2,41])

a = np.tile(np_data[:,:41],2)

print a

b = tf.constant([-1,0,1,2,3])
b = tf.minimum(b, 2)

sess = tf.InteractiveSession()

print b.eval()