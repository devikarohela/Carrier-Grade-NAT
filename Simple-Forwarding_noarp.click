/*
* In this script, a EtherEncap element is used to replace ARPQuerier.
* This script works when encountering something bad.
*/


define(
 $iface0    0,
 $iface1    1,
 $queueSize 1024,
 $burst     32

 $left_mac     52:54:00:7f:78:46,   //These MACs are based on the machine which we are going to use for Demo
 $left_if_mac  52:54:00:62:68:b1,
 $right_mac    52:54:00:e0:67:cb,
 $right_if_mac 52:54:00:75:a7:dc,

 $left_ip  192.168.100.254,
 $right_ip 192.168.200.166,

);

AddressInfo(
    left_interface     $left_ip     $left_mac, 
    right_interface    $right_ip    $right_mac
);

// Module's I/O
nicIn0  :: FromDPDKDevice($iface0, BURST $burst, PROMISC true, SCALE parallel, VERBOSE 99);
nicOut0 :: ToDPDKDevice  ($iface0, IQUEUE $queueSize, BURST $burst);

nicIn1  :: FromDPDKDevice($iface1, BURST $burst, PROMISC true, SCALE parallel, VERBOSE 99);
nicOut1 :: ToDPDKDevice  ($iface1, IQUEUE $queueSize, BURST $burst);

class_left :: Classifier(12/0806 20/0001,  //ARP query
                         12/0806 20/0002,  // ARP response
                         12/0800); //Any other

arpq_left :: EtherEncap(0x0800, $left_mac, $left_if_mac) -> nicOut0; //The packet will go to left interface

class_right :: Classifier(12/0806 20/0001,  //ARP query
                         12/0806 20/0002,  // ARP response
                         12/0800); //Any Other

arpq_right :: EtherEncap(0x0800, $right_mac, $right_if_mac) -> nicOut1; //The packet will go to right interface


nicIn0 -> class_left;

class_left[0] -> ARPResponder(left_interface) -> nicOut0;
class_left[1] -> Discard;
class_left[2] -> Strip(14)-> CheckIPHeader -> arpq_right -> nicOut1;

nicIn1 -> class_right;

class_right[0] -> ARPResponder(right_interface) -> nicOut1;
class_right[1] -> Discard;
class_right[2] -> Strip(14)-> CheckIPHeader -> arpq_left -> nicOut0;
