# A-2: Secret Message Exchange (4%)

## Introduction
The objective of this exercise is to implement a dead drop facility to enable secret message exchange through a switch written in P4.
The dead drop facility has two components: `secret_mailboxes` and `msg_checksums`, which can hold up to 64K entries.

When the switch receives a `DROPOFF` message, it will store the message in the designated `secret_mailbox` and computes a checksum for the message which will then be stored in the `msg_checksum`.
Once the `DROPOFF` is successful, it will return a `SUCCESS` message.

On the other hand, when the switch receives a `PICKUP` message, it will retrieve the message from the corresponding `secret_mailbox`.
At the same time, the checksum of the retrieved message will be computed and compared against the checksum stored in `msg_checksum`.
If the checksum matches, a `SUCCESS` message will be returned, otherwise, a `FAILURE` message will be sent.
Once the message is retrieved from the `secret_mailbox`, the accessed `secret_mailbox` must be "sanitized" and overwritten with the value `0xdeadbeef`.

The `secret_mailboxes` and `msg_checksums` are implemented using stateful memory -- register arrays, on the P4 switch. 
The switch must first verify that the message is indeed destined for it with the destination IP `10.0.0.254`.
The dead drop facility uses UDP ports `0xFFFF`, and must be accompanied by an 8-byte `SECRET` header with the following format:

```
         0                1                  2              3
  +----------------+----------------+----------------+---------------+
  |             opCode              |            mailboxNum          |
  +----------------+----------------+----------------+---------------+
  |                              message                             |
  +----------------+----------------+----------------+---------------+

```

## Step 1: Run the (incomplete) starter code

The directory with this README also contains a skeleton P4 program, `secret.p4`, which can only forward packet between the two hosts, `h1` and `h2`. 
Your job will be to extend this skeleton program to support the dead drop facility.

Before that, let's compile the incomplete `secret.p4` and bring
up a switch in Mininet to test its behavior.

1. In your shell, run:
   ```bash
   make run
   ```
   This will:
   * compile `secret.p4`, and
   * start the pod-topo in Mininet, and
   * configure all hosts with the commands listed in
   [pod-topo/topology.json](./pod-topo/topology.json)

2. We have implemented two Python-based programs that allows us to deposit and retrieve secret messages from the switch. You can run the programs directly from the Mininet command prompt:
   ```bash
   mininet> h1 ./message_dropoff.py 1 hello    # to dropoff message "hello" at mailbox #1
   ... (output omitted)
   Timeout! No message received.
   mininet> h2 ./message_pickup.py 1    # to pickup message at mailbox #1
   ... (output omitted)
   Timeout! No message received.
   ```

3. No message shall be returned by the switch the dead drop facility is not implemented. Type `exit` to leave each xterm and the Mininet command line.
   Then, to stop mininet:
   ```bash
   make stop
   ```
   And to delete all pcaps, build files, and logs:
   ```bash
   make clean
   ```

Your job is to extend this file to implement the necessary logic to realize the dead drop facility to faciliate secret message exchange.

## Step 2: Enabling Secret Message Exchange
The `secret.p4` file contains a skeleton P4 program with key pieces of
logic replaced by `TODO` comments. 
Your implementation should follow the structure given in this file---replace each `TODO` with logic implementing the missing piece.

## Step 3: Run your solution

1. Follow the instructions from Step 1. This time, you should be able to sucessfully dropoff a message using `h1` and retrieve the corresponding message using `h2`.

2. In addition, you should also make sure that if the secret message is tampered with, the switch should return with a `FAILURE` message after comparing the checksums. To simulate that, follow the steps below:

   a. Dropoff secret message using `h1`.
   ```bash
   mininet> h1 ./message_dropoff.py 1 hello  # to dropoff message "hello" at mailbox #1
   ```

   b. Modify secret messages stored in the switch (separate terminal).
   ```bash
   p4@p4: ./modify_state.sh
   ```

   c. Attempt to retrieve the message with `h2`.
   ```bash
   mininet> h2 ./message_pickup.py 1    # to pickup message from mailbox #1
   ```

   The message returned should be with the OpCode set to `FAILURE` -- 0x0000.

### Troubleshooting
There are several problems that might manifest as you develop your program:

1. `secret.p4` might fail to compile. In this case, `make run` will report the error emitted from the compiler and halt.

2. `fake_ping.p4` might compile but `h1` might fail to get any ICMP Echo Responses. The `logs/sX.log` files contain detailed logs that describing how each switch processes each packet. The output is detailed and can help pinpoint logic errors in your implementation. At the same time, you can also take a look at the PCAPs under `pcaps/`.

#### Cleaning up Mininet
In the latter two cases above, `make run` may leave a Mininet instance
running in the background. Use the following command to clean up
these instances:

```bash
make stop
```

## Running the Packet Test Framework (PTF)
We will be grading your using the Packet Test Framework (PTF), which allows us to specify test cases with different input/output packets to verify your P4 data plane program behavior.
This is inline with modern software engineering practices.

We have provided some public test cases that you can use to quickly test your program.
For that, simply do `./runptf.sh`.

Note that passing all the public test cases do not necessarily mean that you will get full marks for the exercise as there are other hidden test cases that will be used during grading.
In addition, not all public test cases will be scored as some are purely for sanity check.

## Relevant Documentation

The documentation for P4_16 and P4Runtime is available [here](https://p4.org/specs/).

All excercises in this repository use the `v1model` architecture, the documentation for which is available at:
1. The BMv2 Simple Switch target document accessible [here](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md) talks mainly about the `v1model` architecture.
2. The include file `v1model.p4` has extensive comments and can be accessed [here](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4).