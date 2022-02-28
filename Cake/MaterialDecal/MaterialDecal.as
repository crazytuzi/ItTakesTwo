class AMaterialDecal : AHazeActor
{
    UFUNCTION()
    FLinearColor RotatorToQuaternion(FRotator input)
    {
        double cy = FMath::Cos(input.Yaw * 0.5);
        double sy = FMath::Sin(input.Yaw * 0.5);
        double cr = FMath::Cos(input.Roll * 0.5);
        double sr = FMath::Sin(input.Roll * 0.5);
        double cp = FMath::Cos(input.Pitch * 0.5);
        double sp = FMath::Sin(input.Pitch * 0.5);

        return FLinearColor(
        cy * sr * cp - sy * cr * sp,
        cy * cr * sp + sy * sr * cp,
        sy * cr * cp - cy * sr * sp,
        cy * cr * cp + sy * sr * sp);
    }
}