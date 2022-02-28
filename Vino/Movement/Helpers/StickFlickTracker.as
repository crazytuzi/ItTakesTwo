
struct FStickDelta
{
	FVector2D StickPosition;
	float DeltaTime;

	FStickDelta()
	{
		StickPosition = FVector2D::ZeroVector;
		DeltaTime = 0.f;
	}

	FStickDelta(FVector2D StickPosition_, float DeltaTime_)
	{
		StickPosition = StickPosition_;
		DeltaTime = DeltaTime_;
	}
}

struct FStickFlickTracker
{
	TArray<FStickDelta> StickDeltas;
	float StoredHistory = 0.f;

	void AddStickDelta(FStickDelta StickDelta, float HistoryLength = 0.2f)
	{
		StickDeltas.Insert(StickDelta, 0);
		StoredHistory += StickDelta.DeltaTime;

		int LastIndex = StickDeltas.Num() - 1;
		while ((StoredHistory - StickDeltas[LastIndex].DeltaTime) > HistoryLength)
		{
			StoredHistory -= StickDeltas[LastIndex].DeltaTime;
			StickDeltas.RemoveAt(LastIndex);
			LastIndex = StickDeltas.Num() - 1;
		}
	}

	bool TestStickData(FVector2D Direction) const
	{
		// You need two deltas to check a flick
		if (StickDeltas.Num() < 2)
			return false;

		FVector2D DirectionNormalized = Direction.GetSafeNormal();
		FVector2D DirectionRight = FVector2D(DirectionNormalized.Y, -DirectionNormalized.X);		

		float FlickWidthLimit = 0.7f;
		float FlickStartEndMinimumLength = 0.5f;

		FStickDelta EndDelta = StickDeltas[0];
		// If the direction is zero
		if (Direction.IsNearlyZero())
			return false;

		// If the end location is not far enough away in the correct direction
		float EndLocationDirectionDot = EndDelta.StickPosition.DotProduct(DirectionNormalized);
		if (EndLocationDirectionDot < FlickStartEndMinimumLength)
			return false;

		// If the end location is outside of the width tolerance
		float EndWidthDistanceDot = FMath::Abs(EndDelta.StickPosition.DotProduct(DirectionRight));
		if (EndWidthDistanceDot > FlickWidthLimit)
		{
			return false;
		}

		for (int Index = 0, Count = StickDeltas.Num() - 1; Index < Count; ++Index)
		{			
			FStickDelta CurrentDelta = StickDeltas[Index];
			FStickDelta PreviousDelta = StickDeltas[Index + 1];

			// If the previous location is outside of the width tolerance
			float PreviousWidthDistanceDot = FMath::Abs(PreviousDelta.StickPosition.DotProduct(DirectionRight));
			if (PreviousWidthDistanceDot > FlickWidthLimit)
				return false;

			// If the two locations are almost the same, skip to the next
			// 		This helps keyboard users that have to let go of a button to press the next. You will get dupe frames
			if ((PreviousDelta.StickPosition - CurrentDelta.StickPosition).Size() < 0.05f)
				continue;

			// FAIL: If the flick direction is in the wrong direction (opposite to the direction)
			float FlickDeltaDirectionDot = (CurrentDelta.StickPosition - PreviousDelta.StickPosition).DotProduct(DirectionNormalized);
			if (FlickDeltaDirectionDot < 0.f)
				return false;

			// If the oldest location is far enough away in the correct direction - SUCCESS!
			float StartFlickDot = PreviousDelta.StickPosition.DotProduct(DirectionNormalized);
			if (StartFlickDot < -FlickStartEndMinimumLength)
				return true;
			else
				continue;
		}
		return false;
	}

}
