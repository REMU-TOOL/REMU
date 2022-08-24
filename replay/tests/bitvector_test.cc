#include "bitvector.h"

#include <iostream>

using namespace Replay;

#define EXPECT(x, res) \
    do { \
        std::cout << "Expected " #x " to be " #res; \
        auto expr = x; \
        if (expr != (res)) { \
            std::cout << " but got " << std::hex << expr << std::endl; \
            return false; \
        } \
        std::cout << std::endl; \
    } while (0)

bool test_bitvector_construct()
{
    BitVector a(32);
    EXPECT(a, 0);

    BitVector b(64, 0x1234567812345678);
    EXPECT(b, 0x1234567812345678);

    BitVector c(32, 0x1234567812345678);
    EXPECT(c, 0x12345678);
    EXPECT(b == c, false);

    BitVector c1(c);
    EXPECT(c1.width(), 32);
    EXPECT(c1, 0x12345678);
    EXPECT(c1 == c, true);

    BitVector c2(BitVector(32, 0x12345678));
    EXPECT(c1 == c2, true);
    c1 = c2;
    EXPECT(c1 == c2, true);
    c2 = BitVector(32, 0xabc12345678);
    EXPECT(c1 == c2, true);

    BitVector d(0, 0xffffffff);
    EXPECT(d, 0);

    uint64_t arr1[] = {0x2222222211111111, 0x4444444433333333, 0xffffffff};
    BitVector e1(128, arr1);
    BitVector e2(128, arr1, 5);
    BitVector e3(128, {0x2222222211111111, 0x4444444433333333, 0xffffffff});
    EXPECT(e1.width(), 128);
    EXPECT(e1, 0x2222222211111111);
    EXPECT(e1 == e2, true);
    EXPECT(e1 != e2, false);
    EXPECT(e1 == e3, true);
    EXPECT(e1 != e3, false);
    BitVector e4(e1);
    EXPECT(e1 == e4, true);
    BitVector e5(BitVector(128, arr1));
    EXPECT(e1 == e5, true);
    BitVector e6(0);
    e6 = e1;
    EXPECT(e1 == e6, true);
    BitVector e7(0);
    e7 = BitVector(128, arr1);
    EXPECT(e1 == e7, true);

    EXPECT(a == b, false);
    EXPECT(a == c, false);
    EXPECT(a == d, false);

    return true;
}

