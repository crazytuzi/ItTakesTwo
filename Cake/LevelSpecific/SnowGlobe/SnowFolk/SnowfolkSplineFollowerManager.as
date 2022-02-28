import Cake.LevelSpecific.SnowGlobe.Snowfolk.SnowfolkSplineFollower;

struct FSnowfolkArray
{
	TArray<ASnowfolkSplineFollower> Snowfolks;

	FSnowfolkArray(ASnowfolkSplineFollower Snowfolk)
	{
		Snowfolks.Add(Snowfolk);
	}
}

class ASnowfolkSplineFollowerManager : AHazeActor
{
    UPROPERTY(DefaultComponent, NotEditable)
    UBillboardComponent BillboardComponent;
	default BillboardComponent.SetRelativeScale3D(4.f);

	UPROPERTY()
	float SplineDistance = 1000.f;
	
	UPROPERTY()
	float OffsetDistance = 400.f;

	UPROPERTY()
	bool bAvoidPlayers = false;

	UPROPERTY()
	bool bAvoidSnowfolk = true;

	UPROPERTY()
	bool bDrawDebug = false;

	TMap<UConnectedHeightSplineComponent, FSnowfolkArray> ManagerList; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<ASnowfolkSplineFollower> AllSnowfolkSplineFollowers;

		GetAllActorsOfClass(AllSnowfolkSplineFollowers);

		for (auto SnowfolkSplineFollower : AllSnowfolkSplineFollowers)
		{
			if (SnowfolkSplineFollower.SplineFollowerComponent.SplineActor == nullptr || !SnowfolkSplineFollower.bUseAvoidance)
				continue;

			// !!! !!! Set Snowfolk tick after Manager !!! !!!
			//SnowfolkSplineFollower.AddTickPrerequisiteActor(this);

			AddTickPrerequisiteActor(SnowfolkSplineFollower);

			SnowfolkSplineFollower.SplineFollowerComponent.SetSplineActorSpline();

			SnowfolkSplineFollower.SplineFollowerComponent.OnSplineTransition.AddUFunction(this, n"OnSplineTransition");

			if (ManagerList.Contains(SnowfolkSplineFollower.SplineFollowerComponent.Spline))
				ManagerList[SnowfolkSplineFollower.SplineFollowerComponent.Spline].Snowfolks.Add(SnowfolkSplineFollower);
			else
				ManagerList.Add(SnowfolkSplineFollower.SplineFollowerComponent.Spline, FSnowfolkArray(SnowfolkSplineFollower));
		}

