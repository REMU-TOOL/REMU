#ifndef _REMU_EVENT_QUEUE_H_
#define _REMU_EVENT_QUEUE_H_

#include <vector>
#include <algorithm>

#include "event.h"

namespace REMU {

class EventQueue
{
    std::vector<EventHolder> list;

public:

    const EventHolder& top()
    {
        return list.front();
    }

    void push(EventHolder event)
    {
        list.push_back(event);
        std::push_heap(list.begin(), list.end());
    }

    void pop()
    {
        std::pop_heap(list.begin(), list.end());
        list.pop_back();
    }
};

};

#endif
