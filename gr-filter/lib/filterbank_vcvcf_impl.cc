/* -*- c++ -*- */
/*
 * Copyright 2009,2010,2012,2014 Free Software Foundation, Inc.
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

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "filterbank_vcvcf_impl.h"
#include <gnuradio/io_signature.h>
#include <stdio.h>
#include <iostream>

namespace gr {
  namespace filter {

    filterbank_vcvcf::sptr
    filterbank_vcvcf::make(const std::vector<std::vector<float> > &taps)
    {
      return gnuradio::get_initial_sptr(new filterbank_vcvcf_impl(taps));
    }

    filterbank_vcvcf_impl::filterbank_vcvcf_impl(
      const std::vector< std::vector<float> > &taps)
      : block("filterbank_vcvcf",
              io_signature::make(1, 1, sizeof(gr_complex)*taps.size()),
              io_signature::make(1, 1, sizeof(gr_complex)*taps.size())),
        filterbank(taps)
    {
      set_history(static_cast<size_t>(d_ntaps+1));
    }

    filterbank_vcvcf_impl::~filterbank_vcvcf_impl()
    {
    }

    void
    filterbank_vcvcf_impl::set_taps(const std::vector<std::vector<float> > &taps)
    {
      gr::thread::scoped_lock guard(d_mutex);
      filterbank::set_taps(taps);
      set_history(static_cast<size_t>(d_ntaps+1));
      d_updated = true;
    }

    void
    filterbank_vcvcf_impl::print_taps()
    {
      filterbank::print_taps();
    }

    std::vector<std::vector<float> >
    filterbank_vcvcf_impl::taps() const
    {
      return filterbank::taps();
    }

    ssize_t
    filterbank_vcvcf_impl::general_work(
      size_t noutput_items,
      gr_vector_size_t &ninput_items,
      gr_vector_const_void_star &input_items,
      gr_vector_void_star &output_items)
    {
      gr::thread::scoped_lock guard(d_mutex);

      gr_complex *in = (gr_complex*)input_items[0];
      gr_complex *out = (gr_complex*)output_items[0];

      if(d_updated) {
        d_updated = false;
        return 0;		     // history requirements may have changed.
      }

      gr_complex *working;

      working = new gr_complex [noutput_items + static_cast<size_t>(d_ntaps)];

      for (size_t i = 0; i < static_cast<size_t>(d_nfilts); i++) {
        // Only call the filter method on active filters.
        if (d_active[i]) {
          for (size_t j = 0; j < noutput_items + static_cast<size_t>(d_ntaps-1); j++) {
            size_t p = i + j*static_cast<size_t>(d_nfilts);
            working[j] = in[p];
          }
          for (size_t j = 0; j < noutput_items; j++) {
            size_t p = i + j*static_cast<size_t>(d_nfilts);
            out[p] = d_fir_filters[i]->filter(working + j);
          }
        } else {
          // Otherwise just output 0s.
          for (size_t j = 0; j < noutput_items; j++) {
            size_t p = i + j*static_cast<size_t>(d_nfilts);
            out[p] = 0;
          }
        }
      }

      delete [] working;
      consume_each(noutput_items);
      return static_cast<ssize_t>(noutput_items);
    }

  } /* namespace filter */
} /* namespace gr */
