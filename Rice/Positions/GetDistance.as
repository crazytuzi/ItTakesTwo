UFUNCTION(Category = "Utilities|Location", BlueprintPure)
float GetVectorDistance(FVector Start, FVector End)
{
    FVector Distance = FVector::ZeroVector;
    Distance = Start - End;
    return Distance.Size();
}