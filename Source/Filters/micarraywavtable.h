/*++

Copyright (c) Microsoft Corporation All Rights Reserved

Module Name:

    micarraywavtable.h

Abstract:

    Declaration of wave miniport tables for the capture endpoints.
--*/

#ifndef _VIRTUALAUDIODRIVER_MICARRAYWAVTABLE_H_
#define _VIRTUALAUDIODRIVER_MICARRAYWAVTABLE_H_

//=============================================================================
// ISL Virtual Mic - FIXED FORMAT for guaranteed compatibility
// CRITICAL: Both speaker and mic MUST use the same format to prevent
// robotic voice distortion from sample rate mismatch.
// Format: 48000 Hz, 16-bit, Stereo (matches desktop app AudioContext)
//=============================================================================
#define MICARRAY_RAW_CHANNELS               2
#define MICARRAY_DEVICE_MAX_CHANNELS        2
#define MICARRAY_MIN_BITS_PER_SAMPLE        16
#define MICARRAY_MAX_BITS_PER_SAMPLE        16
#define MICARRAY_MIN_SAMPLE_RATE            48000
#define MICARRAY_MAX_SAMPLE_RATE            48000

#define MICARRAY_MAX_INPUT_STREAMS          8

//=============================================================================
// Supported device formats - SINGLE FORMAT ONLY to prevent mismatch
// 48000 Hz, 16-bit, Stereo - MUST match speaker format exactly
//=============================================================================
static
KSDATAFORMAT_WAVEFORMATEXTENSIBLE MicArrayPinSupportedDeviceFormats[] =
{
    // 16-bit, Stereo, 48 kHz - THE ONLY SUPPORTED FORMAT
    {
        {
            sizeof(KSDATAFORMAT_WAVEFORMATEXTENSIBLE),
            0,
            0,
            0,
            STATICGUIDOF(KSDATAFORMAT_TYPE_AUDIO),
            STATICGUIDOF(KSDATAFORMAT_SUBTYPE_PCM),
            STATICGUIDOF(KSDATAFORMAT_SPECIFIER_WAVEFORMATEX)
        },
        {
            {
                WAVE_FORMAT_EXTENSIBLE,
                2,                              // nChannels (STEREO)
                48000,                          // nSamplesPerSec
                48000 * 2 * 16 / 8,             // nAvgBytesPerSec = 192000
                2 * 16 / 8,                     // nBlockAlign = 4
                16,                             // wBitsPerSample
                sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX)
            },
            16,                                 // wValidBitsPerSample
            KSAUDIO_SPEAKER_STEREO,
            STATICGUIDOF(KSDATAFORMAT_SUBTYPE_PCM)
        }
    },
};

#define MICARRAY_PIN_SUPPORTED_DEVICE_FORMATS_COUNT (SIZEOF_ARRAY(MicArrayPinSupportedDeviceFormats))

//=============================================================================
// Pin device formats and modes - simplified
// Index 0 = Bridge pin (KSPIN_WAVE_BRIDGE)
// Index 1 = Host pin (KSPIN_WAVEIN_HOST) - this is the capture pin
//
static
PIN_DEVICE_FORMATS_AND_MODES MicArrayPinDeviceFormatsAndModes[] =
{
    // Pin 0: Bridge pin - no formats needed
    {
        BridgePin,
        NULL,
        0,
        NULL,
        0
    },
    // Pin 1: System capture pin - this is where capture happens
    {
        SystemCapturePin,
        MicArrayPinSupportedDeviceFormats,
        MICARRAY_PIN_SUPPORTED_DEVICE_FORMATS_COUNT,
        NULL,
        0
    }
};

