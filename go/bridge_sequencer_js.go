// +build js

package ipc

// GopherJS imports
import sync "github.com/gopherjs/gopherjs/nosync"

// sequencer is a small utility class to manage response channels for
// request/response sequences where the response can't be routed by a callback
// (e.g. if there isn't a way to pass callbacks across the JavaScript/host
// barrier)
type sequencer struct {
	// Faux lock, mostly for future-proof code
	sync.Mutex

	// The next request/response sequence to use
	nextSequence int

	// Map from sequence to result channel
	resultChannels map[int]interface{}
}

func newSequencer() *sequencer {
	return &sequencer{
		resultChannels: make(map[int]interface{}),
	}
}

func (s *sequencer) push(channel interface{}) int {
	// Lock the sequencer
	s.Lock()
	defer s.Unlock()

	// Compute sequence
	sequence := s.nextSequence
	if _, ok := s.resultChannels[sequence]; ok {
		panic("sequence overlap")
	}
	s.nextSequence++

	// Store the channel
	s.resultChannels[sequence] = channel

	// All done
	return sequence
}

func (s *sequencer) pop(sequence int) interface{} {
	// Lock the bridge
	s.Lock()
	defer s.Unlock()

	// Get the channel
	channel, ok := s.resultChannels[sequence]
	if !ok {
		panic("invalid sequence")
	}

	// Remove the channel
	delete(s.resultChannels, sequence)

	// All done
	return channel
}
