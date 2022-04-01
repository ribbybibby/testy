package main

import (
	"fmt"

	"github.com/google/go-containerregistry/pkg/name"
)

func main() {
	ref, err := name.ParseReference("alpine:latest")
	if err != nil {
		panic(err)
	}
	fmt.Println(ref.Name())
}
