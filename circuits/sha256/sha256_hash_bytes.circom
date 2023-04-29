pragma circom 2.0.0;

include "sha256_common.circom";
include "sha256_schedule_bits.circom";
include "sha256_rounds_bits.circom";

//------------------------------------------------------------------------------
// Computes the SHA256 hash of a sequence of bytes

template Sha256_hash_bytes(n) {

  signal input  bytes[n];              // `n` bytes 
  signal output out_hash_bytes[32];    // 32 bytes (big-endian, as displayed by common sha256 utilities)
  signal output out_hash_bits[256];    // 256 bits (little-endian, nonstandard order!)

  var len     = 8*n;
  var nchunks = ((len + 1 + 64) + 511) \ 512;
  var nbits   = nchunks * 512;
  var pad_k   = nbits - 64 - 1 - len;

  signal input_bits[nchunks*512];
  signal states[nchunks+1][256];

  component tobits[n];

  for(var j=0; j<n; j++) {
    tobits[j] = ToBits(8);
    tobits[j].inp <== bytes[j];
    for(var i=0; i<8; i++) {
      tobits[j].out[i] ==> input_bits[ j*8 + 7-i ];
    }
  }

  input_bits[8*n] <== 1;
  for(var i=8*n+1; i<nbits-64; i++) { input_bits[i] <== 0; }

  component len_tb = ToBits(64);
  len_tb.inp <== len;
  for(var i=0; i<64; i++) { input_bits[nbits-1-i] <== len_tb.out[i]; }

  var initial_state[8] =  
        [ 0x6a09e667
        , 0xbb67ae85
        , 0x3c6ef372
        , 0xa54ff53a
        , 0x510e527f
        , 0x9b05688c
        , 0x1f83d9ab
        , 0x5be0cd19
        ];

  for(var k=0; k<8; k++) {
    for(var i=0; i<32; i++) {
      states[0][ k*32 + i ] <== (initial_state[k] >> i) & 1;
    }
  }

  component sch[nchunks]; 
  component rds[nchunks]; 

  for(var m=0; m<nchunks; m++) { 

    sch[m] = Sha256_schedule_bits();
    rds[m] = Sha256_rounds_bits(64); 

    for(var k=0; k<16; k++) {
      for(var i=0; i<32; i++) {
        sch[m].chunk_bits[ k*32 + i ] <== input_bits[ m*512 + k*32 + (31-i) ];
      }
    }

    sch[m].out_words ==> rds[m].words;

    rds[m].hash_bits     <== states[m];
    rds[m].out_hash_bits ==> states[m+1];
  }

  out_hash_bits <== states[nchunks];

  for(var k=0; k<32; k++) {
    var sum = 0;
    for(var i=0; i<8; i++) {
      sum += out_hash_bits[ k*8 + i ] * (1<<i);
    }
    out_hash_bytes[ (k\4)*4 + (3-(k%4)) ] <== sum;
  }

}

//------------------------------------------------------------------------------