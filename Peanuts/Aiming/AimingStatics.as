UFUNCTION(Category = "Aiming")
bool IsTargetWithinCone(FVector ConeOrigin, FVector NormalizedConeDirection, float ConeCosAngle, FVector TargetPosition)
{
	FVector ToTarget = (TargetPosition - ConeOrigin).GetSafeNormal();
	float TargetCosAngle = NormalizedConeDirection.DotProduct(ToTarget);

	return TargetCosAngle > ConeCosAngle;
}
