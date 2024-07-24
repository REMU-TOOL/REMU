TRACE_ELF := build/tracebackend/tests/BatchTest
$(TRACE_ELF):
	make -C build -j 128
gdb: $(TRACE_ELF)
	make -C build -j 128
	gdb --args $^ +dumpfile=wave.fst +duration=1024

run: $(TRACE_ELF)
	make -C build -j 128
	$^ +dumpfile=wave.fst +duration=1024
	