bool test_bitvector_get()
{
    BitVector a1(80, {0x8765432112345678, 0xaabbccdd});
    BitVector a2(63, 0x666ec3b2a190891a);
    EXPECT(a1, 0x8765432112345678);
    EXPECT(a1.getValue(0, 32), 0x12345678);
    EXPECT(a1.getValue(0, 16), 0x5678);
    EXPECT(a1.getValue(16, 16), 0x1234);
    EXPECT(a1.getValue(16, 64), 0xccdd876543211234);
    EXPECT(a1.getValue(17, 63) == a2, true);

    BitVector b(256, {0x1111111111111111, 0x2222222222222222, 0x3333333333333333, 0x4444444444444444});
    EXPECT(b.getValue(0, 64), 0x1111111111111111);
    EXPECT(b.getValue(1, 64), 0x888888888888888);
    EXPECT(b.getValue(2, 64), 0x8444444444444444);
    EXPECT(b.getValue(3, 64), 0x4222222222222222);
    EXPECT(b.getValue(4, 64), 0x2111111111111111);
    EXPECT(b.getValue(5, 64), 0x1088888888888888);
    EXPECT(b.getValue(6, 64), 0x8844444444444444);
    EXPECT(b.getValue(7, 64), 0x4422222222222222);
    EXPECT(b.getValue(8, 64), 0x2211111111111111);
    EXPECT(b.getValue(9, 64), 0x1108888888888888);
    EXPECT(b.getValue(10, 64), 0x8884444444444444);
    EXPECT(b.getValue(11, 64), 0x4442222222222222);
    EXPECT(b.getValue(12, 64), 0x2221111111111111);
    EXPECT(b.getValue(13, 64), 0x1110888888888888);
    EXPECT(b.getValue(14, 64), 0x8888444444444444);
    EXPECT(b.getValue(15, 64), 0x4444222222222222);
    EXPECT(b.getValue(16, 64), 0x2222111111111111);
    EXPECT(b.getValue(17, 64), 0x1111088888888888);
    EXPECT(b.getValue(18, 64), 0x8888844444444444);
    EXPECT(b.getValue(19, 64), 0x4444422222222222);
    EXPECT(b.getValue(20, 64), 0x2222211111111111);
    EXPECT(b.getValue(21, 64), 0x1111108888888888);
    EXPECT(b.getValue(22, 64), 0x8888884444444444);
    EXPECT(b.getValue(23, 64), 0x4444442222222222);
    EXPECT(b.getValue(24, 64), 0x2222221111111111);
    EXPECT(b.getValue(25, 64), 0x1111110888888888);
    EXPECT(b.getValue(26, 64), 0x8888888444444444);
    EXPECT(b.getValue(27, 64), 0x4444444222222222);
    EXPECT(b.getValue(28, 64), 0x2222222111111111);
    EXPECT(b.getValue(29, 64), 0x1111111088888888);
    EXPECT(b.getValue(30, 64), 0x8888888844444444);
    EXPECT(b.getValue(31, 64), 0x4444444422222222);
    EXPECT(b.getValue(32, 64), 0x2222222211111111);
    EXPECT(b.getValue(33, 64), 0x1111111108888888);
    EXPECT(b.getValue(34, 64), 0x8888888884444444);
    EXPECT(b.getValue(35, 64), 0x4444444442222222);
    EXPECT(b.getValue(36, 64), 0x2222222221111111);
    EXPECT(b.getValue(37, 64), 0x1111111110888888);
    EXPECT(b.getValue(38, 64), 0x8888888888444444);
    EXPECT(b.getValue(39, 64), 0x4444444444222222);
    EXPECT(b.getValue(40, 64), 0x2222222222111111);
    EXPECT(b.getValue(41, 64), 0x1111111111088888);
    EXPECT(b.getValue(42, 64), 0x8888888888844444);
    EXPECT(b.getValue(43, 64), 0x4444444444422222);
    EXPECT(b.getValue(44, 64), 0x2222222222211111);
    EXPECT(b.getValue(45, 64), 0x1111111111108888);
    EXPECT(b.getValue(46, 64), 0x8888888888884444);
    EXPECT(b.getValue(47, 64), 0x4444444444442222);
    EXPECT(b.getValue(48, 64), 0x2222222222221111);
    EXPECT(b.getValue(49, 64), 0x1111111111110888);
    EXPECT(b.getValue(50, 64), 0x8888888888888444);
    EXPECT(b.getValue(51, 64), 0x4444444444444222);
    EXPECT(b.getValue(52, 64), 0x2222222222222111);
    EXPECT(b.getValue(53, 64), 0x1111111111111088);
    EXPECT(b.getValue(54, 64), 0x8888888888888844);
    EXPECT(b.getValue(55, 64), 0x4444444444444422);
    EXPECT(b.getValue(56, 64), 0x2222222222222211);
    EXPECT(b.getValue(57, 64), 0x1111111111111108);
    EXPECT(b.getValue(58, 64), 0x8888888888888884);
    EXPECT(b.getValue(59, 64), 0x4444444444444442);
    EXPECT(b.getValue(60, 64), 0x2222222222222221);
    EXPECT(b.getValue(61, 64), 0x1111111111111110);
    EXPECT(b.getValue(62, 64), 0x8888888888888888);
    EXPECT(b.getValue(63, 64), 0x4444444444444444);
    EXPECT(b.getValue(64, 64), 0x2222222222222222);
    EXPECT(b.getValue(65, 64), 0x9111111111111111);
    EXPECT(b.getValue(66, 64), 0xc888888888888888);
    EXPECT(b.getValue(67, 64), 0x6444444444444444);
    EXPECT(b.getValue(68, 64), 0x3222222222222222);
    EXPECT(b.getValue(69, 64), 0x9911111111111111);
    EXPECT(b.getValue(70, 64), 0xcc88888888888888);
    EXPECT(b.getValue(71, 64), 0x6644444444444444);
    EXPECT(b.getValue(72, 64), 0x3322222222222222);
    EXPECT(b.getValue(73, 64), 0x9991111111111111);
    EXPECT(b.getValue(74, 64), 0xccc8888888888888);
    EXPECT(b.getValue(75, 64), 0x6664444444444444);
    EXPECT(b.getValue(76, 64), 0x3332222222222222);
    EXPECT(b.getValue(77, 64), 0x9999111111111111);
    EXPECT(b.getValue(78, 64), 0xcccc888888888888);
    EXPECT(b.getValue(79, 64), 0x6666444444444444);
    EXPECT(b.getValue(80, 64), 0x3333222222222222);
    EXPECT(b.getValue(81, 64), 0x9999911111111111);
    EXPECT(b.getValue(82, 64), 0xccccc88888888888);
    EXPECT(b.getValue(83, 64), 0x6666644444444444);
    EXPECT(b.getValue(84, 64), 0x3333322222222222);
    EXPECT(b.getValue(85, 64), 0x9999991111111111);
    EXPECT(b.getValue(86, 64), 0xcccccc8888888888);
    EXPECT(b.getValue(87, 64), 0x6666664444444444);
    EXPECT(b.getValue(88, 64), 0x3333332222222222);
    EXPECT(b.getValue(89, 64), 0x9999999111111111);
    EXPECT(b.getValue(90, 64), 0xccccccc888888888);
    EXPECT(b.getValue(91, 64), 0x6666666444444444);
    EXPECT(b.getValue(92, 64), 0x3333333222222222);
    EXPECT(b.getValue(93, 64), 0x9999999911111111);
    EXPECT(b.getValue(94, 64), 0xcccccccc88888888);
    EXPECT(b.getValue(95, 64), 0x6666666644444444);
    EXPECT(b.getValue(96, 64), 0x3333333322222222);
    EXPECT(b.getValue(97, 64), 0x9999999991111111);
    EXPECT(b.getValue(98, 64), 0xccccccccc8888888);
    EXPECT(b.getValue(99, 64), 0x6666666664444444);
    EXPECT(b.getValue(100, 64), 0x3333333332222222);
    EXPECT(b.getValue(101, 64), 0x9999999999111111);
    EXPECT(b.getValue(102, 64), 0xcccccccccc888888);
    EXPECT(b.getValue(103, 64), 0x6666666666444444);
    EXPECT(b.getValue(104, 64), 0x3333333333222222);
    EXPECT(b.getValue(105, 64), 0x9999999999911111);
    EXPECT(b.getValue(106, 64), 0xccccccccccc88888);
    EXPECT(b.getValue(107, 64), 0x6666666666644444);
    EXPECT(b.getValue(108, 64), 0x3333333333322222);
    EXPECT(b.getValue(109, 64), 0x9999999999991111);
    EXPECT(b.getValue(110, 64), 0xcccccccccccc8888);
    EXPECT(b.getValue(111, 64), 0x6666666666664444);
    EXPECT(b.getValue(112, 64), 0x3333333333332222);
    EXPECT(b.getValue(113, 64), 0x9999999999999111);
    EXPECT(b.getValue(114, 64), 0xccccccccccccc888);
    EXPECT(b.getValue(115, 64), 0x6666666666666444);
    EXPECT(b.getValue(116, 64), 0x3333333333333222);
    EXPECT(b.getValue(117, 64), 0x9999999999999911);
    EXPECT(b.getValue(118, 64), 0xcccccccccccccc88);
    EXPECT(b.getValue(119, 64), 0x6666666666666644);
    EXPECT(b.getValue(120, 64), 0x3333333333333322);
    EXPECT(b.getValue(121, 64), 0x9999999999999991);
    EXPECT(b.getValue(122, 64), 0xccccccccccccccc8);
    EXPECT(b.getValue(123, 64), 0x6666666666666664);
    EXPECT(b.getValue(124, 64), 0x3333333333333332);
    EXPECT(b.getValue(125, 64), 0x9999999999999999);
    EXPECT(b.getValue(126, 64), 0xcccccccccccccccc);
    EXPECT(b.getValue(127, 64), 0x6666666666666666);
    EXPECT(b.getValue(128, 64), 0x3333333333333333);
    EXPECT(b.getValue(129, 64), 0x1999999999999999);
    EXPECT(b.getValue(130, 64), 0xccccccccccccccc);
    EXPECT(b.getValue(131, 64), 0x8666666666666666);
    EXPECT(b.getValue(132, 64), 0x4333333333333333);
    EXPECT(b.getValue(133, 64), 0x2199999999999999);
    EXPECT(b.getValue(134, 64), 0x10cccccccccccccc);
    EXPECT(b.getValue(135, 64), 0x8866666666666666);
    EXPECT(b.getValue(136, 64), 0x4433333333333333);
    EXPECT(b.getValue(137, 64), 0x2219999999999999);
    EXPECT(b.getValue(138, 64), 0x110ccccccccccccc);
    EXPECT(b.getValue(139, 64), 0x8886666666666666);
    EXPECT(b.getValue(140, 64), 0x4443333333333333);
    EXPECT(b.getValue(141, 64), 0x2221999999999999);
    EXPECT(b.getValue(142, 64), 0x1110cccccccccccc);
    EXPECT(b.getValue(143, 64), 0x8888666666666666);
    EXPECT(b.getValue(144, 64), 0x4444333333333333);
    EXPECT(b.getValue(145, 64), 0x2222199999999999);
    EXPECT(b.getValue(146, 64), 0x11110ccccccccccc);
    EXPECT(b.getValue(147, 64), 0x8888866666666666);
    EXPECT(b.getValue(148, 64), 0x4444433333333333);
    EXPECT(b.getValue(149, 64), 0x2222219999999999);
    EXPECT(b.getValue(150, 64), 0x111110cccccccccc);
    EXPECT(b.getValue(151, 64), 0x8888886666666666);
    EXPECT(b.getValue(152, 64), 0x4444443333333333);
    EXPECT(b.getValue(153, 64), 0x2222221999999999);
    EXPECT(b.getValue(154, 64), 0x1111110ccccccccc);
    EXPECT(b.getValue(155, 64), 0x8888888666666666);
    EXPECT(b.getValue(156, 64), 0x4444444333333333);
    EXPECT(b.getValue(157, 64), 0x2222222199999999);
    EXPECT(b.getValue(158, 64), 0x11111110cccccccc);
    EXPECT(b.getValue(159, 64), 0x8888888866666666);
    EXPECT(b.getValue(160, 64), 0x4444444433333333);
    EXPECT(b.getValue(161, 64), 0x2222222219999999);
    EXPECT(b.getValue(162, 64), 0x111111110ccccccc);
    EXPECT(b.getValue(163, 64), 0x8888888886666666);
    EXPECT(b.getValue(164, 64), 0x4444444443333333);
    EXPECT(b.getValue(165, 64), 0x2222222221999999);
    EXPECT(b.getValue(166, 64), 0x1111111110cccccc);
    EXPECT(b.getValue(167, 64), 0x8888888888666666);
    EXPECT(b.getValue(168, 64), 0x4444444444333333);
    EXPECT(b.getValue(169, 64), 0x2222222222199999);
    EXPECT(b.getValue(170, 64), 0x11111111110ccccc);
    EXPECT(b.getValue(171, 64), 0x8888888888866666);
    EXPECT(b.getValue(172, 64), 0x4444444444433333);
    EXPECT(b.getValue(173, 64), 0x2222222222219999);
    EXPECT(b.getValue(174, 64), 0x111111111110cccc);
    EXPECT(b.getValue(175, 64), 0x8888888888886666);
    EXPECT(b.getValue(176, 64), 0x4444444444443333);
    EXPECT(b.getValue(177, 64), 0x2222222222221999);
    EXPECT(b.getValue(178, 64), 0x1111111111110ccc);
    EXPECT(b.getValue(179, 64), 0x8888888888888666);
    EXPECT(b.getValue(180, 64), 0x4444444444444333);
    EXPECT(b.getValue(181, 64), 0x2222222222222199);
    EXPECT(b.getValue(182, 64), 0x11111111111110cc);
    EXPECT(b.getValue(183, 64), 0x8888888888888866);
    EXPECT(b.getValue(184, 64), 0x4444444444444433);
    EXPECT(b.getValue(185, 64), 0x2222222222222219);
    EXPECT(b.getValue(186, 64), 0x111111111111110c);
    EXPECT(b.getValue(187, 64), 0x8888888888888886);
    EXPECT(b.getValue(188, 64), 0x4444444444444443);
    EXPECT(b.getValue(189, 64), 0x2222222222222221);
    EXPECT(b.getValue(190, 64), 0x1111111111111110);
    EXPECT(b.getValue(191, 64), 0x8888888888888888);

    BitVector c1(512, {
        0x1111111100000000,
        0x3333333322222222,
        0x5555555544444444,
        0x7777777766666666,
        0x9999999988888888,
        0xbbbbbbbbaaaaaaaa,
        0xddddddddcccccccc,
        0xffffffffeeeeeeee
    });
    BitVector c2(256, {
        0x2222111111110000,
        0x4444333333332222,
        0x6666555555554444,
        0x8888777777776666
    });
    BitVector c3(256, {
        0x2222222211111111,
        0x4444444433333333,
        0x6666666655555555,
        0x8888888877777777
    });
    EXPECT(c1.getValue(16, 256) == c2, true);
    EXPECT(c1.getValue(32, 256) == c3, true);

    return true;
}

