#ifndef _DRIVER_EVENT_H_
#define _DRIVER_EVENT_H_

#include <cstdint>

#include "hal.h"

namespace REMU {

class Event
{
    uint64_t m_tick;

public:

    uint64_t tick() const { return m_tick; }

    bool operator<(const Event &other) const
    {
        return m_tick > other.m_tick;
    }

    virtual void execute(HAL &hal) const = 0;

    Event(uint64_t tick) : m_tick(tick) {}
    virtual ~Event() {}
};

class EventHandle
{
    Event *event;

public:

    Event& operator*() const { return *event; }
    Event* operator->() const { return event; }
    bool operator<(EventHandle other) { return *event < *other.event; }

    EventHandle(Event *event) : event(event) {}
};

class SignalEvent : public Event
{
    bool value;

public:

    virtual void execute(HAL &hal) const override
    {

    }

    SignalEvent(uint64_t tick, bool value) : Event(tick), value(value) {}
};

};

#endif
