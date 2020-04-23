/*
 * Copyright 2020 Free Software Foundation, Inc.
 *
 * This file is part of GNU Radio
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 */

/* This file is automatically generated using bindtool */

#include <pybind11/complex.h>
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>

namespace py = pybind11;

#include <gnuradio/dtv/atsc_deinterleaver.h>
// pydoc.h is automatically generated in the build directory
#include <atsc_deinterleaver_pydoc.h>

void bind_atsc_deinterleaver(py::module& m)
{

    using atsc_deinterleaver = ::gr::dtv::atsc_deinterleaver;


    py::class_<atsc_deinterleaver,
               gr::sync_block,
               gr::block,
               gr::basic_block,
               std::shared_ptr<atsc_deinterleaver>>(
        m, "atsc_deinterleaver", D(atsc_deinterleaver))

        .def(py::init(&atsc_deinterleaver::make), D(atsc_deinterleaver, make))


        ;
}
