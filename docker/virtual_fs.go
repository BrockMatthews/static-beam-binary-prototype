package main

import "C"

import (
	"embed"
)

//go:embed virtual-beam
var virtualFS embed.FS

// TODO: we'll probably have to add a function for file enumeration on the virtual filesystem.
// When running we only pass paths to the BEAM, so it will need to
// go to those directories and find the files to run.

//export VirtualReadFile
func VirtualReadFile(filepathC *C.char, readLen *C.long) *C.char {
	// NOTE: filepathC is const char*
	filepath := C.GoString(filepathC)

	data, err := virtualFS.ReadFile(filepath)
	if err != nil {
		return nil
	}

	*readLen = C.long(len(data))
	return C.CString(string(data))
}

func main() {}