bool test_bitvector_set()
{
    BitVector a(256);
    BitVector aa(96, {0x8765432112345678, 0xaabbccdd});
    BitVector a0(256, {0x8765432112345678, 0xaabbccdd, 0x0, 0x0});
    a.setValue(0, aa); EXPECT(a == a0, true);
    BitVector a4(256, {0x7654321123456788, 0xaabbccdd8, 0x0, 0x0});
    a.setValue(4, aa); EXPECT(a == a4, true);
    BitVector a8(256, {0x6543211234567888, 0xaabbccdd87, 0x0, 0x0});
    a.setValue(8, aa); EXPECT(a == a8, true);
    BitVector a12(256, {0x5432112345678888, 0xaabbccdd876, 0x0, 0x0});
    a.setValue(12, aa); EXPECT(a == a12, true);
    BitVector a16(256, {0x4321123456788888, 0xaabbccdd8765, 0x0, 0x0});
    a.setValue(16, aa); EXPECT(a == a16, true);
    BitVector a20(256, {0x3211234567888888, 0xaabbccdd87654, 0x0, 0x0});
    a.setValue(20, aa); EXPECT(a == a20, true);
    BitVector a24(256, {0x2112345678888888, 0xaabbccdd876543, 0x0, 0x0});
    a.setValue(24, aa); EXPECT(a == a24, true);
    BitVector a28(256, {0x1123456788888888, 0xaabbccdd8765432, 0x0, 0x0});
    a.setValue(28, aa); EXPECT(a == a28, true);
    BitVector a32(256, {0x1234567888888888, 0xaabbccdd87654321, 0x0, 0x0});
    a.setValue(32, aa); EXPECT(a == a32, true);
    BitVector a36(256, {0x2345678888888888, 0xabbccdd876543211, 0xa, 0x0});
    a.setValue(36, aa); EXPECT(a == a36, true);
    BitVector a40(256, {0x3456788888888888, 0xbbccdd8765432112, 0xaa, 0x0});
    a.setValue(40, aa); EXPECT(a == a40, true);
    BitVector a44(256, {0x4567888888888888, 0xbccdd87654321123, 0xaab, 0x0});
    a.setValue(44, aa); EXPECT(a == a44, true);
    BitVector a48(256, {0x5678888888888888, 0xccdd876543211234, 0xaabb, 0x0});
    a.setValue(48, aa); EXPECT(a == a48, true);
    BitVector a52(256, {0x6788888888888888, 0xcdd8765432112345, 0xaabbc, 0x0});
    a.setValue(52, aa); EXPECT(a == a52, true);
    BitVector a56(256, {0x7888888888888888, 0xdd87654321123456, 0xaabbcc, 0x0});
    a.setValue(56, aa); EXPECT(a == a56, true);
    BitVector a60(256, {0x8888888888888888, 0xd876543211234567, 0xaabbccd, 0x0});
    a.setValue(60, aa); EXPECT(a == a60, true);
    BitVector a64(256, {0x8888888888888888, 0x8765432112345678, 0xaabbccdd, 0x0});
    a.setValue(64, aa); EXPECT(a == a64, true);
    BitVector a68(256, {0x8888888888888888, 0x7654321123456788, 0xaabbccdd8, 0x0});
    a.setValue(68, aa); EXPECT(a == a68, true);
    BitVector a72(256, {0x8888888888888888, 0x6543211234567888, 0xaabbccdd87, 0x0});
    a.setValue(72, aa); EXPECT(a == a72, true);
    BitVector a76(256, {0x8888888888888888, 0x5432112345678888, 0xaabbccdd876, 0x0});
    a.setValue(76, aa); EXPECT(a == a76, true);
    BitVector a80(256, {0x8888888888888888, 0x4321123456788888, 0xaabbccdd8765, 0x0});
    a.setValue(80, aa); EXPECT(a == a80, true);
    BitVector a84(256, {0x8888888888888888, 0x3211234567888888, 0xaabbccdd87654, 0x0});
    a.setValue(84, aa); EXPECT(a == a84, true);
    BitVector a88(256, {0x8888888888888888, 0x2112345678888888, 0xaabbccdd876543, 0x0});
    a.setValue(88, aa); EXPECT(a == a88, true);
    BitVector a92(256, {0x8888888888888888, 0x1123456788888888, 0xaabbccdd8765432, 0x0});
    a.setValue(92, aa); EXPECT(a == a92, true);
    BitVector a96(256, {0x8888888888888888, 0x1234567888888888, 0xaabbccdd87654321, 0x0});
    a.setValue(96, aa); EXPECT(a == a96, true);
    BitVector a100(256, {0x8888888888888888, 0x2345678888888888, 0xabbccdd876543211, 0xa});
    a.setValue(100, aa); EXPECT(a == a100, true);
    BitVector a104(256, {0x8888888888888888, 0x3456788888888888, 0xbbccdd8765432112, 0xaa});
    a.setValue(104, aa); EXPECT(a == a104, true);
    BitVector a108(256, {0x8888888888888888, 0x4567888888888888, 0xbccdd87654321123, 0xaab});
    a.setValue(108, aa); EXPECT(a == a108, true);
    BitVector a112(256, {0x8888888888888888, 0x5678888888888888, 0xccdd876543211234, 0xaabb});
    a.setValue(112, aa); EXPECT(a == a112, true);
    BitVector a116(256, {0x8888888888888888, 0x6788888888888888, 0xcdd8765432112345, 0xaabbc});
    a.setValue(116, aa); EXPECT(a == a116, true);
    BitVector a120(256, {0x8888888888888888, 0x7888888888888888, 0xdd87654321123456, 0xaabbcc});
    a.setValue(120, aa); EXPECT(a == a120, true);
    BitVector a124(256, {0x8888888888888888, 0x8888888888888888, 0xd876543211234567, 0xaabbccd});
    a.setValue(124, aa); EXPECT(a == a124, true);

    return true;
}

