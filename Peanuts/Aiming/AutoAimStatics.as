import Peanuts.Aiming.AutoAimTarget;
import Peanuts.WeaponTrace.WeaponTraceStatics;

struct FAutoAimLine
{
    // Whether the aim was changed from the input line at all
    UPROPERTY()
    bool bWasAimChanged = false;

    // The start location for the line we're aiming in
    UPROPERTY()
    FVector AimLineStart;

    // The normalized direction of the aim line
    UPROPERTY()
    FVector AimLineDirection;

    // The radius around the target location that is considered a valid target.
    UPROPERTY()
    float TargetRadius = 0.f;

    // The actor that caused the automatic aiming.
    UPROPERTY()
    AActor AutoAimedAtActor = nullptr;

    // The Target Component that caused the automatic aiming.
    UPROPERTY()
    UAutoAimTargetComponent AutoAimedAtComponent = nullptr;

    // The point in the world that the auto aim is aiming at.
    UPROPERTY()
    FVector AutoAimedAtPoint;
};

struct FAutoAimState
{
	TArray<UAutoAimTargetComponent> CacheGood;
	TArray<UAutoAimTargetComponent> CacheOccluded;
	int CacheSize = 0;
	int CachePosition = 0;
	int CacheUpdateFrame = -1;

	FAutoAimState(int OcclusionCacheFrames = 0)
	{
		CacheSize = OcclusionCacheFrames;
		CachePosition = 0;

		CacheGood.SetNumZeroed(CacheSize);
		CacheOccluded.SetNumZeroed(CacheSize);
	}

	void ResetCache()
	{
		CacheGood.Reset();
		CacheGood.SetNumZeroed(CacheSize);

		CacheOccluded.Reset();
		CacheOccluded.SetNumZeroed(CacheSize);
	}

	void CalculateTargetPoint(UAutoAimTargetComponent Target, float AutoAimMaxAngle,
		FVector OriginalLineStart, FVector OriginalLineEnd, float AngularBend,
		FVector& AimLocation, FVector& TargetPoint, float& TargetRadius, FVector& EdgeTarget)
	{
		AimLocation = Target.WorldLocation;
		FVector PointOnTargetLine = FMath::ClosestPointOnInfiniteLine(OriginalLineStart, OriginalLineEnd, AimLocation);

		TargetPoint = AimLocation;
		EdgeTarget = AimLocation;

		TargetRadius = Target.CalculateTargetRadius();
		if (TargetRadius > 0.f)
		{
			FVector DirectionToTarget = (PointOnTargetLine - AimLocation).GetSafeNormal();

			float EdgeRadius = TargetRadius;
			if (Target.bUseInterpolatedAutoAim)
			{
				float RelativeRadius = AngularBend / AutoAimMaxAngle;
				EdgeRadius = TargetRadius * RelativeRadius;
			}
			
			TargetPoint += (DirectionToTarget * EdgeRadius);
			EdgeTarget += (DirectionToTarget * TargetRadius);
		}
	}

