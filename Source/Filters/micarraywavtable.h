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
// Stereo audio format support for ISL Virtual Mic (VB-Cable compatible)
//
#define MICARRAY_RAW_CHANNELS               2
#define MICARRAY_DEVICE_MAX_CHANNELS        2
#define MICARRAY_MIN_BITS_PER_SAMPLE        8
#define MICARRAY_MAX_BITS_PER_SAMPLE        24
#define MICARRAY_MIN_SAMPLE_RATE            44100
#define MICARRAY_MAX_SAMPLE_RATE            96000

#define MICARRAY_MAX_INPUT_STREAMS          8

//=============================================================================
// Supported device formats - VB-Cable compatible (Stereo, 8/16/24 bit, 44100-96000 Hz)
//
static
KSDATAFORMAT_WAVEFORMATEXTENSIBLE MicArrayPinSupportedDeviceFormats[] =
{
    // 0) 16-bit, Stereo, 48 kHz (most common)
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
                48000 * 2 * 16 / 8,             // nAvgBytesPerSec
                2 * 16 / 8,                     // nBlockAlign
                16,                             // wBitsPerSample
                sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX)
            },
            16,                                 // wValidBitsPerSample
            KSAUDIO_SPEAKER_STEREO,
            STATICGUIDOF(KSDATAFORMAT_SUBTYPE_PCM)
        }
    },
    // 1) 16-bit, Stereo, 44.1 kHz
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
                2,
                44100,
                44100 * 2 * 16 / 8,
                2 * 16 / 8,
                16,
                sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX)
            },
            16,
            KSAUDIO_SPEAKER_STEREO,
            STATICGUIDOF(KSDATAFORMAT_SUBTYPE_PCM)
        }
    },
    // 2) 16-bit, Stereo, 96 kHz
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
                2,
                96000,
                96000 * 2 * 16 / 8,
                2 * 16 / 8,
                16,
                sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX)
            },
            16,
            KSAUDIO_SPEAKER_STEREO,
            STATICGUIDOF(KSDATAFORMAT_SUBTYPE_PCM)
        }
    },
    // 3) 24-bit, Stereo, 48 kHz
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
                2,
                48000,
                48000 * 2 * 24 / 8,
                2 * 24 / 8,
                24,
                sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX)
            },
            24,
            KSAUDIO_SPEAKER_STEREO,
            STATICGUIDOF(KSDATAFORMAT_SUBTYPE_PCM)
        }
    },
    // 4) 24-bit, Stereo, 44.1 kHz
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
                2,
                44100,
                44100 * 2 * 24 / 8,
                2 * 24 / 8,
                24,
                sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX)
            },
            24,
            KSAUDIO_SPEAKER_STEREO,
            STATICGUIDOF(KSDATAFORMAT_SUBTYPE_PCM)
        }
    },
    // 5) 24-bit, Stereo, 96 kHz
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
                2,
                96000,
                96000 * 2 * 24 / 8,
                2 * 24 / 8,
                24,
                sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX)
            },
            24,
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
// Data ranges for streaming pin - VB-Cable compatible (Stereo, 8/16/24 bit, 44100-96000 Hz)
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
        8,       // MinimumBitsPerSample
        24,      // MaximumBitsPerSample
        44100,   // MinimumSampleFrequency
        96000    // MaximumSampleFrequency
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