	//	PrintScaled("AllSnowfolkSplineFollowers: " + AllSnowfolkSplineFollowers.Num(), 1.f, FLinearColor::Yellow, 4.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (auto Elem : ManagerList)
		{			
		//	PrintScaled("Spline " + Elem.Key.Owner.Name + " has " + Elem.Value.Snowfolks.Num() + " Snowfolks.", 0.f, FLinearColor::Yellow, 2.f);

			for (ASnowfolkSplineFollower Snowfolk : Elem.Value.Snowfolks)
			{
				float TotalAdjustment = 0.f;

				if (!Snowfolk.bIsSnowfolkActivated)
					continue;

				if (!Snowfolk.bCanMove)
					continue;

				if (Snowfolk.bIsRecovering)
					continue;

				if (Snowfolk.bIsHit)
					continue;
					
				if (Snowfolk.bIsDown)
					continue;

				if (Snowfolk.bMovementIsBlocked)
					continue;

				// Add Adjustment for Snowfolk
				if (bAvoidSnowfolk)
				{
					float Distance = Snowfolk.SplineFollowerComponent.DistanceOnSpline;
					float Offset = Snowfolk.SplineFollowerComponent.Offset;

					for (ASnowfolkSplineFollower Neighbor : Elem.Value.Snowfolks)
					{			
					//	float SplineDistanceScaled = SplineDistance; // * Neighbor.ActorTransform.Scale3D.X;
					//	float OffsetDistanceScaled = OffsetDistance * Neighbor.ActorTransform.Scale3D.X;

						float SplineDistanceScaled = Neighbor.AvoidanceArea.X;
						float OffsetDistanceScaled = Neighbor.AvoidanceArea.Y * Neighbor.ActorTransform.Scale3D.X;

						if (!Neighbor.SplineFollowerComponent.bForwardDirection)
							SplineDistanceScaled * -1.f;

						if (Neighbor != Snowfolk)
						{							
							float DistanceToNeighbor = (Neighbor.SplineFollowerComponent.Spline.IsClosedLoop()) ? FMath::Min(FMath::Abs(Distance - Neighbor.SplineFollowerComponent.DistanceOnSpline), Neighbor.SplineFollowerComponent.Spline.SplineLength - FMath::Abs(Distance - Neighbor.SplineFollowerComponent.DistanceOnSpline)) : FMath::Abs(Distance - Neighbor.SplineFollowerComponent.DistanceOnSpline);

							if (DistanceToNeighbor <= SplineDistanceScaled)
								if (FMath::IsWithin(Neighbor.SplineFollowerComponent.Offset, Offset - OffsetDistanceScaled, Offset + OffsetDistanceScaled))
								{
									if (bDrawDebug)
									{
										System::DrawDebugBox(Neighbor.ActorLocation, FVector(SplineDistanceScaled, OffsetDistanceScaled, 200.f), FLinearColor::Yellow, Neighbor.ActorRotation, 0.f, 10.f);
										PrintToScreen("DistanceToNeighbor: " + DistanceToNeighbor, 0.f, FLinearColor::Green);
									}

									float DistanceAlpha = 1.f - (DistanceToNeighbor / SplineDistanceScaled);
							//		float DistanceAlpha = 1.f - FMath::Abs((Distance - Neighbor.SplineFollowerComponent.DistanceOnSpline) / SplineDistanceScaled);

									if (Neighbor.bDrawDebug)
										PrintScaled("DistanceAlpha " + DistanceAlpha, 0.f, FLinearColor::Yellow, 1.f);

									float OffsetAdjustment = (Offset - Neighbor.SplineFollowerComponent.Offset);

									if (FMath::IsNearlyZero(OffsetAdjustment))
										OffsetAdjustment = (Neighbor.SplineFollowerComponent.bForwardDirection ? -1.f : 1.f);

									OffsetAdjustment = FMath::Sign(OffsetAdjustment) * (OffsetDistanceScaled - FMath::Abs(OffsetAdjustment));
												
									TotalAdjustment += OffsetAdjustment * DistanceAlpha;
								}				
						}
					}
				}

				// Add Adjustment for Players
				if (bAvoidPlayers)
					TotalAdjustment += GetPlayerAvoidance(Snowfolk);

				// Lerp Adjustment
		//		Snowfolk.ExtraOffset = TotalAdjustment;

				// Scale how much this Snowfolk is affected by others
				TotalAdjustment *= Snowfolk.AvoidanceWeight;

				Snowfolk.MovementComp.ExtraOffset = FMath::Lerp(Snowfolk.MovementComp.ExtraOffset, TotalAdjustment, 1.f * DeltaTime);
		//		Snowfolk.ExtraOffset = FMath::Lerp(Snowfolk.ExtraOffset, TotalAdjustment, 40.f * DeltaTime);	

				if (bDrawDebug)
				{
					System::DrawDebugLine(Snowfolk.ActorLocation + (Snowfolk.ActorUpVector * 10.f), Snowfolk.ActorLocation + (Snowfolk.ActorUpVector * 10.f) + Snowfolk.SplineFollowerComponent.GetSplineTransform().Rotation.RightVector * -Snowfolk.MovementComp.ExtraOffset, FLinearColor::Red, 0.f, 20.f);
					System::DrawDebugSphere(Snowfolk.ActorLocation + (Snowfolk.SplineFollowerComponent.GetSplineTransform().Rotation.RightVector * -Snowfolk.MovementComp.ExtraOffset), 50.f, 12, FLinearColor::Red, 0.f, 10.f);
				//	System::DrawDebugLine(Snowfolk.ActorLocation + (Snowfolk.ActorUpVector * 10.f), Snowfolk.ActorLocation + (Snowfolk.ActorUpVector * 10.f) + Snowfolk.SplineFollowerComponent.GetSplineTransform().Rotation.RightVector * -TotalAdjustment, FLinearColor::Green, 0.f, 20.f);
				}
			}
		}
	}

	UFUNCTION()
	void OnSplineTransition(UConnectedHeightSplineFollowerComponent ConnectedHeightSplineFollowerComponent, bool bForward)
	{
		auto SnowfolkSplineFollower = Cast<ASnowfolkSplineFollower>(ConnectedHeightSplineFollowerComponent.Owner);

		if (SnowfolkSplineFollower == nullptr)
			return;

		if (ManagerList.Contains(ConnectedHeightSplineFollowerComponent.PreviousSpline))
		{
			ManagerList[ConnectedHeightSplineFollowerComponent.PreviousSpline].Snowfolks.Remove(SnowfolkSplineFollower);

			if (ManagerList[ConnectedHeightSplineFollowerComponent.PreviousSpline].Snowfolks.Num() == 0)
				ManagerList.Remove(SnowfolkSplineFollower.SplineFollowerComponent.PreviousSpline);	
		}
		
		if (ManagerList.Contains(ConnectedHeightSplineFollowerComponent.Spline))
			ManagerList[ConnectedHeightSplineFollowerComponent.Spline].Snowfolks.Add(SnowfolkSplineFollower);
		else
			ManagerList.Add(SnowfolkSplineFollower.SplineFollowerComponent.Spline, FSnowfolkArray(SnowfolkSplineFollower));
	}

	float GetPlayerAvoidance(ASnowfolkSplineFollower Snowfolk)
	{
		auto Player = Snowfolk.ProximityComp.GetClosestPlayer();
		if (Player == nullptr)
			return 0.f;

		FVector PlayerRelativeLocation = Snowfolk.SplineFollowerComponent.GetSplineTransform(true).InverseTransformPosition(Player.ActorLocation);

		float PlayerOffsetAdjustment = -FMath::Sign(PlayerRelativeLocation.Y) * (500.f - FMath::Abs(PlayerRelativeLocation.Y));

		float DistanceAlpha = 1.f - FMath::Abs(PlayerRelativeLocation.X / 1000.f);
	
	//	PrintScaled("DistanceAlpha " + DistanceAlpha, 0.f, FLinearColor::Yellow, 1.f);

		PlayerOffsetAdjustment *= DistanceAlpha;

	//	System::DrawDebugSphere(Snowfolk.ClosestPlayer.ActorLocation, 500.f, 12, FLinearColor::Green, 0.f, 10.f);
	//	PrintScaled("OffsetAdjustment " + OffsetAdjustment, 0.f, FLinearColor::Yellow, 1.f);

		return PlayerOffsetAdjustment;
	}
}