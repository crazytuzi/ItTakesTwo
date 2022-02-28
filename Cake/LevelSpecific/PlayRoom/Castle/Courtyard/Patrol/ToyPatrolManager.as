import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Patrol.ToyPatrol;

struct FToyPatrolArray
{
	TArray<AToyPatrol> Array;

	FToyPatrolArray(AToyPatrol ToyPatrol)
	{
		Add(ToyPatrol);
	}

	void Add(AToyPatrol ToyPatrol)
	{
		if (!Array.Contains(ToyPatrol))
			Array.Add(ToyPatrol);
	}

	void Remove(AToyPatrol ToyPatrol)
	{
		if (Array.Contains(ToyPatrol))
			Array.Remove(ToyPatrol);
	}

	bool Contains(AToyPatrol ToyPatrol)
	{
		return Array.Contains(ToyPatrol);
	}
}

class UToyPatrolManagerComponent : UActorComponent
{
	TArray<AToyPatrol> ToyPatrollers;
	TMap<UConnectedHeightSplineComponent, FToyPatrolArray> SplinePatrollerMap;

	UPROPERTY()
	float AvoidanceScale = 1.5f;

	UPROPERTY()
	float AvoidanceSpeedScale = 0.3f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Movement calculation is control-side only, running this would be meaningless
		if (!HasControl())
			return;
			
		for (auto& SplinePatrol : SplinePatrollerMap)
		{
			UConnectedHeightSplineComponent Spline = SplinePatrol.Key;
			TArray<AToyPatrol> Patrollers = SplinePatrol.Value.Array;

			if (Spline == nullptr)
				continue;

			for (int i = 0; i < Patrollers.Num(); ++i)
			{
				AToyPatrol First = Patrollers[i];

				if (First == nullptr)
					continue;

				float FirstDistance = First.SplineFollowerComponent.DistanceOnSpline;
				float FirstOffset = First.SplineFollowerComponent.Offset;
				float FirstRadius = First.CapsuleComponent.ScaledCapsuleRadius;
				bool bFirstDirection = First.SplineFollowerComponent.bForwardDirection;

				// System::DrawDebugCircle(First.CapsuleComponent.ShapeCenter, FirstRadius * AvoidanceScale,
				// 	32, FLinearColor::DPink, ZAxis = FVector::ForwardVector);

				// Already checked against anything that's <= i
				for (int j = i + 1; j < Patrollers.Num(); ++j)
				{
					AToyPatrol Second = Patrollers[j];

					if (Second == nullptr)
						continue;

					float SecondDistance = Second.SplineFollowerComponent.DistanceOnSpline;
					float SecondOffset = Second.SplineFollowerComponent.Offset;
					float SecondRadius = Second.CapsuleComponent.ScaledCapsuleRadius;
					bool bSecondDirection = Second.SplineFollowerComponent.bForwardDirection;

					float AvoidanceRadius = (FirstRadius + SecondRadius) * AvoidanceScale;
					float AvoidanceRadiusSqr = FMath::Square(AvoidanceRadius);
					float DistanceSqr = (Second.ActorLocation - First.ActorLocation).SizeSquared();
					
					if (DistanceSqr <= AvoidanceRadiusSqr)
					{
						float Alpha = FMath::Clamp(1.f - FMath::Abs(DistanceSqr / AvoidanceRadiusSqr), 0.f, 1.f);

						if (bFirstDirection == bSecondDirection)
						{
							// Modify speed if we're going in the same direction
							if (FirstDistance >= SecondDistance)
							{
								First.AvoidanceSpeedScale += AvoidanceSpeedScale;
								Second.AvoidanceSpeedScale -= AvoidanceSpeedScale;
							}
							else
							{
								First.AvoidanceSpeedScale -= AvoidanceSpeedScale;
								Second.AvoidanceSpeedScale += AvoidanceSpeedScale;
							}
						}
						else
						{
							// Add offset if we're moving in the opposite direction
							float Offset = AvoidanceRadius * Alpha;
							if (FirstOffset >= SecondOffset)
							{
								First.AvoidanceOffset += Offset / 2.f;
								Second.AvoidanceOffset -= Offset / 2.f;
							}
							else
							{
								First.AvoidanceOffset -= Offset / 2.f;
								Second.AvoidanceOffset += Offset / 2.f;
							}
						}
					}
				}
			}
		}
	}
}

void RegisterToyPatrol(AToyPatrol ToyPatrol)
{
	UToyPatrolManagerComponent Manager = UToyPatrolManagerComponent::GetOrCreate(Game::May);

	if (Manager.ToyPatrollers.Contains(ToyPatrol))
		return;

	if (Manager.ToyPatrollers.Num() == 0)
		Reset::RegisterPersistentComponent(Manager);
	
	Manager.ToyPatrollers.Add(ToyPatrol);
	Manager.AddTickPrerequisiteActor(ToyPatrol);
	UpdateSplineMapping(ToyPatrol, nullptr, ToyPatrol.SplineFollowerComponent.Spline);
}

void UnregisterToyPatrol(AToyPatrol ToyPatrol)
{
	UToyPatrolManagerComponent Manager = UToyPatrolManagerComponent::GetOrCreate(Game::May);
	bool bWasEmpty = (Manager.ToyPatrollers.Num() == 0);

	// Ensure the toy patrol is removed from spline mapping
	UpdateSplineMapping(ToyPatrol, ToyPatrol.SplineFollowerComponent.Spline, nullptr);

	if (Manager.ToyPatrollers.Contains(ToyPatrol))
		Manager.ToyPatrollers.Remove(ToyPatrol);

	if (Manager.ToyPatrollers.Num() == 0 && !bWasEmpty)
		Reset::UnregisterPersistentComponent(Manager);
}

const TArray<AToyPatrol>& GetAllToyPatrol()
{
	UToyPatrolManagerComponent Manager = UToyPatrolManagerComponent::GetOrCreate(Game::May);
	TArray<AToyPatrol>& List = Manager.ToyPatrollers;
	
	return List;
}

void UpdateSplineMapping(AToyPatrol ToyPatrol, UConnectedHeightSplineComponent Previous, UConnectedHeightSplineComponent Current)
{
	auto Manager = UToyPatrolManagerComponent::GetOrCreate(Game::May);
	auto& SplinePatrollerMap = Manager.SplinePatrollerMap;
	
	// Removes from previous spline if present
	if (Previous != nullptr)
	{
		if (SplinePatrollerMap.Contains(Previous) && SplinePatrollerMap[Previous].Contains(ToyPatrol))
			SplinePatrollerMap[Previous].Remove(ToyPatrol);
	}

	// Add to current spline, adds the kv-pair if not present
	if (Current != nullptr)
	{
		if (!SplinePatrollerMap.Contains(Current))
			SplinePatrollerMap.Add(Current, FToyPatrolArray(ToyPatrol));
		else
			SplinePatrollerMap[Current].Add(ToyPatrol);
	}
}