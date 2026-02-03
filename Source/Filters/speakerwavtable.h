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
// ISL Virtual Mic - FIXED FORMAT for guaranteed compatibility
// CRITICAL: Both speaker and mic MUST use the same format to prevent
// robotic voice distortion from sample rate mismatch.
// Format: 48000 Hz, 16-bit, Stereo (matches desktop app AudioContext)
//=============================================================================
#define SPEAKER_DEVICE_MAX_CHANNELS         2
#define SPEAKER_HOST_MAX_CHANNELS           2
#define SPEAKER_HOST_MIN_BITS_PER_SAMPLE    16
#define SPEAKER_HOST_MAX_BITS_PER_SAMPLE    16
#define SPEAKER_HOST_MIN_SAMPLE_RATE        48000
#define SPEAKER_HOST_MAX_SAMPLE_RATE        48000

#define SPEAKER_MAX_INPUT_SYSTEM_STREAMS    8

//=============================================================================
// Supported device formats - SINGLE FORMAT ONLY to prevent mismatch
// 48000 Hz, 16-bit, Stereo - matches Web Audio API default
//=============================================================================
static
KSDATAFORMAT_WAVEFORMATEXTENSIBLE SpeakerHostPinSupportedDeviceFormats[] =
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
// Data ranges for streaming pin - FIXED to 48000 Hz, 16-bit, Stereo
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
        16,      // MinimumBitsPerSample (FIXED)
        16,      // MaximumBitsPerSample (FIXED)
        48000,   // MinimumSampleFrequency (FIXED)
        48000    // MaximumSampleFrequency (FIXED)
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
