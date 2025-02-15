#ifndef DEF
#define DEF(k, v)
#endif

DEF(CommonPort,             "\\__emu_common_port"           )
DEF(ChannelDependsOn,       "\\__emu_channel_depends_on"    )
DEF(ChannelDirection,       "\\__emu_channel_direction"     )
DEF(ChannelName,            "\\__emu_channel_name"          )
DEF(ChannelPayload,         "\\__emu_channel_payload"       )
DEF(ChannelClock,           "\\__emu_channel_clock"         )
DEF(ChannelReady,           "\\__emu_channel_ready"         )
DEF(ChannelValid,           "\\__emu_channel_valid"         )
DEF(AxiType,                "\\__emu_axi_type"              )
DEF(AxiName,                "\\__emu_axi_name"              )
DEF(AxiSize,                "\\__emu_axi_size"              )
DEF(ModelType,              "\\__emu_model_type"            )
DEF(NoScanchain,            "\\__emu_no_scanchain"          )
DEF(AnonymousFF,            "\\__emu_anonymous_ff"          ) // unused? emu_insert_chain is run before emu_fame_transform
DEF(TracePortName,          "\\__emu_trace_port_name"       )
DEF(TracePortValid,         "\\__emu_trace_port_valid"      )
DEF(TracePortReady,         "\\__emu_trace_port_ready"      )
DEF(TracePortData,          "\\__emu_trace_port_data"       )
DEF(TracePortType,          "\\__emu_trace_port_type"       )

DEF(REMUClock,              "\\remu_clock"                  )
DEF(REMUSignal,             "\\remu_signal"                 )
DEF(REMUSignalInit,         "\\remu_signal_init"            )
DEF(REMUTrig,               "\\remu_trigger"                )
