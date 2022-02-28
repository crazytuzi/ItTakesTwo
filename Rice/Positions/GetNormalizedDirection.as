UFUNCTION(Category = "Utilities|Direction", BlueprintPure)
FVector GetNormalizedDirection(FVector From, FVector To)
{
    FVector result = To-From;
    result.Normalize();

    return result;
}