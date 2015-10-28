// +build js

package ipc

// This package provides some common error handling helper routines to be shared
// among bridge implementations.  Specifically, it provides a simple mechanism
// for translating JavaScript strings (potentially even base64-encoded ones)
// into error messages.

// System imports
import (
	"errors"
	"encoding/base64"
)

func ErrorFromErrorMessage(errorMessage string) error {
	// If there is no error, we're done
	if errorMessage == "" {
		return nil
	}

	// Otherwise create a new error
	return errors.New(errorMessage)
}

// ErrorFromBase64EncodedErrorMessage decodes a 64-bit encoded string an returns
// a string-based error (using errors.New) with that string as the message.  If
// there is a decoding error, the decoding error is returned.  If the message is
// empty, nil is returned.
func ErrorFromBase64EncodedErrorMessage(errorMessage64 string) error {
	// If there is no error, we're done
	if errorMessage64 == "" {
		return nil
	}

	// Attempt to decode the UTF-8 bytes composing the error
	errorMessageBytes, err := base64.StdEncoding.DecodeString(errorMessage64)

	// If we encounter a decoding error, treat that as our error
	if err != nil {
		return err
	}

	// Otherwise create a new error
	return errors.New(string(errorMessageBytes))
}
