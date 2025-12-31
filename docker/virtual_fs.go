package main

import "C"

import (
	"embed"
)

//go:embed virtual-beam-extract
var virtualFS embed.FS

// TODO: we'll probably have to add a function for file enumeration on the virtual filesystem.
// When running we only pass paths to the BEAM, so it will need to
// go to those directories and find the files to run.

//export VirtualReadFile
func VirtualReadFile(filepathC *C.char, readLen *C.long) *C.char {
	// NOTE: filepathC is const char*
    filepath := C.GoString(filepathC)

	// TEMP: fixing -extract
	f := "virtual-beam-extract/" + filepath[len("virtual-beam/"):]

	data, err := virtualFS.ReadFile(f)

	if err != nil {
		return nil
	}

	*readLen = C.long(len(data))
	return C.CString(string(data))
}

func main() {}
