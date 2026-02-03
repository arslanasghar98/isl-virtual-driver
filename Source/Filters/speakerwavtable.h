/*++

Copyright (c) Microsoft Corporation All Rights Reserved

Module Name:

    speakerwavtable.h

Abstract:

    Declaration of wave miniport tables for the render endpoints.
--*/

#ifndef _VIRTUALAUDIODRIVER_SPEAKERWAVTABLE_H_
#define _VIRTUALAUDIODRIVER_SPEAKERWAVTABLE_H_

//=============================================================================
// Stereo audio format support for ISL Virtual Mic (VB-Cable compatible)
//
#define SPEAKER_DEVICE_MAX_CHANNELS         2
#define SPEAKER_HOST_MAX_CHANNELS           2
#define SPEAKER_HOST_MIN_BITS_PER_SAMPLE    8
#define SPEAKER_HOST_MAX_BITS_PER_SAMPLE    24
#define SPEAKER_HOST_MIN_SAMPLE_RATE        44100
#define SPEAKER_HOST_MAX_SAMPLE_RATE        96000

#define SPEAKER_MAX_INPUT_SYSTEM_STREAMS    8

//=============================================================================
// Supported device formats - VB-Cable compatible (Stereo, 8/16/24 bit, 44100-96000 Hz)
//
static
KSDATAFORMAT_WAVEFORMATEXTENSIBLE SpeakerHostPinSupportedDeviceFormats[] =
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

#define SPEAKER_HOST_PIN_SUPPORTED_DEVICE_FORMATS_COUNT (SIZEOF_ARRAY(SpeakerHostPinSupportedDeviceFormats))

//=============================================================================
// Pin device formats and modes - simplified
//
static 
PIN_DEVICE_FORMATS_AND_MODES SpeakerPinDeviceFormatsAndModes[] = 
{
    {
        SystemRenderPin,
        SpeakerHostPinSupportedDeviceFormats,
        SPEAKER_HOST_PIN_SUPPORTED_DEVICE_FORMATS_COUNT,
        NULL,
        0
    }
};

//=============================================================================
// Data ranges for streaming pin - VB-Cable compatible (Stereo, 8/16/24 bit, 44100-96000 Hz)
//
static
KSDATARANGE_AUDIO SpeakerPinDataRangesStream[] =
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
PKSDATARANGE SpeakerPinDataRangePointersStream[] =
{
    PKSDATARANGE(&SpeakerPinDataRangesStream[0]),
};

//=============================================================================
// Bridge pin data range
//
static
KSDATARANGE SpeakerPinDataRangesBridge[] =
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
PKSDATARANGE SpeakerPinDataRangePointersBridge[] =
{
    &SpeakerPinDataRangesBridge[0]
};

//=============================================================================
// Wave filter pin descriptors
//
static 
PCPIN_DESCRIPTOR SpeakerWaveMiniportPins[] = 
{
    // Wave In Streaming Pin (Renderer) - 0
    {
        SPEAKER_MAX_INPUT_SYSTEM_STREAMS,
        SPEAKER_MAX_INPUT_SYSTEM_STREAMS, 
        0,
        NULL,
        {
            0,
            NULL,
            0,
            NULL,
            SIZEOF_ARRAY(SpeakerPinDataRangePointersStream),
            SpeakerPinDataRangePointersStream,
            KSPIN_DATAFLOW_IN,
            KSPIN_COMMUNICATION_SINK,
            &KSCATEGORY_AUDIO,
            NULL,
            0
        }
    },
    // Wave Out Bridge Pin - 1
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
            SIZEOF_ARRAY(SpeakerPinDataRangePointersBridge),
            SpeakerPinDataRangePointersBridge,
            KSPIN_DATAFLOW_OUT,
            KSPIN_COMMUNICATION_NONE,
            &KSCATEGORY_AUDIO,
            NULL,
            0
        }
    }
};

//=============================================================================
// Wave filter node descriptors
//
static
PCNODE_DESCRIPTOR SpeakerWaveMiniportNodes[] =
{
    // KSNODE_WAVE_SUM
    {
        0,
        NULL,
        &KSNODETYPE_SUM,
        NULL
    },
    // KSNODE_WAVE_VOLUME
    {
        0,
        NULL,
        &KSNODETYPE_VOLUME,
        NULL
    },
    // KSNODE_WAVE_MUTE
    {
        0,
        NULL,
        &KSNODETYPE_MUTE,
        NULL
    },
    // KSNODE_WAVE_PEAKMETER
    {
        0,
        NULL,
        &KSNODETYPE_PEAKMETER,
        NULL
    }
};

//=============================================================================
// Wave filter connections
//
static
PCCONNECTION_DESCRIPTOR SpeakerWaveMiniportConnections[] =
{
    { PCFILTER_NODE,        KSPIN_WAVE_RENDER3_SINK_SYSTEM, KSNODE_WAVE_SUM,       1 },
    { KSNODE_WAVE_SUM,      0,                              KSNODE_WAVE_VOLUME,    1 },
    { KSNODE_WAVE_VOLUME,   0,                              KSNODE_WAVE_MUTE,      1 },
    { KSNODE_WAVE_MUTE,     0,                              KSNODE_WAVE_PEAKMETER, 1 },
    { KSNODE_WAVE_PEAKMETER,0,                              PCFILTER_NODE,         KSPIN_WAVE_RENDER3_SOURCE }
};

//=============================================================================
// Wave filter descriptor
//
static
PCFILTER_DESCRIPTOR SpeakerWaveMiniportFilterDescriptor =
{
    0,
    NULL,
    sizeof(PCPIN_DESCRIPTOR),
    SIZEOF_ARRAY(SpeakerWaveMiniportPins),
    SpeakerWaveMiniportPins,
    sizeof(PCNODE_DESCRIPTOR),
    SIZEOF_ARRAY(SpeakerWaveMiniportNodes),
    SpeakerWaveMiniportNodes,
    SIZEOF_ARRAY(SpeakerWaveMiniportConnections),
    SpeakerWaveMiniportConnections,
    0,
    NULL
};

#endif // _VIRTUALAUDIODRIVER_SPEAKERWAVTABLE_H_
