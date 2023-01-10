#ifndef _AXI_H_
#define _AXI_H_

#include <string>
#include <vector>

namespace AXI {

void __check_error(std::vector<const char*> &backtrace, const char *msg);

#define __AXI_CHECK(x) \
    do { if (!(x)) __check_error(backtrace, "check " #x " failed"); } while (0)

struct Sig
{
    std::string name;
    unsigned int width = 0;
    bool output = false;

    Sig() = default;
    Sig(const std::string &name, unsigned int width, bool output) :
        name(name), width(width), output(output) {}

    bool present() const { return width != 0;}
    bool isConsistentDirection(const Sig &other) const
    {
        return !present() || !other.present() || output == other.output;
    }

    void check(std::vector<const char*> &backtrace) const
    {
        __AXI_CHECK(present() && !name.empty());
    }
};

struct OptSig : public Sig
{
    OptSig() = default;
    OptSig(const std::string &name, unsigned int width, bool output, bool present = true) :
        Sig(name, width, output) { if (!present) width = 0; }

    void check(std::vector<const char*> &backtrace) const
    {
        __AXI_CHECK(!present() || !name.empty());
    }
};

template<unsigned int W>
struct FixSig : public Sig
{
    static_assert(W != 0);
    constexpr unsigned int requiredWidth() const { return W; }

    FixSig() = default;
    FixSig(const std::string &name, bool output) :
        Sig(name, W, output) {}

    void check(std::vector<const char*> &backtrace) const
    {
        if (width != W) {
            std::string s = "width is required to be ";
            s += std::to_string(W);
            __check_error(backtrace, s.c_str());
        }
    }
};

template<unsigned int W>
struct OptFixSig : public Sig
{
    static_assert(W != 0);
    constexpr unsigned int requiredWidth() const { return W; }

    OptFixSig() = default;
    OptFixSig(const std::string &name, bool output, bool present = true) :
        Sig(name, W, output) { if (!present) width = 0; }

    void check(std::vector<const char*> &backtrace) const
    {
        if (present() && width != W) {
            std::string s = "width is required to be ";
            s += std::to_string(W);
            __check_error(backtrace, s.c_str());
        }
    }
};

struct DataSig : public Sig
{
    using Sig::Sig;

    void check(std::vector<const char*> &backtrace) const
    {
        Sig::check(backtrace);

        switch (width) {
            case 8:     case 16:    case 32:    case 64:
            case 128:   case 256:   case 512:   case 1024:
                break;
            default:
                __check_error(backtrace, "width is required to be 8, 16, 32, 64, 128, 256, 512 or 1024");
                break;
        }
    }
};

struct SigIterator
{
    using iterator_category = std::forward_iterator_tag;
    using value_type = Sig;
    using difference_type = std::ptrdiff_t;
    using pointer = Sig*;
    using reference = Sig&;
    typename std::vector<Sig*>::iterator vec_it;

    SigIterator() {}
    SigIterator(decltype(vec_it) vec_it) : vec_it(vec_it) {}

    reference operator*() const { return **vec_it; }
    pointer operator->() { return *vec_it; }

    SigIterator& operator++() { ++vec_it; return *this; }
    SigIterator operator++(int) { SigIterator tmp(*this); ++(*this); return tmp; }

    bool operator==(const SigIterator &other) const { return vec_it == other.vec_it; }
    bool operator!=(const SigIterator &other) const { return !(*this == other); }
};

struct SigRange
{
    std::vector<Sig*> m_vec;

    SigRange() {}
    SigRange(const std::vector<Sig*> &vec) : m_vec(vec) {}
    SigRange(std::vector<Sig*> &&vec) : m_vec(std::move(vec)) {}

    void append(std::initializer_list<Sig*> ilist)
    {
        m_vec.insert(m_vec.end(), ilist);
    }

    void append(const std::vector<Sig*> &vec)
    {
        m_vec.insert(m_vec.end(), vec.begin(), vec.end());
    }

    SigIterator begin() { return m_vec.begin(); }
    SigIterator end() { return m_vec.end(); }
};

#define __AXI_NESTED_CHECK(obj_func) \
    do { \
        backtrace.push_back(#obj_func ": "); \
        obj_func(backtrace); \
        backtrace.pop_back(); \
    } while (0)

#define __AXI_SET_PREFIX(field) field.name = prefix + #field

struct Info
{
    unsigned int addr_width;
    unsigned int data_width;
    unsigned int id_width;
    unsigned int user_width;
    bool is_master;
    bool is_full;
    bool has_lock;
    bool has_cache;
    bool has_qos;
    bool has_region;

    Info() = default;

    Info(
        unsigned int addr_width,
        unsigned int data_width,
        bool is_master,
        bool is_full,
        unsigned int id_width = 0,
        unsigned int user_width = 0,
        bool has_lock = true,
        bool has_cache = true,
        bool has_qos = true,
        bool has_region = true
    ) :
        addr_width(addr_width),
        data_width(data_width),
        id_width(id_width),
        user_width(user_width),
        is_master(is_master),
        is_full(is_full),
        has_lock(is_full && has_lock),
        has_cache(is_full && has_cache),
        has_qos(is_full && has_qos),
        has_region(is_full && has_region)
    {}
};

struct ChannelBase
{
    FixSig<1> valid;
    FixSig<1> ready;

    ChannelBase() = default;
    ChannelBase(const std::string &prefix, bool output) :
        valid(prefix + "valid", output),
        ready(prefix + "ready", !output) {}

    void check(std::vector<const char*> &backtrace) const
    {
        __AXI_NESTED_CHECK(valid.check);
        __AXI_NESTED_CHECK(ready.check);
        __AXI_CHECK(valid.output != ready.output);
    }

    bool isMaster() const { return valid.output; }

    void setPrefix(const std::string &prefix)
    {
        __AXI_SET_PREFIX(valid);
        __AXI_SET_PREFIX(ready);
    }

    void constructRange(SigRange &range)
    {
        range.append({&valid, &ready});
    }
};

struct AChannel : public ChannelBase
{
    Sig addr;
    FixSig<3> prot;
    OptSig id;
    OptFixSig<8> len;
    OptFixSig<3> size;
    OptFixSig<2> burst;
    OptFixSig<1> lock;
    OptFixSig<4> cache;
    OptFixSig<4> qos;
    OptFixSig<4> region;
    OptSig user;

    AChannel() = default;

    AChannel(const std::string &prefix, const Info &info) :
        ChannelBase(prefix, info.is_master),
        addr  (prefix + "addr",   info.addr_width, info.is_master),
        prot  (prefix + "prot",   info.is_master),
        id    (prefix + "id",     info.id_width, info.is_master, info.is_full),
        len   (prefix + "len",    info.is_master, info.is_full),
        size  (prefix + "size",   info.is_master, info.is_full),
        burst (prefix + "burst",  info.is_master, info.is_full),
        lock  (prefix + "lock",   info.is_master, info.has_lock),
        cache (prefix + "cache",  info.is_master, info.has_cache),
        qos   (prefix + "qos",    info.is_master, info.has_qos),
        region(prefix + "region", info.is_master, info.has_region) {}

    void check(std::vector<const char*> &backtrace) const
    {
        ChannelBase::check(backtrace);
        __AXI_NESTED_CHECK(addr.check);
        __AXI_NESTED_CHECK(prot.check);
        __AXI_NESTED_CHECK(id.check);
        __AXI_NESTED_CHECK(len.check);
        __AXI_NESTED_CHECK(size.check);
        __AXI_NESTED_CHECK(burst.check);
        __AXI_NESTED_CHECK(lock.check);
        __AXI_NESTED_CHECK(cache.check);
        __AXI_NESTED_CHECK(qos.check);
        __AXI_NESTED_CHECK(region.check);
        __AXI_NESTED_CHECK(user.check);
        __AXI_CHECK(addr.isConsistentDirection(valid));
        __AXI_CHECK(prot.isConsistentDirection(valid));
        __AXI_CHECK(id.isConsistentDirection(valid));
        __AXI_CHECK(len.isConsistentDirection(valid));
        __AXI_CHECK(size.isConsistentDirection(valid));
        __AXI_CHECK(burst.isConsistentDirection(valid));
        __AXI_CHECK(lock.isConsistentDirection(valid));
        __AXI_CHECK(cache.isConsistentDirection(valid));
        __AXI_CHECK(qos.isConsistentDirection(valid));
        __AXI_CHECK(region.isConsistentDirection(valid));
        __AXI_CHECK(user.isConsistentDirection(valid));
    }

    void checkFull(std::vector<const char*> &backtrace) const
    {
        __AXI_CHECK(len.present());
        __AXI_CHECK(size.present());
        __AXI_CHECK(burst.present());
    }

    void checkLite(std::vector<const char*> &backtrace) const
    {
        __AXI_CHECK(!len.present());
        __AXI_CHECK(!size.present());
        __AXI_CHECK(!burst.present());
    }

    void setPrefix(const std::string &prefix)
    {
        ChannelBase::setPrefix(prefix);
        __AXI_SET_PREFIX(addr);
        __AXI_SET_PREFIX(prot);
        __AXI_SET_PREFIX(id);
        __AXI_SET_PREFIX(len);
        __AXI_SET_PREFIX(size);
        __AXI_SET_PREFIX(burst);
        __AXI_SET_PREFIX(lock);
        __AXI_SET_PREFIX(cache);
        __AXI_SET_PREFIX(qos);
        __AXI_SET_PREFIX(region);
        __AXI_SET_PREFIX(user);
    }

    void constructRange(SigRange &range)
    {
        ChannelBase::constructRange(range);
        range.append({&addr, &prot, &id, &len, &size, &burst, &lock, &cache, &qos, &region, &user});
    }
};

struct WChannel : public ChannelBase
{
    DataSig data;
    Sig strb;
    OptFixSig<1> last;

    WChannel() = default;

    WChannel(const std::string &prefix, const Info &info) :
        ChannelBase(prefix, info.is_master),
        data(prefix + "data", info.data_width, info.is_master),
        strb(prefix + "strb", info.data_width / 8, info.is_master),
        last(prefix + "last", info.is_master, info.is_full) {}

    void check(std::vector<const char*> &backtrace) const
    {
        ChannelBase::check(backtrace);
        __AXI_NESTED_CHECK(data.check);
        __AXI_NESTED_CHECK(strb.check);
        __AXI_NESTED_CHECK(last.check);
        __AXI_CHECK(data.isConsistentDirection(valid));
        __AXI_CHECK(strb.isConsistentDirection(valid));
        __AXI_CHECK(last.isConsistentDirection(valid));
        __AXI_CHECK(data.width == strb.width * 8);
    }

    void checkFull(std::vector<const char*> &backtrace) const
    {
        __AXI_CHECK(last.present());
    }

    void checkLite(std::vector<const char*> &backtrace) const
    {
        __AXI_CHECK(!last.present());
    }

    void setPrefix(const std::string &prefix)
    {
        ChannelBase::setPrefix(prefix);
        __AXI_SET_PREFIX(data);
        __AXI_SET_PREFIX(strb);
        __AXI_SET_PREFIX(last);
    }

    void constructRange(SigRange &range)
    {
        ChannelBase::constructRange(range);
        range.append({&data, &strb, &last});
    }
};

struct BChannel : public ChannelBase
{
    FixSig<2> resp;
    OptSig id;

    BChannel() = default;

    BChannel(const std::string &prefix, const Info &info) :
        ChannelBase(prefix, !info.is_master),
        resp(prefix + "resp", !info.is_master),
        id  (prefix + "id", info.id_width, !info.is_master) {}

    void check(std::vector<const char*> &backtrace) const
    {
        ChannelBase::check(backtrace);
        __AXI_NESTED_CHECK(resp.check);
        __AXI_NESTED_CHECK(id.check);
        __AXI_CHECK(resp.isConsistentDirection(valid));
        __AXI_CHECK(id.isConsistentDirection(valid));
    }

    void checkFull(std::vector<const char*> &) const {}

    void checkLite(std::vector<const char*> &backtrace) const
    {
        __AXI_CHECK(!id.present());
    }

    void setPrefix(const std::string &prefix)
    {
        ChannelBase::setPrefix(prefix);
        __AXI_SET_PREFIX(resp);
        __AXI_SET_PREFIX(id);
    }

    void constructRange(SigRange &range)
    {
        ChannelBase::constructRange(range);
        range.append({&resp, &id});
    }
};

struct RChannel : public ChannelBase
{
    DataSig data;
    FixSig<2> resp;
    OptSig id;
    OptFixSig<1> last;

    RChannel() = default;

    RChannel(const std::string &prefix, const Info &info) :
        ChannelBase(prefix, !info.is_master),
        data(prefix + "data", info.data_width, !info.is_master),
        resp(prefix + "resp", !info.is_master),
        id  (prefix + "id", info.id_width, !info.is_master),
        last(prefix + "last", !info.is_master, info.is_full) {}

    void check(std::vector<const char*> &backtrace) const
    {
        ChannelBase::check(backtrace);
        __AXI_NESTED_CHECK(data.check);
        __AXI_NESTED_CHECK(resp.check);
        __AXI_NESTED_CHECK(id.check);
        __AXI_NESTED_CHECK(last.check);
        __AXI_CHECK(data.isConsistentDirection(valid));
        __AXI_CHECK(resp.isConsistentDirection(valid));
        __AXI_CHECK(id.isConsistentDirection(valid));
        __AXI_CHECK(last.isConsistentDirection(valid));
    }

    void checkFull(std::vector<const char*> &backtrace) const
    {
        __AXI_CHECK(last.present());
    }

    void checkLite(std::vector<const char*> &backtrace) const
    {
        __AXI_CHECK(!id.present());
        __AXI_CHECK(!last.present());
    }

    void setPrefix(const std::string &prefix)
    {
        ChannelBase::setPrefix(prefix);
        __AXI_SET_PREFIX(data);
        __AXI_SET_PREFIX(resp);
        __AXI_SET_PREFIX(id);
        __AXI_SET_PREFIX(last);
    }

    void constructRange(SigRange &range)
    {
        ChannelBase::constructRange(range);
        range.append({&data, &resp});
        range.append({&id, &last});
    }
};


struct AXI4
{
    AChannel aw;
    WChannel w;
    BChannel b;
    AChannel ar;
    RChannel r;

    AXI4() = default;

    AXI4(const std::string &prefix, const Info &info) :
        aw(prefix + "_aw", info),
        w (prefix + "_w",  info),
        b (prefix + "_b",  info),
        ar(prefix + "_ar", info),
        r (prefix + "_r",  info) {}

    bool isFull() const { return aw.len.present(); }

    void check() const
    {
        std::vector<const char*> backtrace;
        __AXI_NESTED_CHECK(aw.check);
        __AXI_NESTED_CHECK(w.check);
        __AXI_NESTED_CHECK(b.check);
        __AXI_NESTED_CHECK(ar.check);
        __AXI_NESTED_CHECK(r.check);
        __AXI_CHECK(aw.addr.width == ar.addr.width);
        __AXI_CHECK(w.data.width == r.data.width);
        __AXI_CHECK(aw.addr.width == ar.addr.width);
        __AXI_CHECK(w.data.width == r.data.width);
        __AXI_CHECK(aw.addr.width == ar.addr.width);
        __AXI_CHECK(aw.lock.width == ar.lock.width);
        __AXI_CHECK(aw.cache.width == ar.cache.width);
        __AXI_CHECK(aw.qos.width == ar.qos.width);
        __AXI_CHECK(aw.region.width == ar.region.width);
        __AXI_CHECK(w.data.width == r.data.width);
        __AXI_CHECK(aw.id.width == ar.id.width);
        __AXI_CHECK(aw.id.width == b.id.width);
        __AXI_CHECK(aw.id.width == r.id.width);
        __AXI_CHECK(aw.isMaster() == w.isMaster());
        __AXI_CHECK(aw.isMaster() != b.isMaster());
        __AXI_CHECK(aw.isMaster() == ar.isMaster());
        __AXI_CHECK(aw.isMaster() != r.isMaster());
        if (isFull()) {
            __AXI_NESTED_CHECK(aw.checkFull);
            __AXI_NESTED_CHECK(w.checkFull);
            __AXI_NESTED_CHECK(b.checkFull);
            __AXI_NESTED_CHECK(ar.checkFull);
            __AXI_NESTED_CHECK(r.checkFull);
        }
        else  {
            __AXI_NESTED_CHECK(aw.checkLite);
            __AXI_NESTED_CHECK(w.checkLite);
            __AXI_NESTED_CHECK(b.checkLite);
            __AXI_NESTED_CHECK(ar.checkLite);
            __AXI_NESTED_CHECK(r.checkLite);
        }
    }

    unsigned int addrWidth() const { return aw.addr.width; }
    unsigned int dataWidth() const { return w.data.width; }
    unsigned int idWidth() const { return aw.id.width; }
    bool isMaster() const { return aw.isMaster(); }

    void setPrefix(const std::string &prefix)
    {
        aw.setPrefix(prefix + "_aw");
        w.setPrefix(prefix + "_w");
        b.setPrefix(prefix + "_b");
        ar.setPrefix(prefix + "_ar");
        r.setPrefix(prefix + "_r");
    }

    SigRange signals()
    {
        SigRange range;
        aw.constructRange(range);
        w.constructRange(range);
        b.constructRange(range);
        ar.constructRange(range);
        r.constructRange(range);
        return range;
    }
};

#undef __AXI_CHECK
#undef __AXI_NESTED_CHECK
#undef __AXI_SET_PREFIX

};

#endif // #ifndef _AXI_H_
