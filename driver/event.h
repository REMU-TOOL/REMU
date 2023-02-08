#ifndef _REMU_EVENT_H_
#define _REMU_EVENT_H_

#include <cstdint>

#include "bitvector.h"

namespace REMU {

class Driver;

class Event
{
    uint64_t m_tick;

public:

    uint64_t tick() const { return m_tick; }
    bool operator<(const Event &other) const { return m_tick > other.m_tick; }

    // return false to stop execution
    virtual bool execute(Driver &drv) const = 0;

    Event(uint64_t tick) : m_tick(tick) {}
    virtual ~Event() {}
};

class SignalEvent : public Event
{
    int index;
    BitVector value;

public:

    virtual bool execute(Driver &drv) const override;

    SignalEvent(uint64_t tick, int index, const BitVector &value) :
        Event(tick), index(index), value(value) {}
};

class StopEvent : public Event
{
public:

    virtual bool execute(Driver &drv) const override { return false; }

    StopEvent(uint64_t tick) : Event(tick) {}
};

class EventHolder
{
    Event *event;

public:

    Event* get() const { return event; }
    Event& operator*() const { return *event; }
    Event* operator->() const { return event; }
    bool operator<(const EventHolder &other) const { return *event < *other.event; }

    EventHolder(Event *event) : event(event) {}
};

};

#endif
