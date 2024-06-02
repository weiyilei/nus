/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_SECRET = 0xFFFF;
const bit<32> SWITCH_IP = 0x0a0000FE;
const bit<8>  TYPE_UDP  = 17;

enum bit<16> SECRET_OPT {
    DROPOFF = 0x0001,
    PICKUP  = 0x0002,
    SUCCESS = 0xFFFF,
    FAILURE = 0x0000
}

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
    /* Hint: define ICMP header */
    bit<8>  type;
    bit<8>  code;
    bit<16> checksum;
}

header udp_t {
    /* TODO: your code here */
    /* Hint: define UDP header */
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> len;
    bit<16> checksum;
}

header secret_t {
    bit<16> opCode; 
    bit<16> mailboxNum;
    bit<32> message;
}

struct metadata {
    /* empty */
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    udp_t        udp;
    secret_t     secret;
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

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol){
            TYPE_UDP: parse_udp;
            default: accept;
        }
    }

    state parse_udp {
       packet.extract(hdr.udp);
       transition select(hdr.udp.srcPort, hdr.udp.dstPort){
            (TYPE_SECRET, TYPE_SECRET): parse_secret;
            default: accept;
        }
    }

     state parse_secret {
       packet.extract(hdr.secret);
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
    
    register<bit<32>>(65536) secret_mailboxes;
    register<bit<32>>(65536) msg_checksums;

    action drop() {
        mark_to_drop(standard_metadata);
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
        default_action = drop();
    }

    apply {
        if(hdr.secret.isValid()) {
            /* TODO: your code here */
            /* Hint 1: verify if the secret message is destined to the switch */
            /* Hint 2: there are two cases to handle -- DROPOFF, PICKUP */
            /* Hint 3: what happens when you PICKUP from an empty mailbox? */
            /* Hint 4: remember to "sanitize" your mailbox with 0xdeadbeef after every PICKUP */
            /* Hint 5: msg_checksums are important! */
            /* Hint 6: once everything is done, swap addresses, set port and reply to sender */
            if (hdr.ipv4.dstAddr == SWITCH_IP){
                bit<32> checksum;
                bit<32> storedChecksum;
                bit<32> storedMessage;
                bit<32> index = (bit<32>) hdr.secret.mailboxNum;
                if (index > (bit<32>)65536) {
                    drop();
                    return;
                }
                msg_checksums.read(storedChecksum, index);
                secret_mailboxes.read(storedMessage, index);
                if (hdr.secret.opCode == SECRET_OPT.DROPOFF) {
                    if (storedChecksum != 0x0) {
                        // non empty mailbox
                        hdr.secret.opCode = SECRET_OPT.FAILURE;
                    } else {
                        // store the message in the secret_mailbox, compute checksum for the message and store in the msg_checksum, return a SUCCESS message
                        hash(checksum, HashAlgorithm.crc32, (bit<32>)0, {hdr.secret.message}, (bit<32>)65536);
                        secret_mailboxes.write(index, hdr.secret.message);
                        msg_checksums.write(index, checksum);
                        hdr.secret.opCode = SECRET_OPT.SUCCESS;
                    }
                } else if (hdr.secret.opCode == SECRET_OPT.PICKUP) {
                    if (storedChecksum == 0x0) {
                        // empty mailbox
                        hdr.secret.opCode = SECRET_OPT.FAILURE;
                    } else {
                        // retrieve message, compare against checksum, return SUCCESS/FAILURE message, overwrite secret_mailbox with 0xdeadbeef
                        hash(checksum, HashAlgorithm.crc32, (bit<32>)0, {storedMessage}, (bit<32>)65536);
                        if (storedChecksum == checksum) {
                            hdr.secret.opCode = SECRET_OPT.SUCCESS;
                            hdr.secret.message = storedMessage;
                            msg_checksums.write(index, 0x0);
                            secret_mailboxes.write(index, 0xdeadbeef);
                        } else {
                            hdr.secret.opCode = SECRET_OPT.FAILURE;
                            hdr.secret.message = 0x0;
                        }
                    }
                } else {
                    drop();
                    return;
                }
                bit<32> tmpIP = hdr.ipv4.dstAddr;
                hdr.ipv4.dstAddr = hdr.ipv4.srcAddr;
                hdr.ipv4.srcAddr = tmpIP;
                bit<48> tmpMac = hdr.ethernet.dstAddr;
                hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
                hdr.ethernet.srcAddr = tmpMac;
            }
        } 
        ipv4_forward.apply();
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
     apply {
        update_checksum(
            hdr.ipv4.isValid(),
            { 
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr 
            },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16
        );
    }
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        /* TODO: your code here */
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.secret);
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
