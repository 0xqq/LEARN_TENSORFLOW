import numpy as np
import pandas as pd
import time

#split the dataset into three part:
#training, validation, test
#ver 1.0
def split_dataset(dataset, test_dataset_size=None, radio=None):
    if radio != None:
        test_dataset_size = int(radio * len(dataset))

    train_set = dataset.values[0:-test_dataset_size * 2]
    validation_set = dataset.values[-test_dataset_size * 2:-test_dataset_size]
    test_set = dataset.values[-test_dataset_size:len(dataset)]

    return train_set, validation_set, test_set

#normalize the dataset, push data between -1 to 1
#ver 1.0
def normalize_dataset(dataset, min_values=None, max_values=None):
    norm_dataset = np.zeros((dataset.shape))
    norm_dataset[:, :] = dataset[:, :]

    if min_values == None:
        CMr_min = np.min(norm_dataset[:,0:3100])
        CMi_min = np.min(norm_dataset[:,3100:6200])
        CD_min = np.min(norm_dataset[:,6200:6201])
        length_min = np.min(norm_dataset[:,6201:6221])
        power_min = np.min(norm_dataset[:,6221:6241])
    else:
        CMr_min, CMi_min, CD_min, length_min, power_min = min_values


    if max_values == None:
        CMr_max = np.max(norm_dataset[:,0:3100])
        CMi_max = np.max(norm_dataset[:,3100:6200])
        CD_max = np.max(norm_dataset[:,6200:6201])
        length_max = np.max(norm_dataset[:,6201:6221])
        power_max = np.max(norm_dataset[:,6221:6241])
    else:
        CMr_max, CMi_max, CD_max, length_max, power_max = max_values

    def calcul_norm(dataset, min, max):
        return (2 * dataset - max - min) / (max - min)

    norm_dataset[:, 0:3100] = calcul_norm(norm_dataset[:, 0:3100], CMr_min, CMr_max)
    norm_dataset[:, 3100:6200] = calcul_norm(norm_dataset[:, 3100:6200], CMi_min, CMi_max)
    norm_dataset[:, 6200:6201] = calcul_norm(norm_dataset[:, 6200:6201], CD_min, CD_max)
    norm_dataset[:, 6201:6221] = calcul_norm(norm_dataset[:, 6201:6221], length_min, length_max)
    norm_dataset[:, 6221:6241] = calcul_norm(norm_dataset[:, 6221:6241], power_min, power_max)

    min_values = (CMr_min, CMi_min, CD_min, length_min, power_min)
    max_values = (CMr_max, CMi_max, CD_max, length_max, power_max)

    return norm_dataset, min_values, max_values

#get the values from array read from csv file
#ver 1.0
def get_values_from_array(array, num):
    CMr = array[num,0]
    CMi = array[num,1]
    CD = array[num,2]
    length = array[num,3]
    power = array[num,4]

    values = CMr, CMi, CD, length, power

    return values

#recut the normalize and split the dataset
#ver 1.0
def norm_recut_dataset(filename, savePath, minmax_name, dataSize, chunkSize):
    #filename = '/media/freshield/LINUX/Ciena/CIENA/raw/FiberID_Data_noPCA.csv'
    #chunkSize = 1000
    #savePath = '/media/freshield/LINUX/Ciena/CIENA/raw/norm/'
    #minmax_name = '/media/freshield/LINUX/Ciena/CIENA/raw/min_max.csv'

    reader = pd.read_csv(filename, header=None, iterator=True, dtype=np.float32)

    loop = True
    # to do
    # think about chunkSize 10000

    total_loop = dataSize // chunkSize

    i = 0
    count = 0

    minmax_array = pd.read_csv(minmax_name, header=None, dtype=np.float32).values

    # get min and max
    min_values = get_values_from_array(minmax_array, 0)
    max_values = get_values_from_array(minmax_array, 1)

    print 'begin to norm and recut the file'

    while loop:
        before_time = time.time()
        try:
            chunk = reader.get_chunk(chunkSize)

            train_set, validation_set, test_set = split_dataset(chunk, radio=0.1)

            # normalize dataset
            train_set, _, _ = normalize_dataset(train_set, min_values, max_values)
            validation_set, _, _ = normalize_dataset(validation_set, min_values, max_values)
            test_set, _, _ = normalize_dataset(test_set, min_values, max_values)

            np.savetxt(savePath + "train_set_%d.csv" % count, train_set, delimiter=",")
            np.savetxt(savePath + "validation_set_%d.csv" % count, validation_set,
                       delimiter=",")
            np.savetxt(savePath + "test_set_%d.csv" % count, test_set, delimiter=",")

            if count % 10 == 0:
                span_time = time.time() - before_time
                print "use %.2f second in 10 loop" % (span_time * 10)
                print "need %.2f minutes for all loop" % (((total_loop - count) * span_time) / 60)

            # i += chunk.shape[0]
            count += 1
            print count



        except StopIteration:
            print "stop"
            break

#norm_recut_dataset('/home/freshield/Ciena_data/dataset_10k/ciena10000.csv','/home/freshield/Ciena_data/dataset_10k/model/','/home/freshield/Ciena_data/dataset_10k/model/min_max.csv',10000,100)