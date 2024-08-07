#ifndef __AXI_HH__
#define __AXI_HH__

#include "TraceBackend/AXI4Module.hpp"
#include "bitvector.h"
#include "verilated.h"
#include <fmt/core.h>
#include <optional>

template <size_t ID_WIDTH, typename DATA_REF_T, typename ADDR_REF_T>
class AXI4SlaveRef {
  VL_OUT8(&awid, 3, 0);
  VL_OUT8(&awlen, 7, 0);
  VL_OUT8(&awsize, 2, 0);
  VL_OUT8(&awburst, 1, 0);
  VL_OUT8(&awlock, 0, 0);
  VL_OUT8(&awcache, 3, 0);
  VL_OUT8(&awprot, 2, 0);
  VL_OUT8(&awqos, 3, 0);
  VL_OUT8(&awregion, 3, 0);
  VL_OUT8(&awuser, 0, -1);
  VL_OUT8(&awvalid, 0, 0);
  VL_IN8(&awready, 0, 0);
  ADDR_REF_T awaddr;

  VL_OUT8(&wstrb, 7, 0);
  VL_OUT8(&wlast, 0, 0);
  VL_OUT8(&wuser, 0, -1);
  VL_OUT8(&wvalid, 0, 0);
  VL_IN8(&wready, 0, 0);
  DATA_REF_T wdata;

  VL_IN8(&bid, 3, 0);
  VL_IN8(&bresp, 1, 0);
  VL_IN8(&buser, 0, -1);
  VL_IN8(&bvalid, 0, 0);
  VL_OUT8(&bready, 0, 0);

  AXI4::SlaveWriteModule &deleg;

  template <typename T> static uint8_t *get_ref_addr(T &x) {
    return (uint8_t *)&x;
  }

  template <std::size_t T_Words>
  static uint8_t *get_ref_addr(VlWide<T_Words> &x) {
    return (uint8_t *)x.data();
  }

  template <typename S, typename D> static void set_ref_addr(S &src, D dest) {
    src = dest;
  }

  template <std::size_t T_Words, typename D>
  static void set_ref_addr(VlWide<T_Words> &src, D dest) {
    return memcpy(src.data(), &dest, sizeof(dest));
  }

  template <typename S>
  static void set_ref_addr(S &src, const REMU::BitVector &dest) {
    assert(sizeof(std::remove_reference<decltype(src)>) == dest.width() / 8);
    dest.getValue(&src, sizeof(src));
  }

  template <std::size_t T_Words>
  static void set_ref_addr(VlWide<T_Words> &src, REMU::BitVector dest) {
    // TODO: assert
    dest.getValue(src.data(), dest.width());
  }

public:
  // check fire in every cycle, if fire call callback function
  void check_inputs() {
    if (awvalid && awready) {
      deleg.aw_fire_cb(awaddr, awid, awburst, awlen, awsize);
    }
    if (wvalid && wready) {
      deleg.w_fire_cb(wstrb, wlast, wdata);
    }
    if (bvalid && bready) {
      deleg.b_fire_cb();
    }
    deleg.tick_cb();
  }

  // call every cycle, check if slave module want update
  void update_outputs() {
    if (deleg.next_state.b.has_value()) {
      bvalid = deleg.next_state.b->valid;
      set_ref_addr(bid, deleg.next_state.b->id);
      set_ref_addr(bresp, deleg.next_state.b->resp);
      set_ref_addr(buser, deleg.next_state.b->user);
      deleg.next_state.b.reset();
    }
    if (deleg.next_state.awready.has_value()) {
      awready = deleg.next_state.awready.value();
      deleg.next_state.awready.reset();
    }
    if (deleg.next_state.wready.has_value()) {
      awready = deleg.next_state.wready.value();
      deleg.next_state.wready.reset();
    }
  }

  AXI4SlaveRef(CData &awid, CData &awlen, CData &awsize, CData &awburst,
               CData &awlock, CData &awcache, CData &awprot, CData &awqos,
               CData &awregion, CData &awuser, CData &awvalid, CData &awready,
               ADDR_REF_T awaddr,

               CData &wstrb, CData &wlast, CData &wuser, CData &wvalid,
               CData &wready, DATA_REF_T wdata,

               CData &bid, CData &bresp, CData &buser, CData &bvalid,
               CData &bready,

               AXI4::SlaveWriteModule &deleg)
      : awid(awid), awlen(awlen), awsize(awsize), awburst(awburst),
        awlock(awlock), awcache(awcache), awprot(awprot), awqos(awqos),
        awregion(awregion), awuser(awuser), awvalid(awvalid), awready(awready),
        awaddr(awaddr), wstrb(wstrb), wlast(wlast), wuser(wuser),
        wvalid(wvalid), wready(wready), wdata(wdata), bid(bid), bresp(bresp),
        buser(buser), bvalid(bvalid), bready(bready), deleg(deleg) {}
};

#endif // !__AXI_HPP__