
class UPhase3RailSwordComponent : UActorComponent
{
	/* queen will ignore these when switching shapes.
	 The swarm will flip the bool himself once it is finished with the first attack... */
	UPROPERTY(Category = "Queen P3 Swarm Component")
	bool bIntroSwarm = false;

	// Assigned by Manager. Needed for spacing between swarms
	int AssignedIndex;

	// Current Angle around queen. Used in both sword and shield
	float CurrentAngle = 0.f;

	// Used in shield formations
	float DesiredOffsetX = 0.f;
	float DesiredOffsetZ = 0.f;

	FVector CalculateSwordTelegraphPos(const FVector& InQueenPos) const
	{
		FVector DesiredPosition = InQueenPos + FVector::UpVector * 700;
		FVector OffsetFromQueen = FVector::ForwardVector * 1500.f;
		OffsetFromQueen = OffsetFromQueen.RotateAngleAxis(CurrentAngle, FVector::UpVector);
		DesiredPosition += OffsetFromQueen;
		return DesiredPosition;
	}
}