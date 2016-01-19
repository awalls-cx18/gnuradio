/* -*- c++ -*- */
/*
 * Copyright 2013 Free Software Foundation, Inc.
 *
 * This file is part of GNU Radio
 *
 * GNU Radio is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 *
 * GNU Radio is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GNU Radio; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */

/* @WARNING@ */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "@IMPL_NAME@.h"
#include <gnuradio/io_signature.h>
#include <stdexcept>

namespace gr {
  namespace analog {

    @BASE_NAME@::sptr
    @BASE_NAME@::make(noise_type_t type, float ampl, long seed, long samples)
    {
      return gnuradio::get_initial_sptr
	(new @IMPL_NAME@(type, ampl, seed, samples));
    }

    @IMPL_NAME@::@IMPL_NAME@(noise_type_t type, float ampl, long seed, long samples)
    : sync_block("@BASE_NAME@",
		    io_signature::make(0, 0, 0),
		    io_signature::make(1, 1, sizeof(@TYPE@))),
      d_type(type),
#if @IS_COMPLEX@	// complex?
      d_ampl(ampl/sqrtf(2.0f)),
#else
      d_ampl(ampl),
#endif
      d_rng(seed)
    {
      d_samples.resize(samples);
      generate();
    }

    @IMPL_NAME@::~@IMPL_NAME@()
    {
    }

    void
    @IMPL_NAME@::set_type(noise_type_t type)
    {
      gr::thread::scoped_lock l(d_setlock);
      d_type = type;
      generate();
    }

    void
    @IMPL_NAME@::set_amplitude(float ampl)
    {
      gr::thread::scoped_lock l(d_setlock);
#if @IS_COMPLEX@	// complex?
      d_ampl = ampl/sqrtf(2.0f);
#else
      d_ampl = ampl;
#endif
      generate();
    }

    void
    @IMPL_NAME@::generate()
    {
      size_t noutput_items = d_samples.size();
      switch(d_type){
#if @IS_COMPLEX@	// complex?

      case GR_UNIFORM:
	for(size_t i = 0; i < noutput_items; i++)
	  d_samples[i] = gr_complex(d_ampl * ((d_rng.ran1() * 2.0) - 1.0),
				    d_ampl * ((d_rng.ran1() * 2.0) - 1.0));
	break;

      case GR_GAUSSIAN:
	for(size_t i = 0; i < noutput_items; i++)
	  d_samples[i] = d_ampl * d_rng.rayleigh_complex();
	break;

#else			// nope...

      case GR_UNIFORM:
	for(size_t i = 0; i < noutput_items; i++)
	  d_samples[i] = (@TYPE@)(d_ampl * ((d_rng.ran1() * 2.0) - 1.0));
	break;

      case GR_GAUSSIAN:
	for(size_t i = 0; i < noutput_items; i++)
	  d_samples[i] = (@TYPE@)(d_ampl * d_rng.gasdev());
	break;

      case GR_LAPLACIAN:
	for(size_t i = 0; i < noutput_items; i++)
	  d_samples[i] = (@TYPE@)(d_ampl * d_rng.laplacian());
	break;

      case GR_IMPULSE:	// FIXME changeable impulse settings
	for(size_t i = 0; i < noutput_items; i++)
	  d_samples[i] = (@TYPE@)(d_ampl * d_rng.impulse(9));
	break;
#endif

      default:
	throw std::runtime_error("invalid type");
      }
    }

    ssize_t
    @IMPL_NAME@::work(size_t noutput_items,
		      gr_vector_const_void_star &input_items,
		      gr_vector_void_star &output_items)
    {
      gr::thread::scoped_lock l(d_setlock);

      @TYPE@ *out = (@TYPE@*)output_items[0];

      for(size_t i=0; i<noutput_items; i++) {
        out[i] = sample();
      }

      return static_cast<ssize_t>(noutput_items);
    }

    @TYPE@ @IMPL_NAME@::sample()
    {
#ifdef __USE_GNU
        size_t idx = lrand48() % d_samples.size();
#else
        size_t idx = rand() % d_samples.size();
#endif
        return d_samples[idx];
    }

#ifndef FASTNOISE_RANDOM_SIGN
#ifdef _MSC_VER
#define FASTNOISE_RANDOM_SIGN       ((rand()%2==0)?1:-1)
#else
#define FASTNOISE_RANDOM_SIGN       ((lrand48()%2==0)?1:-1)
#endif
#endif

    @TYPE@ @IMPL_NAME@::sample_unbiased()
    {
#if @IS_COMPLEX@
        gr_complex s(sample());
        return gr_complex(FASTNOISE_RANDOM_SIGN * s.real(),
                          FASTNOISE_RANDOM_SIGN * s.imag());
#else
        return FASTNOISE_RANDOM_SIGN * sample();
#endif
    }

  } /* namespace analog */
} /* namespace gr */
