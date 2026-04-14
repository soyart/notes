alias:: Symbol rate

- > Baud rate is related to gross bit rate and is expressed in bps
- [Baud rate or symbol rate](https://en.wikipedia.org/wiki/Symbol_rate) is a number of symbol change, or waveform change per unit of time
	- A symbol is a waveform, a state or a significant condition of the [communication channel](https://en.wikipedia.org/wiki/Communication_channel) that *persists*, for a fixed period of time
	- For example, with a simple serial line (1 bit at a time) sending out char `A`, we'd need to send at 1 bit of data 8 times to complete the character.
	- The rate determines *symbol duration time*, i.e. **for how long each 1 of the 8 bits persists in the serial line**.