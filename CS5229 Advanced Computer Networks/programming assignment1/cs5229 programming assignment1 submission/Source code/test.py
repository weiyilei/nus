import sys
import pandas as pd
import numpy as np
from count_min import CountMinSketch
from constants import *
from pympler.classtracker import ClassTracker
from pympler import asizeof
import time


def load_data(file_name):
    packet_trace = None
    try:
        packet_trace = pd.read_csv(file_name)
    except FileNotFoundError:
        print(f"File '{file_name}' not found.")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

    flow_grouped = packet_trace.groupby(
        ['Source_IP', 'Destination_IP', 'Source_Port', 'Destination_Port', 'Protocol']).sum()
    return packet_trace, flow_grouped


def get_rand_flow(flow_grouped):
    ind = np.random.randint(flow_grouped.shape[0])
    flow_X = flow_grouped.index[ind]
    gt_freq = flow_grouped.iloc[ind]['flow_freq']
    return flow_X, gt_freq


def wrap_test(func):
    def inner():
        func_name = func.__name__.replace('test_', '')
        try:
            func()
            print('{}: WITHIN SET LIMITS'.format(func_name))
        except Exception as e:
            print('{}: FAILED, reason: {} ***'.format(func_name, str(e)))

    return inner


@wrap_test
def test_estimate_frequency():
    gt, est = list(), list()
    # cnt = 0
    for i in range(10000):
        flow_X, gt_freq = get_rand_flow(flow_grouped)
        est_freq = sketch.estimate_frequency(flow_X)
        # print(gt_freq, est_freq)
        # if est_freq == 0:
        #     cnt += 1
        gt.append(gt_freq)
        est.append(est_freq)
    # print(cnt)
    gt = np.array(gt)
    est = np.array(est)
    err = np.abs(est - gt)
    print("Mean Error: ", err.mean())

    assert err.mean() < MEAN_ERROR_THRESHOLD, "Mean error beyond threshold"
    assert np.percentile(err, 95) < PERCENTILE_95_THRESHOLD, "Percentile 95 error beyond threshold"
    assert np.median(err) < MEDIAN_ERROR_THRESHOLD, "Median error beyond threshold"


@wrap_test
def test_count_unique_flows():
    cardinality = sketch.count_unique_flows()
    # print(cardinality)
    gt_cardinality = flow_grouped.shape[0]
    # print(gt_cardinality)
    error = np.abs(gt_cardinality - cardinality) * 100 / gt_cardinality
    print("Error in Cardinality: ", error)
    assert error < CARDINALITY_ERROR_THRESHOLD, "Cardinality error beyond threshold"


@wrap_test
def test_find_heavy_hitters():
    heavy_hitters, _ = sketch.find_heavy_hitters()
    top_100 = flow_grouped.sort_values(by='flow_freq', ascending=False).head(100)
    print("Number of Heavy Hitters: ", len(set(top_100.index) & set(heavy_hitters)))
    # print((set(top_100.index) & set(heavy_hitters)))

    assert len(set(top_100.index) & set(
        heavy_hitters)) > HEAVY_HITTERS_THRESHOLD, "Unable to detect heavy hitters above set threshold"


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python test.py <file_name>")
        print("Example: python test.py packet-trace.csv")
        sys.exit(1)

    file_name = 'Data/' + sys.argv[1]

    start_time = time.time()
    tracker = ClassTracker()
    tracker.track_class(CountMinSketch)

    print("Loading Data.....")
    packet_trace, flow_grouped = load_data(file_name)

    print("Initialising Sketch.....")
    """ YOUR CODE HERE
        TODO: Initialise the sketch with the required parameters
        Example:
            width = ...
            depth = ...
            data_type = ...
            sketch = CountMinSketch(width, depth, data_type)
    """
    sketch = CountMinSketch()
    ########################################

    tracker.create_snapshot("Sketch Initialised")

    # Updating sketch with all packets in trace
    print("Updating sketch with all packets in trace, this may take a while...")
    i = 0
    for row in packet_trace.itertuples(index=False):
        i += 1
        sketch.add_item(row[0:5], row[5])
        if i % 500000 == 0:
            print("Processed {:.2f}% of packets".format(i * 100 / packet_trace.shape[0]))
    assert (asizeof.asizeof(sketch.sketch) + asizeof.asizeof(sketch.auxiliary_storage)) / (
                1024 ** 2) < 1, "Sketch Size is not less than 1 Megabyte"
    tracker.create_snapshot("Sketch Updated with all packets")
    print("Sketch Updated with all packets")

    print("\n\n~~~~~~~Testing Functionalities~~~~~~~\n")
    test_estimate_frequency()
    tracker.create_snapshot("Query I")

    test_count_unique_flows()
    tracker.create_snapshot("Query II")

    test_find_heavy_hitters()
    tracker.create_snapshot("Query II")
    end_time = time.time()
    elapsed_time = end_time - start_time

    print("\n\n~~~~~~~ Sketch Memory Usage Report~~~~~~~")
    tracker.create_snapshot("End of Script")
    tracker.stats.print_summary()
    tracker.stats.dump_stats('Data/class_profile.dat')

    print(f"\n\nElapsed time: {elapsed_time} seconds")
