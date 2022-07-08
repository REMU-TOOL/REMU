#ifndef _TRANSFORM_H_
#define _TRANSFORM_H_

#include "kernel/yosys.h"
#include "designtools.h"
#include "rewriter.h"

namespace Emu {

USING_YOSYS_NAMESPACE

struct Transform {
    virtual void execute(EmulationRewriter &rewriter) = 0;
    Transform() {}
    virtual ~Transform() {}
};

class TransformFlow {

    EmulationRewriter &rewriter;
    std::vector<Transform *> list;

public:

    void add(Transform *transform) {
        list.push_back(transform);
    }

    void run() {
        for (auto &transform : list) {
            transform->execute(rewriter);
            rewriter.update_design();
        }
    }

    TransformFlow(EmulationRewriter &rewriter) : rewriter(rewriter) {}

    ~TransformFlow() {
        for (auto &transform : list)
            delete transform;
    }

};

struct IdentifySyncReadMem : public Transform {
    virtual void execute(EmulationRewriter &rewriter) override;
};

struct PortTransform : public Transform {
    virtual void execute(EmulationRewriter &rewriter) override;
};

struct TargetTransform : public Transform {
    virtual void execute(EmulationRewriter &rewriter) override;
};

struct ClockTransform : public Transform {
    virtual void execute(EmulationRewriter &rewriter) override;
};

struct InsertScanchain : public Transform {
    virtual void execute(EmulationRewriter &rewriter) override;
};

struct PlatformTransform : public Transform {
    bool raw;
    virtual void execute(EmulationRewriter &rewriter) override;
    PlatformTransform(bool raw) : raw(raw) {}
};

struct DesignIntegration : public Transform {
    virtual void execute(EmulationRewriter &rewriter) override;
};

struct InterfaceTransform : public Transform {
    virtual void execute(EmulationRewriter &rewriter) override;
};

} // namespace Emu

#endif // #ifndef _TRANSFORM_H_
