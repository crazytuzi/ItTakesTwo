
delegate void FFinishedSignature();

UFUNCTION()
float TickTimer(float &StoredValue, float Duration, float DeltaTime, FRuntimeFloatCurve Curve, FFinishedSignature OnFinished)
{
    return 0.f;
}