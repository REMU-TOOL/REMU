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
    virtual void execute(EmulationRewriter &rewriter) override;
};

} // namespace Emu

#endif // #ifndef _TRANSFORM_H_
