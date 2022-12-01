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

    bool present() const { return width != 0;}

    void check(std::vector<const char*> &backtrace) const
    {
        __AXI_CHECK(present());
    }
};

struct OptSig : public Sig {
    void check(std::vector<const char*> &) const {}
};

template<unsigned int W>
struct FixSig : public Sig
{
    static_assert(W != 0);
    constexpr unsigned int requiredWidth() const { return W; }

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

#define __AXI_CHECK_SUB(sig) \
    do { \
        backtrace.push_back(#sig ": "); \
        sig.check(backtrace); \
        backtrace.pop_back(); \
    } while (0)

#define __AXI_SET_PREFIX(field) field.name = prefix + #field

struct ChannelBase
{
    FixSig<1> valid;
    FixSig<1> ready;

    void check(std::vector<const char*> &backtrace) const
    {
        __AXI_CHECK_SUB(valid);
        __AXI_CHECK_SUB(ready);
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

struct AChannelLite : public ChannelBase
{
    Sig addr;
    FixSig<3> prot;

    void check(std::vector<const char*> &backtrace) const
    {
        ChannelBase::check(backtrace);
        __AXI_CHECK_SUB(addr);
        __AXI_CHECK_SUB(prot);
        __AXI_CHECK(valid.output == addr.output);
        __AXI_CHECK(valid.output == prot.output);
    }

    void setPrefix(const std::string &prefix)
    {
        ChannelBase::setPrefix(prefix);
        __AXI_SET_PREFIX(addr);
        __AXI_SET_PREFIX(prot);
    }

    void constructRange(SigRange &range)
    {
        ChannelBase::constructRange(range);
        range.append({&addr, &prot});
    }
};

struct WChannelLite : public ChannelBase
{
    DataSig data;
    Sig strb;

    void check(std::vector<const char*> &backtrace) const
    {
        ChannelBase::check(backtrace);
        __AXI_CHECK_SUB(data);
        __AXI_CHECK_SUB(strb);
        __AXI_CHECK(valid.output == data.output);
        __AXI_CHECK(valid.output == strb.output);
        __AXI_CHECK(data.width == strb.width * 8);
    }

    void setPrefix(const std::string &prefix)
    {
        ChannelBase::setPrefix(prefix);
        __AXI_SET_PREFIX(data);
        __AXI_SET_PREFIX(strb);
    }

    void constructRange(SigRange &range)
    {
        ChannelBase::constructRange(range);
        range.append({&data, &strb});
    }
};

struct BChannelLite : public ChannelBase
{
    FixSig<2> resp;

    void check(std::vector<const char*> &backtrace) const
    {
        ChannelBase::check(backtrace);
        __AXI_CHECK_SUB(resp);
        __AXI_CHECK(valid.output == resp.output);
    }

    void setPrefix(const std::string &prefix)
    {
        ChannelBase::setPrefix(prefix);
        __AXI_SET_PREFIX(resp);
    }

    void constructRange(SigRange &range)
    {
        ChannelBase::constructRange(range);
        range.append({&resp});
    }
};

struct RChannelLite : public ChannelBase
{
    DataSig data;
    FixSig<2> resp;

    void check(std::vector<const char*> &backtrace) const
    {
        ChannelBase::check(backtrace);
        __AXI_CHECK_SUB(data);
        __AXI_CHECK_SUB(resp);
        __AXI_CHECK(valid.output == data.output);
        __AXI_CHECK(valid.output == resp.output);
    }

    void setPrefix(const std::string &prefix)
    {
        ChannelBase::setPrefix(prefix);
        __AXI_SET_PREFIX(data);
        __AXI_SET_PREFIX(resp);
    }

    void constructRange(SigRange &range)
    {
        ChannelBase::constructRange(range);
        range.append({&data, &resp});
    }
};

struct AChannel : public AChannelLite
{
    OptSig id;
    FixSig<8> len;
    FixSig<3> size;
    FixSig<2> burst;
    OptFixSig<1> lock;
    OptFixSig<4> cache;
    OptFixSig<4> qos;
    OptFixSig<4> region;
    OptSig user;

    void check(std::vector<const char*> &backtrace) const
    {
        AChannelLite::check(backtrace);
        __AXI_CHECK_SUB(id);
        __AXI_CHECK_SUB(len);
        __AXI_CHECK_SUB(size);
        __AXI_CHECK_SUB(burst);
        __AXI_CHECK_SUB(lock);
        __AXI_CHECK_SUB(cache);
        __AXI_CHECK_SUB(qos);
        __AXI_CHECK_SUB(region);
        __AXI_CHECK_SUB(user);
        __AXI_CHECK(!id.present() || valid.output == id.output);
        __AXI_CHECK(valid.output == len.output);
        __AXI_CHECK(valid.output == size.output);
        __AXI_CHECK(valid.output == burst.output);
        __AXI_CHECK(valid.output == lock.output);
        __AXI_CHECK(valid.output == cache.output);
        __AXI_CHECK(valid.output == qos.output);
        __AXI_CHECK(valid.output == region.output);
        __AXI_CHECK(!user.present() || valid.output == user.output);
    }

    void setPrefix(const std::string &prefix)
    {
        AChannelLite::setPrefix(prefix);
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
        AChannelLite::constructRange(range);
        range.append({&id, &len, &size, &burst, &lock, &cache, &qos, &region, &user});
    }
};

struct WChannel : public WChannelLite
{
    FixSig<1> last;

    void check(std::vector<const char*> &backtrace) const
    {
        WChannelLite::check(backtrace);
        __AXI_CHECK_SUB(last);
        __AXI_CHECK(valid.output == last.output);
    }

    void setPrefix(const std::string &prefix)
    {
        WChannelLite::setPrefix(prefix);
        __AXI_SET_PREFIX(last);
    }

    void constructRange(SigRange &range)
    {
        WChannelLite::constructRange(range);
        range.append({&last});
    }
};

struct BChannel : public BChannelLite
{
    OptSig id;

    void check(std::vector<const char*> &backtrace) const
    {
        BChannelLite::check(backtrace);
        __AXI_CHECK_SUB(id);
        __AXI_CHECK(!id.present() || valid.output == id.output);
    }

    void setPrefix(const std::string &prefix)
    {
        BChannelLite::setPrefix(prefix);
        __AXI_SET_PREFIX(id);
    }

    void constructRange(SigRange &range)
    {
        BChannelLite::constructRange(range);
        range.append({&id});
    }
};

struct RChannel : public RChannelLite
{
    OptSig id;
    FixSig<1> last;

    void check(std::vector<const char*> &backtrace) const
    {
        RChannelLite::check(backtrace);
        __AXI_CHECK_SUB(id);
        __AXI_CHECK_SUB(last);
        __AXI_CHECK(!id.present() || valid.output == id.output);
        __AXI_CHECK(valid.output == last.output);
    }

    void setPrefix(const std::string &prefix)
    {
        RChannelLite::setPrefix(prefix);
        __AXI_SET_PREFIX(id);
        __AXI_SET_PREFIX(last);
    }

    void constructRange(SigRange &range)
    {
        RChannelLite::constructRange(range);
        range.append({&id, &last});
    }
};

template <typename A, typename W, typename B, typename R>
struct BaseAXI4Intf
{
    A aw;
    W w;
    B b;
    A ar;
    R r;

    void check() const
    {
        std::vector<const char*> backtrace;
        __AXI_CHECK_SUB(aw);
        __AXI_CHECK_SUB(w);
        __AXI_CHECK_SUB(b);
        __AXI_CHECK_SUB(ar);
        __AXI_CHECK_SUB(r);
        __AXI_CHECK(aw.addr.width == ar.addr.width);
        __AXI_CHECK(w.data.width == r.data.width);
        __AXI_CHECK(aw.isMaster() == w.isMaster());
        __AXI_CHECK(aw.isMaster() != b.isMaster());
        __AXI_CHECK(aw.isMaster() == ar.isMaster());
        __AXI_CHECK(aw.isMaster() != r.isMaster());
    }

    unsigned int addrWidth() const { return aw.addr.width; }
    unsigned int dataWidth() const { return w.data.width; }
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

using AXI4Lite = BaseAXI4Intf<AChannelLite, WChannelLite, BChannelLite, RChannelLite>;

struct AXI4 : public BaseAXI4Intf<AChannel, WChannel, BChannel, RChannel>
{
    void check() const
    {
        BaseAXI4Intf::check();
        std::vector<const char*> backtrace;
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
    }

    unsigned int idWidth() const { return aw.id.width; }
};

#undef __AXI_CHECK
#undef __AXI_CHECK_SUB
#undef __AXI_SET_PREFIX

};

#endif // #ifndef _AXI_H_
