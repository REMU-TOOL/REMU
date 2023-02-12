#ifndef _REMU_SCHEDULER_H_
#define _REMU_SCHEDULER_H_

#include <cstdint>
#include <memory>
#include <queue>
#include <functional>

namespace REMU {

class Scheduler
{
    struct Event
    {
        uint64_t tick;
        std::function<void()> func;

        bool operator<(const Event &other) const { return tick > other.tick; }
    };

    std::priority_queue<Event> event_queue;

public:

    void clear()
    {
        event_queue = {};
    }

    bool empty() const
    {
        return event_queue.empty();
    }

    uint64_t next_tick() const
    {
        return event_queue.top().tick;
    }

    void step()
    {
        event_queue.top().func();
        event_queue.pop();
    }

    void schedule(uint64_t tick, std::function<void()> func)
    {
        event_queue.push({
            .tick   = tick,
            .func   = func,
        });
    }
};

};

#endif
