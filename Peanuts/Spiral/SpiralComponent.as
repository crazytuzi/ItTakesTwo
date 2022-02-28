
class USpiralComponent : UHazeSpiralComponent
{

	UFUNCTION(BlueprintOverride)
	void Tick(const float DeltaSeconds) 
	{
	}

	UFUNCTION(BlueprintCallable)
	FSpiralParticle GetNearestSpiralParticle(const FVector& InWorldLocation) const
	{
		float ClosestSpiralPointDistanceSQ = BIG_NUMBER;
		FSpiralParticle ClosestSpiralPoint = FSpiralParticle();
// 		Print("" + SpiralParticles.Num());
		if (SpiralParticles.Num() > 0)
		{
			for (int i = 0; i < SpiralParticles.Num(); ++i)
			{
				const float DistToSpiralPointSQ = InWorldLocation.DistSquared(SpiralParticles[i].Current);
				if (DistToSpiralPointSQ < ClosestSpiralPointDistanceSQ)
				{
					ClosestSpiralPointDistanceSQ = DistToSpiralPointSQ;
					ClosestSpiralPoint = SpiralParticles[i];
// 					Print("" + DistToSpiralPointSQ);
				}
			}
		}

// 		Print("Current: " + ClosestSpiralPoint.Current + "\n" + "Prev: " + ClosestSpiralPoint.PrevIndex + "\n" + "Next: " + ClosestSpiralPoint.NextIndex);

		return ClosestSpiralPoint;
	}

	UFUNCTION(BlueprintCallable)
	FVector GetNearestSpiralPointLocation(const FVector& InWorldLocation) 
	{
		float ClosestSpiralPointDistanceSQ = BIG_NUMBER;
		FVector ClosestSpiralPointLocation = FVector::ZeroVector;
		if (SpiralParticleLocations.Num() > 0)
		{
			for (int i = 0; i < SpiralParticleLocations.Num(); ++i)
			{
				const float DistToSpiralPointSQ = InWorldLocation.DistSquared(SpiralParticleLocations[i]);
				if (DistToSpiralPointSQ < ClosestSpiralPointDistanceSQ)
				{
					ClosestSpiralPointDistanceSQ = DistToSpiralPointSQ;
					ClosestSpiralPointLocation = SpiralParticleLocations[i];
				}
			}
		}
		return ClosestSpiralPointLocation;
	}

	UFUNCTION(BlueprintPure)
	const FSpiralParticle& GetParticleNext(const FSpiralParticle& CurrentSpiralPoint) const
	{
		ensure(SpiralParticles.IsValidIndex(CurrentSpiralPoint.NextIndex));
		return SpiralParticles[CurrentSpiralPoint.NextIndex];
	}

	UFUNCTION(BlueprintPure)
	const FSpiralParticle& GetParticlePrev(const FSpiralParticle& CurrentSpiralPoint) const
	{
		ensure(SpiralParticles.IsValidIndex(CurrentSpiralPoint.PrevIndex));
		return SpiralParticles[CurrentSpiralPoint.PrevIndex];
	}

	UFUNCTION(BlueprintPure)
	const FVector& GetParticleLocationFromIndex(const int32& Index) const
	{
		if(SpiralParticles.IsValidIndex(Index))
			return SpiralParticles[Index].Current;
		return FVector::ZeroVector;
	}

};





























