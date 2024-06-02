/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;

#define SKETCH_ROW_LENGTH 65536
#define SKETCH_CELL_BIT_WIDTH 32

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header icmp_t {
    /* TODO: your code here */
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
}

header tcp_t {
    /* TODO: your code here */
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> sequenceNumber;
    bit<32> ACKNumber;
    bit<4> dataOffset;
    bit<4> reserved;
    bit<1> CWR;
    bit<1> ECE;
    bit<1> URG;
    bit<1> ACK;
    bit<1> PSH;
    bit<1> RST;
    bit<1> SYN;
    bit<1> FIN;
    bit<16> windowSize;
    bit<16> checksum;
    bit<16> urgentPointer;
}

header udp_t {
    /* TODO: your code here */
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> len;
    bit<16> checksum;
}

struct metadata {
    /* TODO: your code here */
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    icmp_t       icmp;
    tcp_t        tcp;
    udp_t        udp;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        /* TODO: your code here */
        /* Hint: implement your parser */
        transition parse_ethernet;
    }

    state parse_ethernet{
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4{
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol){
            1: parse_icmp;
            6: parse_tcp;
            17: parse_udp;
            default: accept;
        }
    }

    state parse_icmp{
        packet.extract(hdr.icmp);
        transition accept;
    }

    state parse_tcp{
        packet.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp{
        packet.extract(hdr.udp);
        transition accept;
    }
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    
    bit<32> hh_threshold = 0;
    bit<32> drop_threshold = 0;
    
    /* sketch data structure */
    /* Note: you may modify this structure as you wish */
    register<bit<4>> (524288)  sketch_row0;  // 32/8 * 65536*8
    register<bit<8>> (262144)  sketch_row1;  // 32/4 * 65536*4
    register<bit<16>> (131072)  sketch_row2;  // 32/2 * 65536*2
    register<bit<32>> (SKETCH_ROW_LENGTH)  sketch_row3;  //32 * 65536

    /* TODO: your code here, if needed ;) */
    register<bit<1>> (524288) duplicate_check;
    bit<1> duplicate;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
    bit<16> srcPort;
    bit<16> dstPort;
    bit<8> protocol;
    bit<32> hash_position;
    bit<4> layer0Num;
    bit<8> layer1Num;
    bit<16> layer2Num;
    bit<32> layer3Num;
    bit<4> es_layer0Num;
    bit<8> es_layer1Num;
    bit<16> es_layer2Num;
    bit<32> es_layer3Num;
    bit<32> flow_estimate;

    // action increment_layer3(bit<32> position){
    //     sketch_row3.read(layer3Num, position);
    //         if(0 <= layer3Num && layer3Num <= 4294967294){
    //             layer3Num = layer3Num + 1;
    //             sketch_row3.write(position, layer3Num);
    //         }
    // }

    // action increment_layer2(bit<32> position){
    //     sketch_row2.read(layer2Num, position);
    //         if(0 <= layer2Num && layer2Num <= 65534){
    //             layer2Num = layer2Num + 1;
    //             sketch_row2.write(position, layer2Num);
    //         }
    //         sketch_row2.read(layer2Num, position);
    //         if(layer2Num == 65535){
    //             increment_layer3(position / 2);
    //         }
    // }

    // action increment_layer1(bit<32> position){
    //     sketch_row1.read(layer1Num, position);
    //         if(0 <= layer1Num && layer1Num <= 254){
    //             layer1Num = layer1Num + 1;
    //             sketch_row1.write(position, layer1Num);
    //         }
    //         sketch_row1.read(layer1Num, position);
    //         if(layer1Num == 255){
    //             increment_layer2(position / 2);
    //         }
    // }

    // action increment_layer0(bit<32>position){
    //     sketch_row0.read(layer0Num, position);
    //         if(0 <= layer0Num && layer0Num <= 14){
    //             layer0Num = layer0Num + 1;
    //             sketch_row0.write(position, layer0Num);
    //         }
    //         sketch_row0.read(layer0Num, position);
    //         if(layer0Num == 15){
    //             increment_layer1(position / 2);
    //         }
    // }

    // action increment(bit<2> layer, bit<19> position){
    //     if(layer == 0){
    //         sketch_row0.read(layer0Num, position);
    //         if(0 <= layer0Num <= 14){
    //             layer0Num = layer0Num + 1;
    //             sketch_row0.write(position, layer0Num);
    //         }
    //         sketch_row0.read(layer0Num, position);
    //         if(layer0Num == 15){
    //             increment(layer + 1, position / 2);
    //         }
    //     }
    //     else if(layer == 1){
    //         sketch_row1.read(layer1Num, position);
    //         if(0 <= layer1Num <= 254){
    //             layer1Num = layer1Num + 1;
    //             sketch_row1.write(position, layer1Num);
    //         }
    //         sketch_row1.read(layer1Num, position);
    //         if(layer1Num == 255){
    //             increment(layer + 1, position / 2);
    //         }
    //     }
    //     else if(layer == 2){
    //         sketch_row2.read(layer2Num, position);
    //         if(0 <= layer2Num <= 65534){
    //             layer2Num = layer2Num + 1;
    //             sketch_row2.write(position, layer2Num);
    //         }
    //         sketch_row2.read(layer2Num, position);
    //         if(layer2Num == 65535){
    //             increment(layer + 1, position / 2);
    //         }
    //     }
    //     else{
    //         sketch_row3.read(layer3Num, position);
    //         if(0 <= layer3Num <= 4294967294){
    //             layer3Num = layer3Num + 1;
    //             sketch_row3.write(position, layer3Num);
    //         }
    //     }
    // }

    // action estimate(inout bit<32> rst, bit<32> position){
    //     bit<32> temp;
    //     rst = 0;
    //     sketch_row0.read(es_layer0Num, position);
    //     if(es_layer0Num == 15){
    //         rst = rst + 14;
    //         temp = position / 2;
    //         sketch_row1.read(es_layer1Num, temp);
    //         if(es_layer1Num == 255){
    //             rst = rst + 254;
    //             temp = temp / 2;
    //             sketch_row2.read(es_layer2Num, temp);
    //             if(es_layer2Num == 65535){
    //                 rst = rst + 65534;
    //                 temp = temp / 2;
    //                 sketch_row3.read(es_layer3Num, temp);
    //                 rst = rst + es_layer3Num;
    //             }
    //             else{
    //                 rst = rst + (bit<32>)es_layer2Num;
    //             }
    //         }
    //         else{
    //             rst = rst + (bit<32>)es_layer1Num;
    //         }
    //     }
    //     else{
    //         rst = rst + (bit<32>)es_layer0Num;
    //     }
    // }
    // ...

    action mirror_heavy_flow() {
        clone(CloneType.I2E, 0);    // mirror detected heavy flows to ports under session 0.
    }
    
    action drop() {
        mark_to_drop(standard_metadata);
    }

    action get_thresholds_action(bit<32> hh_threshold_param, bit<32> drop_threshold_param) {
        hh_threshold = hh_threshold_param;
        drop_threshold = drop_threshold_param;
    }

    table get_thresholds {
        key = {}
        actions = {
            NoAction;
            get_thresholds_action;
        }
        default_action = NoAction();
    }

    action ipv4_forward_action(egressSpec_t port) {
        standard_metadata.egress_spec = port;
    }

    table ipv4_forward {
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        actions = {
            ipv4_forward_action;
            drop;
        }
        size = 1024;
        default_action = drop();
    }

    apply {
        if (hdr.ipv4.isValid()) {
            /* TODO: your code here */
            get_thresholds.apply();
            srcAddr = 0;
            dstAddr = 0;
            srcPort = 0;
            dstPort = 0;
            protocol = 0;
            flow_estimate = 0;
            bit<32> temp = 0;
            /* Hint 1: update the sketch and get the latest estimation */
            if(hdr.icmp.isValid()){
                srcAddr = hdr.ipv4.srcAddr;
                dstAddr = hdr.ipv4.dstAddr;
                srcPort = 0;
                dstPort = 0;
                protocol = hdr.ipv4.protocol;
            }
            else if(hdr.tcp.isValid()){
                srcAddr = hdr.ipv4.srcAddr;
                dstAddr = hdr.ipv4.dstAddr;
                srcPort = hdr.tcp.srcPort;
                dstPort = hdr.tcp.dstPort;
                protocol = hdr.ipv4.protocol;
            }
            else if(hdr.udp.isValid()){
                srcAddr = hdr.ipv4.srcAddr;
                dstAddr = hdr.ipv4.dstAddr;
                srcPort = hdr.udp.srcPort;
                dstPort = hdr.udp.dstPort;
                protocol = hdr.ipv4.protocol;
            }
            // log_msg("{}, {}, {}, {}, {}", {srcAddr, dstAddr, srcPort, dstPort, protocol});
            hash(hash_position, HashAlgorithm.crc32, (bit<32>)0, {srcAddr, dstAddr, srcPort, dstPort, protocol}, (bit<32>)524288);
            log_msg("The hash value is {}", {hash_position});
            sketch_row0.read(layer0Num, hash_position);
            if(0 <= layer0Num && layer0Num <= 14){
                layer0Num = layer0Num + 1;
                sketch_row0.write(hash_position, layer0Num);
            }
            sketch_row0.read(layer0Num, hash_position);
            if(layer0Num == 15){
                temp = hash_position / 2;
                sketch_row1.read(layer1Num, temp);
                if(0 <= layer1Num && layer1Num <= 254){
                    layer1Num = layer1Num + 1;
                    sketch_row1.write(temp, layer1Num);
                }
                sketch_row1.read(layer1Num, temp);
                if(layer1Num == 255){
                    temp = temp / 2;
                    sketch_row2.read(layer2Num, temp);
                    if(0 <= layer2Num && layer2Num <= 65534){
                        layer2Num = layer2Num + 1;
                        sketch_row2.write(temp, layer2Num);
                    }
                    sketch_row2.read(layer2Num, temp);
                    if(layer2Num == 65535){
                        temp = temp / 2;
                        sketch_row3.read(layer3Num, temp);
                        if(0 <= layer3Num && layer3Num <= 4294967294){
                            layer3Num = layer3Num + 1;
                            sketch_row3.write(temp, layer3Num);
                        }
                    }
                }
            }
            // increment_layer0(hash_position);
            temp = 0;
            sketch_row0.read(es_layer0Num, hash_position);
            if(es_layer0Num == 15){
                flow_estimate = flow_estimate + 14;
                temp = hash_position / 2;
                sketch_row1.read(es_layer1Num, temp);
                if(es_layer1Num == 255){
                    flow_estimate = flow_estimate + 254;
                    temp = temp / 2;
                    sketch_row2.read(es_layer2Num, temp);
                    if(es_layer2Num == 65535){
                        flow_estimate = flow_estimate + 65534;
                        temp = temp / 2;
                        sketch_row3.read(es_layer3Num, temp);
                        flow_estimate = flow_estimate + es_layer3Num;
                    }
                    else{
                        flow_estimate = flow_estimate + (bit<32>)es_layer2Num;
                    }
                }
                else{
                    flow_estimate = flow_estimate + (bit<32>)es_layer1Num;
                }
            }
            else{
                flow_estimate = flow_estimate + (bit<32>)es_layer0Num;
            }
            log_msg("flow_estimate is {}", {flow_estimate});
            // estimate(flow_estimate, hash_position);
            /* Hint 2: compare the estimation with the hh_threshold */
            /* Hint 3: to report HH flow, call mirror_heavy_flow() */
            if(flow_estimate > hh_threshold){
                duplicate_check.read(duplicate, hash_position);
                log_msg("duplicate is {}", {duplicate});
                if(duplicate == 0){
                    mirror_heavy_flow();
                    duplicate_check.write(hash_position, 1);
                    log_msg("weiyilei");
                }
            }
            /* Hint 4: how to ensure no duplicate HH reports to collector? */
            /* Hint 5: check drop_threshold, and drop if it is a potential DNS amplification attack */
            ipv4_forward.apply();
        } 
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        /* TODO: your code here */
        packet.emit(hdr);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    MyIngress(),
    MyEgress(),
    MyComputeChecksum(),
    MyDeparser()
) main;