bool test_bitvector_bitmanip()
{
    BitVector a(128, {0x8888888811111111, 0x3333333377777777});
    EXPECT(a.getBit(0), true);
    EXPECT(a.getBit(1), false);
    EXPECT(a.getBit(2), false);
    EXPECT(a.getBit(3), false);
    EXPECT(a.getBit(60), false);
    EXPECT(a.getBit(61), false);
    EXPECT(a.getBit(62), false);
    EXPECT(a.getBit(63), true);
    EXPECT(a.getBit(64), true);
    EXPECT(a.getBit(65), true);
    EXPECT(a.getBit(66), true);
    EXPECT(a.getBit(67), false);
    EXPECT(a.getBit(124), true);
    EXPECT(a.getBit(125), true);
    EXPECT(a.getBit(126), false);
    EXPECT(a.getBit(127), false);

    BitVector b(128, {0xffffffff00000000, 0xffffffff00000000});
    b.setBit(1, true);
    b.setBit(2, true);
    b.setBit(62, false);
    b.setBit(63, false);
    b.setBit(64, true);
    b.setBit(127, false);
    EXPECT(b.getValue(0, 64), 0x3fffffff00000006);
    EXPECT(b.getValue(64, 64), 0x7fffffff00000001);

    return true;
}

bool test_bitvector_hex()
{
    BitVector a(1);
    EXPECT(a.hex(), "0");

    BitVector b(1, 1);
    EXPECT(b.hex(), "1");

    BitVector c(129, {0x1, 0x0, 0x1});
    EXPECT(c.hex(), "100000000000000000000000000000001");

    BitVector d(64, 0x123456789abcdef);
    EXPECT(d.hex(), "123456789abcdef");

    return true;
}

bool test_bitvectorarray()
{
    BitVectorArray array(64, 1024);
    for (int i=0; i<1024; i++)
        array.set(i, BitVector(64, i));
    EXPECT(array.get(0), 0);
    EXPECT(array.get(1), 1);
    EXPECT(array.get(2) == BitVector(64, 2), true);
    return true;
}

int main() {
#define RUN(x) do {std::cout << "Running " #x << std::endl; if (!(x)) return 1; } while(0)
    RUN(test_bitvector_construct());
    RUN(test_bitvector_get());
    RUN(test_bitvector_set());
    RUN(test_bitvector_bitmanip());
    RUN(test_bitvector_hex());
    RUN(test_bitvectorarray());
    return 0;
}