//=============================================================================
// Data ranges for streaming pin - FIXED to 48000 Hz, 16-bit, Stereo
//
static
KSDATARANGE_AUDIO MicArrayPinDataRangesRawStream[] =
{
    {
        {
            sizeof(KSDATARANGE_AUDIO),
            0,
            0,
            0,
            STATICGUIDOF(KSDATAFORMAT_TYPE_AUDIO),
            STATICGUIDOF(KSDATAFORMAT_SUBTYPE_PCM),
            STATICGUIDOF(KSDATAFORMAT_SPECIFIER_WAVEFORMATEX)
        },
        2,       // MaximumChannels (STEREO)
        16,      // MinimumBitsPerSample (FIXED)
        16,      // MaximumBitsPerSample (FIXED)
        48000,   // MinimumSampleFrequency (FIXED)
        48000    // MaximumSampleFrequency (FIXED)
    }
};

static
PKSDATARANGE MicArrayPinDataRangePointersStream[] =
{
    PKSDATARANGE(&MicArrayPinDataRangesRawStream[0]),
};

//=============================================================================
// Bridge pin data range
//
static
KSDATARANGE MicArrayPinDataRangesBridge[] =
{
    {
        sizeof(KSDATARANGE),
        0,
        0,
        0,
        STATICGUIDOF(KSDATAFORMAT_TYPE_AUDIO),
        STATICGUIDOF(KSDATAFORMAT_SUBTYPE_ANALOG),
        STATICGUIDOF(KSDATAFORMAT_SPECIFIER_NONE)
    }
};

static
PKSDATARANGE MicArrayPinDataRangePointersBridge[] =
{
    &MicArrayPinDataRangesBridge[0]
};

//=============================================================================
// Wave filter pin descriptors
//
static
PCPIN_DESCRIPTOR MicArrayWaveMiniportPins[] =
{
    // Wave In Bridge Pin - 0
    {
        0,
        0,
        0,
        NULL,
        {
            0,
            NULL,
            0,
            NULL,
            SIZEOF_ARRAY(MicArrayPinDataRangePointersBridge),
            MicArrayPinDataRangePointersBridge,
            KSPIN_DATAFLOW_IN,
            KSPIN_COMMUNICATION_NONE,
            &KSCATEGORY_AUDIO,
            NULL,
            0
        }
    },
    // Wave Out Streaming Pin (Capture) - 1
    {
        MICARRAY_MAX_INPUT_STREAMS,
        MICARRAY_MAX_INPUT_STREAMS,
        0,
        NULL,
        {
            0,
            NULL,
            0,
            NULL,
            SIZEOF_ARRAY(MicArrayPinDataRangePointersStream),
            MicArrayPinDataRangePointersStream,
            KSPIN_DATAFLOW_OUT,
            KSPIN_COMMUNICATION_SINK,
            &KSCATEGORY_AUDIO,
            &KSAUDFNAME_RECORDING_CONTROL,
            0
        }
    }
};

//=============================================================================
// Wave filter node descriptors
//
static
PCNODE_DESCRIPTOR MicArrayWaveMiniportNodes[] =
{
    // KSNODE_WAVE_ADC
    {
        0,
        NULL,
        &KSNODETYPE_ADC,
        NULL
    }
};

//=============================================================================
// Wave filter connections
//
static
PCCONNECTION_DESCRIPTOR MicArrayWaveMiniportConnections[] =
{
    { PCFILTER_NODE,     KSPIN_WAVE_BRIDGE,   KSNODE_WAVE_ADC, 1 },
    { KSNODE_WAVE_ADC,   0,                   PCFILTER_NODE,   KSPIN_WAVEIN_HOST }
};

//=============================================================================
// Wave filter descriptor
//
static
PCFILTER_DESCRIPTOR MicArrayWaveMiniportFilterDescriptor =
{
    0,
    NULL,
    sizeof(PCPIN_DESCRIPTOR),
    SIZEOF_ARRAY(MicArrayWaveMiniportPins),
    MicArrayWaveMiniportPins,
    sizeof(PCNODE_DESCRIPTOR),
    SIZEOF_ARRAY(MicArrayWaveMiniportNodes),
    MicArrayWaveMiniportNodes,
    SIZEOF_ARRAY(MicArrayWaveMiniportConnections),
    MicArrayWaveMiniportConnections,
    0,
    NULL
};

#endif // _VIRTUALAUDIODRIVER_MICARRAYWAVTABLE_H_