	FAutoAimLine GetAutoAimForTargetLine(
		AHazePlayerCharacter Player,
		FVector OriginalLineStart,
		FVector OriginalLineDirection,
		float MinimumDistance,
		float MaximumDistance,
		bool bCheckVisibility)
	{
		// If the last time we updated this auto aim was several frames ago, drop the cache
		if (CacheSize > 0 && bCheckVisibility)
		{
			if (FMath::Abs(GFrameNumber - CacheUpdateFrame) > 3)
				ResetCache();
		}

		// TODO: Might be nice to use the physics system for this
		//  I'm not expecting a huge amount of auto aim targets right now,
		//  so it should be fine to just enumerate them as a list on the player.
		//  If this changes, might need to alter this.

		UAutoAimTargetComponent ClosestTarget;
		float BestScore = 0.f;
		float ClosestAngularBend = 0.f;

		UAutoAimTargetComponent BestCachedTarget;
		float BestCachedScore = 0.f;
		float BestCachedAngularBend = 0.f;

		FVector OriginalLineDirectionNormalized = OriginalLineDirection.GetSafeNormal();
		FVector OriginalLineEnd = OriginalLineStart + OriginalLineDirection.GetSafeNormal() * MaximumDistance;

		float ConfigStrength = AutoAimStrength.GetFloat();

		// Find the closest auto aim target to our original target point
		UAutoAimComponent AimComponent = UAutoAimComponent::GetOrCreate(Player);
		for (UAutoAimTargetComponent AimTarget : AimComponent.AutoAimTargets)
		{
			// Ignore this target if its not enabled
			if (!AimTarget.bIsAutoAimEnabled)
				continue;

#if !RELEASE
			{
				float DistanceToAimCenter = AimTarget.WorldLocation.Distance(OriginalLineStart);
				const float AutoAimMaxAngle = AimTarget.CalculateAutoAimMaxAngle(MinimumDistance, MaximumDistance, DistanceToAimCenter, ConfigStrength);
				AimTarget.ShowDebug(Player, AutoAimMaxAngle, DistanceToAimCenter);
			}
#endif

			// First check our total distance to early-skip anything too far away
			FVector AimLocation = AimTarget.WorldLocation;

			float DistanceToAimCenter = AimLocation.Distance(OriginalLineStart);

			// Get the target radius
			float TargetRadius = AimTarget.CalculateTargetRadius();

			const float DistanceToSphereBounds = FMath::Max(DistanceToAimCenter - TargetRadius, 0.f);

			// Apply maximum distance
			if (AimTarget.bOverrideMaximumDistance)
			{
				if (DistanceToSphereBounds > AimTarget.MaximumDistance)
					continue;
			}
			else
			{
				if (DistanceToSphereBounds > MaximumDistance)
					continue;
			}

			// Apply minimum distance
			if (AimTarget.bOverrideMinimumDistance)
			{
				if (DistanceToAimCenter < AimTarget.MinimumDistance)
					continue;
			}
			else
			{
				if (DistanceToAimCenter < MinimumDistance)
					continue;
			}

			// Check if we are actually inside the auto-aim arc
			FVector ClosestTargetRadiusPoint = AimLocation;

			if (TargetRadius > 0.f && DistanceToAimCenter > TargetRadius)
			{
				FVector PointOnTargetLine = FMath::ClosestPointOnInfiniteLine(OriginalLineStart, OriginalLineEnd, AimLocation);
				FVector DirectionToTarget = (PointOnTargetLine - AimLocation).GetSafeNormal();
				ClosestTargetRadiusPoint += (DirectionToTarget * TargetRadius);
			}

			FVector TargetDirection = (ClosestTargetRadiusPoint - OriginalLineStart).GetSafeNormal();
			float AngularBend = FMath::RadiansToDegrees(OriginalLineDirectionNormalized.AngularDistanceForNormals(TargetDirection));

			const float AutoAimMaxAngle = AimTarget.CalculateAutoAimMaxAngle(MinimumDistance, MaximumDistance, DistanceToAimCenter, ConfigStrength);
			if (AngularBend > AutoAimMaxAngle)
				continue;

			// If the point was occluded in the most recent few frames, ignore it
			if (CacheOccluded.Contains(AimTarget))
				continue;

			// Score the distance based on how much we have to bend the aim
			float Score = (DistanceToAimCenter / MaximumDistance) * AimTarget.TargetDistanceWeight;
			Score += (AngularBend / AutoAimMaxAngle) * (1.f - AimTarget.TargetDistanceWeight);
			Score += AimTarget.BonusScore;

			// Update closest target
			if (Score < BestScore || ClosestTarget == nullptr)
			{
				ClosestTarget = AimTarget;
				BestScore = Score;
				ClosestAngularBend = AngularBend;
			}

			// Update best cached target
			if (Score < BestCachedScore || BestCachedTarget == nullptr)
			{
				if (CacheGood.Contains(AimTarget))
				{
					BestCachedTarget = AimTarget;
					BestCachedScore = Score;
					BestCachedAngularBend = AngularBend;
				}
			}
		}

		if (ClosestTarget != nullptr)
		{
			// We found an auto aim target, use it
			FVector AimLocation;
			float TargetRadius = 0.f;
			FVector TargetPoint;
			FVector EdgeTarget;

			{
				float DistanceToAimCenter = ClosestTarget.WorldLocation.Distance(OriginalLineStart);
				const float AutoAimMaxAngle = ClosestTarget.CalculateAutoAimMaxAngle(MinimumDistance, MaximumDistance, DistanceToAimCenter, ConfigStrength);
				CalculateTargetPoint(ClosestTarget, AutoAimMaxAngle,
					OriginalLineStart, OriginalLineEnd, ClosestAngularBend,
					AimLocation, TargetPoint, TargetRadius, EdgeTarget);
			}

			// Make sure the auto aim target is visible at all
			if (bCheckVisibility)
			{
				FVector TraceStart = OriginalLineStart;
				FVector TraceEnd = TargetPoint;

				TArray<FHitResult> HitArray;

				System::LineTraceMulti(
					Start = TraceStart,
					End = TraceEnd,
					TraceChannel = ETraceTypeQuery::Visibility,
					bTraceComplex = false,
					ActorsToIgnore = TArray<AActor>(),
					DrawDebugType = EDrawDebugTrace::None,
					OutHits = HitArray,
					bIgnoreSelf = false
				);

				bool bVisibilityBlocked = false;
				for (int i = 0, Count = HitArray.Num(); i < Count; ++i)
				{
					auto Comp = HitArray[i].Component;
					auto Actor = HitArray[i].Actor;

					if (!HitArray[i].bBlockingHit)
						continue;
					if (Comp.IsAttachedTo(Player))
						continue;

					FVector Impact = HitArray[i].ImpactPoint;
					if (!WeaponTrace::IsAutoAimBlockingComponent(Comp))
					{
						if (ClosestTarget.bIgnoreParentForAutoAimTraceBlock)
						{
							if (ClosestTarget.IsAttachedTo(Actor))
								continue;
							if (Comp.IsAttachedTo(ClosestTarget))
								continue;
						}

						float Distance = Impact.Distance(AimLocation);

						if (Distance < FMath::Max(TargetRadius, 20.f))
							continue;
					}
#if !RELEASE
					if (AutoAimDebug.GetInt() != 0)
					{
						System::DrawDebugLine(TraceStart, Impact, FLinearColor::Red, 1.f, 2.f);
						System::DrawDebugPoint(EdgeTarget, 10.f, FLinearColor::Green, 1.f);
					}
#endif
					bVisibilityBlocked = true;
					break;
				}

				if (bVisibilityBlocked)
				{
					// Target is occluded, cache that status
					if (CacheSize > 0)
					{
						CacheGood[CachePosition] = nullptr;
						CacheOccluded[CachePosition] = ClosestTarget;
						CachePosition = (CachePosition + 1) % CacheSize;
						CacheUpdateFrame = GFrameNumber;
					}

					// If we have a 'cached good' auto aim fallback, use that
					if (BestCachedTarget != nullptr && BestCachedTarget != ClosestTarget)
					{
						ClosestTarget = BestCachedTarget;

						{
							float DistanceToAimCenter = ClosestTarget.WorldLocation.Distance(OriginalLineStart);
							const float AutoAimMaxAngle = ClosestTarget.CalculateAutoAimMaxAngle(MinimumDistance, MaximumDistance, DistanceToAimCenter, ConfigStrength);
							CalculateTargetPoint(BestCachedTarget, AutoAimMaxAngle,
								OriginalLineStart, OriginalLineEnd, BestCachedAngularBend,
								AimLocation, TargetPoint, TargetRadius, EdgeTarget);
						}
					}
					else
					{
						// Target is not visible, ignore it
						FAutoAimLine Result;
						Result.AimLineStart = OriginalLineStart;
						Result.AimLineDirection = OriginalLineDirection;

						return Result;
					}
				}
				else
				{
					// Visibility was okay, so add that to the cache
					if (CacheSize > 0)
					{
						CacheGood[CachePosition] = ClosestTarget;
						CacheOccluded[CachePosition] = nullptr;
						CachePosition = (CachePosition + 1) % CacheSize;
						CacheUpdateFrame = GFrameNumber;
					}
				}
			}

			// Need to bend the aiming line to hit the target
			FAutoAimLine Result;
			Result.bWasAimChanged = true;
			Result.AutoAimedAtActor = ClosestTarget.Owner;
			Result.AutoAimedAtComponent = ClosestTarget;
			Result.TargetRadius = TargetRadius;
			Result.AimLineStart = OriginalLineStart;
			Result.AimLineDirection = (TargetPoint - Result.AimLineStart).GetSafeNormal();
			Result.AutoAimedAtPoint = TargetPoint;

			return Result;
		}
		else
		{
			// Empty this frame's cache entry
			if (CacheSize > 0 && bCheckVisibility)
			{
				CacheGood[CachePosition] = nullptr;
				CacheOccluded[CachePosition] = nullptr;
				CachePosition = (CachePosition + 1) % CacheSize;
				CacheUpdateFrame = GFrameNumber;
			}

			// No auto aim target, return aim in original target line
			FAutoAimLine Result;
			Result.AimLineStart = OriginalLineStart;
			Result.AimLineDirection = OriginalLineDirection;

			return Result;
		}
	}
}

UFUNCTION(Category = "Auto Aim", Meta = (ReturnDisplayName = "Auto Aim Line"))
FAutoAimLine GetAutoAimForTargetLine(AHazePlayerCharacter Player, FVector OriginalLineStart, FVector OriginalLineDirection, float MinimumDistance, float MaximumDistance, bool bCheckVisibility)
{
	FAutoAimState TempState;
	return TempState.GetAutoAimForTargetLine(Player, OriginalLineStart, OriginalLineDirection, MinimumDistance, MaximumDistance, bCheckVisibility);
}