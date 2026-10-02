/*++

Module Name:

    calljoyna_telemetry.h

Abstract:

    Public definitions for the CallJoyna driver telemetry property set.

    This header is shared between the kernel driver (both topology filters)
    and user-mode clients. It only depends on ks.h style GUID macros and
    basic Windows types, so it can be included from a user-mode project
    after <windows.h> + <ks.h> (or from the driver after <portcls.h>).

    Property set : KSPROPSETID_CallJoynaTelemetry
                   {EA30EDA4-0EDC-4C03-B8B4-6455AFE518E1}
    Property id  : KSPROPERTY_CALLJOYNA_TELEMETRY (1), GET + BASICSUPPORT only
    Exposed on   : the "CallJoyna Speaker" and "CallJoyna Mic" topology filters
    Value        : CALLJOYNA_TELEMETRY (32 bytes)

--*/

#ifndef _CALLJOYNA_TELEMETRY_H_
#define _CALLJOYNA_TELEMETRY_H_

//=============================================================================
// Property set GUID
//=============================================================================
#define STATIC_KSPROPSETID_CallJoynaTelemetry \
    0xea30eda4, 0x0edc, 0x4c03, 0xb8, 0xb4, 0x64, 0x55, 0xaf, 0xe5, 0x18, 0xe1
DEFINE_GUIDSTRUCT("EA30EDA4-0EDC-4C03-B8B4-6455AFE518E1", KSPROPSETID_CallJoynaTelemetry);
#define KSPROPSETID_CallJoynaTelemetry DEFINE_GUIDNAMED(KSPROPSETID_CallJoynaTelemetry)

//=============================================================================
// Property ids
//=============================================================================
typedef enum
{
    KSPROPERTY_CALLJOYNA_TELEMETRY = 1      // GET: CALLJOYNA_TELEMETRY
} KSPROPERTY_CALLJOYNA;

//=============================================================================
// Property value
//
// All counters are monotonically increasing ULONGs that wrap at 2^32, except
// micEngagedCount / speakerEngagedCount (live gauges) and
// loopbackBytesAvailable (live gauge, bytes queued in the ring buffer).
//
// cbSize is filled by the driver with sizeof(CALLJOYNA_TELEMETRY) so that
// future versions can append fields while older clients keep working.
//=============================================================================
#pragma pack(push, 4)
typedef struct _CALLJOYNA_TELEMETRY
{
    ULONG cbSize;                   // sizeof(CALLJOYNA_TELEMETRY), set by the driver
    ULONG micEngagedCount;          // capture (mic) streams currently in KSSTATE_RUN
    ULONG speakerEngagedCount;      // render (speaker) streams currently in KSSTATE_RUN
    ULONG loopbackBytesAvailable;   // bytes queued in the speaker->mic ring buffer
    ULONG loopbackWriteCount;       // WriteToLoopbackBuffer calls that wrote >= 1 frame
    ULONG loopbackReadCount;        // ReadFromLoopbackBuffer calls (all)
    ULONG loopbackOverruns;         // writes that discarded oldest queued audio
    ULONG loopbackUnderruns;        // reads after preroll that had to zero-fill
} CALLJOYNA_TELEMETRY, *PCALLJOYNA_TELEMETRY;
#pragma pack(pop)

// Offsets are fixed: 8 x ULONG = 32 bytes.
C_ASSERT(sizeof(CALLJOYNA_TELEMETRY) == 32);

#endif // _CALLJOYNA_TELEMETRY_H_
