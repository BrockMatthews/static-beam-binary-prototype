package main

import "C"

import (
	"embed"
	"io/fs"
	"unsafe"
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

//export VirtualListDir
func VirtualListDir(dirpathC *C.char) **C.char {
	dirpath := C.GoString(dirpathC)

	entries, err := virtualFS.ReadDir(dirpath)
	if err != nil {
		return nil
	}

	cArray := C.malloc(C.size_t(len(entries)) * (C.size_t(unsafe.Sizeof(uintptr(0))) + 1))
	for i, entry := range entries {
		cStr := C.CString(entry.Name())
		ptr := (**C.char)(unsafe.Pointer(uintptr(cArray) + uintptr(i)*unsafe.Sizeof(uintptr(0))))
		*ptr = cStr
	}

	// Null-terminate the array
	lastPtr := (**C.char)(unsafe.Pointer(uintptr(cArray) + uintptr(len(entries))*unsafe.Sizeof(uintptr(0))))
	*lastPtr = nil

	return (**C.char)(cArray)
}

//export VirtualReadInfo
func VirtualReadInfo(
	pathC *C.char,
	// Outputs
	size *C.long,
	mode *C.uint,
	modTime *C.long,
	isDir *C.int,
) C.int {
	path := C.GoString(pathC)

	info, err := fs.Stat(virtualFS, path)
	if err != nil {
		return -1
	}

	*size = C.long(info.Size())
	*mode = C.uint(info.Mode())
	*modTime = C.long(info.ModTime().Unix())
	if info.IsDir() {
		*isDir = 1
	} else {
		*isDir = 0
	}

	return 0
}

func main() {}
