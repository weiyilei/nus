""" CS5229 Programming Assignment 1: 
    Sketch-based Network Monitoring

Name: WEI YILEI
Email: E1132304@u.nus.edu
Student ID: A0276571W
"""

import numpy as np
from pympler import asizeof


class CountMinSketch:
    def __init__(self):  # Allowed to add initialization parameters
        """Initialise the sketch. You may add additional variables to the function call.

            self.sketch: Variable to store the sketch
            self.auxiliary_storage: Additional auxiliary storage (optional)
        """

        self.sketch = []  # Variable to store sketch
        self.sketch2 = []
        self.auxiliary_storage = {}  # Variable to store heavy hitters (optional)

        """ YOUR CODE HERE
        TODO: Initialise the sketch with the required parameters
        """
        self.first_width = 450000
        self.sketch.append(np.zeros([1, self.first_width], dtype=np.uint8))
        self.sketch.append(np.zeros([1, self.first_width // 100], dtype=np.uint16))
        self.sketch.append(np.zeros([1, self.first_width // 10000], dtype=np.uint32))
        self.sketch2.append(np.zeros([1, self.first_width], dtype=np.uint8))
        self.sketch2.append(np.zeros([1, self.first_width // 100], dtype=np.uint16))
        self.sketch2.append(np.zeros([1, self.first_width // 10000], dtype=np.uint32))
        self.min_count = 0
        # print(self.sketch)
        # print(self.sketch[0][0])
        assert (asizeof.asizeof(self.sketch) + asizeof.asizeof(self.auxiliary_storage) + asizeof.asizeof(self.sketch2)
                + asizeof.asizeof(self.min_count) + asizeof.asizeof(self.first_width)) / (
                       1024 ** 2) < 1, "Sketch Size is not less than 1 Megabyte"

    def hash_func(self, packet_flow, i=None):
        """Function handles the hashing functionality for the sketch

        Args:
            packet_flow: Tuple of (Source_IP, Destination_IP, Source_Port, Destination_Port, Protocol)
            i (optional): Optional arguement to specify the hash function ID to be used. Defaults to None.

        Returns:
            Hashed value of the packet_flow
        """

        """ YOUR CODE HERE
        TODO: Implement the hash functions
        """

        s = packet_flow[0] + packet_flow[1] + str(packet_flow[2]) + str(packet_flow[3]) + str(packet_flow[4])
        s2 = s + ' '
        value = hash(s)
        value2 = hash(s2)
        return value % 450000, value2 % 450000  # Return the hashed value of the packet_flow

    def increment(self, l, il):
        if l == 0:
            if 0 <= self.sketch[l][0][il] <= 254:
                self.sketch[l][0][il] += 1
            if self.sketch[l][0][il] == 255:
                self.increment(l + 1, il // 100)
        elif l == 1:
            if 0 <= self.sketch[l][0][il] <= 65534:
                self.sketch[l][0][il] += 1
            if self.sketch[l][0][il] == 65535:
                self.increment(l + 1, il // 100)
        else:
            if 0 <= self.sketch[l][0][il] <= 4294967294:
                self.sketch[l][0][il] += 1

    def increment2(self, l, il):
        if l == 0:
            if 0 <= self.sketch2[l][0][il] <= 254:
                self.sketch2[l][0][il] += 1
            if self.sketch2[l][0][il] == 255:
                self.increment2(l + 1, il // 100)
        elif l == 1:
            if 0 <= self.sketch2[l][0][il] <= 65534:
                self.sketch2[l][0][il] += 1
            if self.sketch2[l][0][il] == 65535:
                self.increment2(l + 1, il // 100)
        else:
            if 0 <= self.sketch2[l][0][il] <= 4294967294:
                self.sketch2[l][0][il] += 1

    def add_item(self, packet_flow, packet_len):
        """ Update sketch for the current packet in stream

        Args:
            packet_flow : Tuple of (Source_IP, Destination_IP, Source_Port, Destination_Port, Protocol)
            packet_len: Integer value of packet length
        """

        """ YOUR CODE HERE
        TODO: Implement the sketch update algorithm
        """

        hash_value, hash_value2 = self.hash_func(packet_flow)
        self.increment(0, hash_value)
        self.increment2(0, hash_value2)
        flow_count = self.estimate_frequency(packet_flow)
        if len(self.auxiliary_storage) < 100:
            self.auxiliary_storage[packet_flow] = flow_count
            if len(self.auxiliary_storage) == 100:
                sort = sorted(self.auxiliary_storage.items(), key=lambda d: d[1], reverse=False)
                self.min_count = sort[0][1]
        else:
            # if flow_count > self.min_count:
            #     sort = sorted(self.auxiliary_storage.items(), key=lambda d: d[1], reverse=False)
            #     min_flow = sort[0][0]
            #     del self.auxiliary_storage[min_flow]
            #     self.auxiliary_storage[packet_flow] = flow_count
            #     sort = sorted(self.auxiliary_storage.items(), key=lambda d: d[1], reverse=False)
            #     self.min_count = sort[0][1]
            sort = sorted(self.auxiliary_storage.items(), key=lambda d: d[1], reverse=False)
            min_flow = sort[0][0]
            min_count = sort[0][1]
            if flow_count > min_count:
                del self.auxiliary_storage[min_flow]
                self.auxiliary_storage[packet_flow] = flow_count

    def estimate_frequency(self, flow_X):
        """Estimate the frequency of flow_X using the sketch

        Args:
            flow_X: Tuple of (Source_IP, Destination_IP, Source_Port, Destination_Port, Protocol)

        Returns:
            Observed frequency of flow_X
        """

        ###### Task I - Freuqency Estimation ######
        flow_freq = 0

        """ YOUR CODE HERE
        TODO: Implement the frequency estimation algorithm
        """

        hash_value, hash_value2 = self.hash_func(flow_X)
        rst = 0
        rst2 = 0
        if self.sketch[0][0][hash_value] == 255:
            rst += 254
            temp = hash_value // 100
            if self.sketch[1][0][temp] == 65535:
                rst += 65534
                rst += self.sketch[2][0][temp // 100]
            else:
                rst += self.sketch[1][0][temp]
        else:
            rst += self.sketch[0][0][hash_value]

        if self.sketch2[0][0][hash_value2] == 255:
            rst2 += 254
            temp = hash_value2 // 100
            if self.sketch2[1][0][temp] == 65535:
                rst2 += 65534
                rst2 += self.sketch2[2][0][temp // 100]
            else:
                rst2 += self.sketch2[1][0][temp]
        else:
            rst2 += self.sketch2[0][0][hash_value2]

        flow_freq = min(rst, rst2)
        return flow_freq

    def count_unique_flows(self):
        """ Estimate the number of unique flows(Cardinality) using the sketch

        Returns:
            Cardinality of the packet trace
        """

        ###### Task II - Cardinality Estimation ######
        num_unique_flows = 0

        """ YOUR CODE HERE
        TODO: Implement the cardinality estimation algorithm
        """

        count1 = 0
        count2 = 0
        for i in range(len(self.sketch[0][0])):
            if self.sketch[0][0][i] == 0:
                count1 += 1
        for i in range(len(self.sketch2[0][0])):
            if self.sketch2[0][0][i] == 0:
                count2 += 1
        count = (count1 + count2) / 2
        # print(count)
        num_unique_flows = -450000 * np.log(count / 450000)
        return num_unique_flows

    def find_heavy_hitters(self):
        """ Find the heavy hitters using the sketch

        Returns:
            heavy_hitters: 5-Tuples representing the heavy hitter flows
            heavy_hitters_size: Size of the heavy hitter flows
        """
        ###### Task III - Heavy Hitter Detection ######
        heavy_hitters = []  # List to store heavy hitter flows
        heavy_hitters_size = []  # List to store heavy hitter sizes

        """ YOUR CODE HERE
        TODO: Implement the heavy hitter detection algorithm
        """

        for key, value in self.auxiliary_storage.items():
            heavy_hitters.append(key)
            heavy_hitters_size.append(value)

        return heavy_hitters, heavy_hitters_size
