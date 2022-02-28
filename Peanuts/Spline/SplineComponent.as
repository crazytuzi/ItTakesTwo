
/**
 * Base class for the spline component on the .as level. 
 */

struct FSplineAttachPoint
{
	UHazeSplineComponent OtherSpline;
	ESplineAttachSide OtherSplineSide;
	USplineAttachPointComponent AttachPoint;
	int AttachPointIndex;
	FVector Location;
	FVector Tangent;
}

enum ESplineAttachSide
{
	Start,
	End,
}

class USplineAttachPointComponent : USceneComponent
{
	UPROPERTY()
	TArray<FTransform> AttachPoints;
}

class UHazeSplineComponent : UHazeSplineComponentBase
{
	TArray<FSplineAttachPoint> GetAllAttachPoints() const
	{
		TArray<FSplineAttachPoint> FoundPoints = TArray<FSplineAttachPoint>();

		TArray<AActor> AllActors = TArray<AActor>();
		Gameplay::GetAllActorsOfClass(AActor::StaticClass(), AllActors);
		for(int i = 0; i < AllActors.Num(); i++)
		{
			// Other Splines
			TArray<UActorComponent> SplineComponents = AllActors[i].GetComponentsByClass(UHazeSplineComponent::StaticClass());
			for(int j = 0; j < SplineComponents.Num(); j++)
			{
				UHazeSplineComponent CurrentComp = Cast<UHazeSplineComponent>(SplineComponents[j]);
				TArray<int> Indexes = TArray<int>();
				Indexes.Add(0);
				Indexes.Add(CurrentComp.GetLastSplinePointIndex());
				for(int k = 0; k < Indexes.Num(); k++)
				{
					FSplineAttachPoint NewSplinePoint = FSplineAttachPoint();

					NewSplinePoint.OtherSpline = CurrentComp;
					NewSplinePoint.OtherSplineSide =  ESplineAttachSide::End;
					if(Indexes[k] == 0)
						NewSplinePoint.OtherSplineSide = ESplineAttachSide::Start;
					NewSplinePoint.Location = CurrentComp.GetLocationAtSplinePoint(Indexes[k], ESplineCoordinateSpace::World);
					NewSplinePoint.Tangent = CurrentComp.GetTangentAtSplinePoint(Indexes[k], ESplineCoordinateSpace::World);
					
					FoundPoints.Add(NewSplinePoint);
				}
			}

			// Spline attach points
			TArray<UActorComponent> SplineAttachPointComponents = AllActors[i].GetComponentsByClass(USplineAttachPointComponent::StaticClass());
			for(int j = 0; j < SplineAttachPointComponents.Num(); j++)
			{
				USplineAttachPointComponent CurrentComp = Cast<USplineAttachPointComponent>(SplineAttachPointComponents[j]);
				for(int k = 0; k < CurrentComp.AttachPoints.Num(); k++)
				{
					FSplineAttachPoint NewSplinePoint = FSplineAttachPoint();
					NewSplinePoint.AttachPoint = CurrentComp;
					NewSplinePoint.AttachPointIndex = k;
					NewSplinePoint.Location = CurrentComp.Owner.ActorTransform.TransformPosition(CurrentComp.AttachPoints[k].Location);
					NewSplinePoint.Tangent = CurrentComp.Owner.ActorTransform.TransformVector(CurrentComp.AttachPoints[k].Rotation.ForwardVector);
					FoundPoints.Add(NewSplinePoint);
				}
			}
		}

		return FoundPoints;
	}

	UFUNCTION()
	FSplineAttachPoint GetClosestAttachPoint(TArray<FSplineAttachPoint> AttachPoints, FVector WorldPosition) const
	{
		float CurrentLowestDistance = 100000000;
		FSplineAttachPoint ClosestPoint = FSplineAttachPoint();
		for(int i = 0; i < AttachPoints.Num(); i++)
		{
			float dist = AttachPoints[i].Location.Distance(WorldPosition);
			
			if(dist == 0)
				continue;
			
			if(AttachPoints[i].OtherSpline == this)
				continue;

			if(dist > CurrentLowestDistance)
				continue;

			CurrentLowestDistance = dist;
			ClosestPoint = AttachPoints[i];
		}
		return ClosestPoint;
	}

	UFUNCTION()
	void SnapSplineSideToAttachPoint(FSplineAttachPoint AttachPoint, ESplineAttachSide Side)
	{
		int Index = 0;
		if (Side == ESplineAttachSide::End)
			Index = GetLastSplinePointIndex();
		FVector Tangent = AttachPoint.Tangent;

		if (AttachPoint.OtherSpline != nullptr) // Spline
		{
			if (Side == AttachPoint.OtherSplineSide)
			{
				Tangent *= -1.0f;
			}
		}
		else // Attachpoint
		{
			if (Side == ESplineAttachSide::End)
			{
				Tangent *= -1.0f;
			}
		}

		SetLocationAtSplinePoint(Index, AttachPoint.Location, ESplineCoordinateSpace::World, true);
		SetTangentAtSplinePoint(Index, Tangent, ESplineCoordinateSpace::World, true);
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable, CallInEditor, Category = "Spline")
	void SnapToNearbyAttachPoints()
	{
		auto AttachPoints = GetAllAttachPoints();
		
		for (int i = 0; i < AttachPoints.Num(); i++)
		{
			System::DrawDebugPoint(AttachPoints[i].Location, 50, FLinearColor::White, 1.0f);
		}

		TArray<int> Indexes = TArray<int>();
		Indexes.Add(0);
		Indexes.Add(GetLastSplinePointIndex());
		for (int i = 0; i < Indexes.Num(); i++)
		{
			FVector Location = GetLocationAtSplinePoint(Indexes[i], ESplineCoordinateSpace::World);
			auto AttachPoint = GetClosestAttachPoint(AttachPoints, Location);
			System::DrawDebugPoint(AttachPoint.Location, 100, FLinearColor::Red, 1.0f);

			if ((AttachPoint.AttachPoint != nullptr || AttachPoint.OtherSpline != nullptr))
			{
				if (Location.Distance(AttachPoint.Location) < 100)
				{
					SnapSplineSideToAttachPoint(AttachPoint, i == 0 ? ESplineAttachSide::Start : ESplineAttachSide::End);
					System::DrawDebugArrow(Location, AttachPoint.Location, 500, FLinearColor::Green, 1.0f, 2.0f);
				}
				else
				{
					System::DrawDebugArrow(Location, AttachPoint.Location, 500, FLinearColor::Red, 1.0f, 2.0f);
				}
			}
		}

		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		if (HazeOwner != nullptr)
		{
			HazeOwner.ExecuteConstructionScript();
		}
	}


	UPROPERTY(Category = "Spline")
	bool AutoTangents = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (IsClosedLoop())
        {
            FHazeSplineConnection EndOfSplineConnection;
            EndOfSplineConnection.ExitSpline = this;
            EndOfSplineConnection.DistanceOnEntrySpline = GetSplineLength();
            EndOfSplineConnection.DistanceOnExitSpline = 0.f;
            EndOfSplineConnection.bCanEnterGoingForward = true;
            EndOfSplineConnection.bCanEnterGoingBackward = false;
            EndOfSplineConnection.bExitForwardOnSpline = true;
            AddSplineConnection(EndOfSplineConnection);

            FHazeSplineConnection StartOfSplineConnection;
            StartOfSplineConnection.ExitSpline = this;
            StartOfSplineConnection.DistanceOnEntrySpline = 0.f;
            StartOfSplineConnection.DistanceOnExitSpline = GetSplineLength();
            StartOfSplineConnection.bCanEnterGoingForward = false;
            StartOfSplineConnection.bCanEnterGoingBackward = true;
            StartOfSplineConnection.bExitForwardOnSpline = false;
            AddSplineConnection(StartOfSplineConnection);
        }
	}

	UFUNCTION(BlueprintOverride)
	void BP_UpdateSpline()
	{
		ShowTangents = true;
		if(AutoTangents)
		{
			ShowTangents = false;
			TArray<FVector> AllSplineLocations;
			for(int i = 0; i < this.NumberOfSplinePoints; i++ )
			{
				FVector PointLocation = this.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::Local);
				AllSplineLocations.Add(PointLocation);
			}
			
			TArray<FSplinePoint> Points;
			int PointCount = AllSplineLocations.Num();
			for(int i = 0; i < PointCount; i++ )
			{
				// Get next and previous indexes
				int NextIndex = 0;
				int PreviousIndex = 0;
				FVector ArriveTangent = FVector(0,0,0);
				FVector LeaveTangent = FVector(0,0,0);
				
				// First and last tangent
				if(!this.IsClosedLoop() && (i == 0 || i == PointCount-1))
				{
					if(PointCount > 2)
					{
						if(i == 0)
						{
							FVector Current = AllSplineLocations[i+0];
							FVector Next = AllSplineLocations[i+1];
							FVector NextNext = AllSplineLocations[i+2];

							LeaveTangent = GetTangentFromLocations(Current, Next, NextNext);
							float dist = Current.Distance(Next) * 0.25;
							FVector TangentLocation = Next + LeaveTangent * dist;
							LeaveTangent = TangentLocation - Current;
							ArriveTangent = LeaveTangent;
						}
						if(i == PointCount-1)
						{
							FVector Current = AllSplineLocations[i-0];
							FVector Previous = AllSplineLocations[i-1];
							FVector PreviousPrevious = AllSplineLocations[i-2];

							ArriveTangent = GetTangentFromLocations(Current, Previous, PreviousPrevious);
							float dist = Current.Distance(Previous) * 0.25;
							FVector TangentLocation = Previous + ArriveTangent * dist;
							ArriveTangent = -(TangentLocation - Current);
							LeaveTangent = ArriveTangent;
						}
					}
				}
				else
				{
					if(this.IsClosedLoop())
					{
						if(i == PointCount - 1)
						{
							NextIndex = 0;
							PreviousIndex = i - 1;
						}
						else if(i == 0)
						{
							NextIndex = i + 1;
							PreviousIndex = PointCount - 1;
						}
						else
						{
							NextIndex = i + 1;
							PreviousIndex = i - 1;
						}
					}
					else
					{
						NextIndex = i + 1;
						PreviousIndex = i - 1;
					}
					
					// Get spline positions
					FVector Previous = AllSplineLocations[PreviousIndex];
					FVector Current = AllSplineLocations[i];
					FVector Next = AllSplineLocations[NextIndex];

					// Calculate tangent angles
					LeaveTangent = GetTangentFromLocations(Previous, Current, Next);

					// Scale tangents to prevent over/under-shooting
					float DistanceToPrevious = Current.Distance(Previous);
					float DistanceToNext = Current.Distance(Next);
					
					ArriveTangent = -LeaveTangent * DistanceToPrevious;
					LeaveTangent = -LeaveTangent * DistanceToNext;
				}

				// Apply to spline
				auto point = MakeSplinePoint(AllSplineLocations[i], ArriveTangent, LeaveTangent, i,
				this.GetRotationAtSplinePoint(i, ESplineCoordinateSpace::Local), this.GetScaleAtSplinePoint(i));
				Points.Add(point);
			}

			this.ClearSplinePoints();
			this.AddPoints(Points);
			this.UpdateSpline();
			this.bSplineHasBeenEdited = true;
		}
	}

	FVector GetTangentFromLocations(FVector Previous, FVector Current, FVector Next)
	{
		FVector Average = (Previous + Next) * 0.5;
		FVector Delta = Current - Average;
		FVector LeaveTangentLocation = Next + Delta;

		FVector LeaveTangent = Current - LeaveTangentLocation;
		LeaveTangent.Normalize();

		return LeaveTangent;
	}

	UFUNCTION()
	void CopyFromOtherSpline(UHazeSplineComponent Other)
	{
		this.AutoTangents = Other.AutoTangents;
		this.SetClosedLoop(Other.IsClosedLoop());

		TArray<FSplinePoint> Points;
		for(int i = 0; i < Other.NumberOfSplinePoints; i++ )
		{
			FVector Position = Other.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::Local);
			FVector ArriveTangent = Other.GetArriveTangentAtSplinePoint(i, ESplineCoordinateSpace::Local);
			FVector LeaveTangent = Other.GetLeaveTangentAtSplinePoint(i, ESplineCoordinateSpace::Local);
			FRotator Rotation = Other.GetRotationAtSplinePoint(i, ESplineCoordinateSpace::Local);
			FVector Scale = Other.GetScaleAtSplinePoint(i);

			Points.Add(MakeSplinePoint(Position, ArriveTangent, LeaveTangent, i, Rotation, Scale));
		}

		this.SetWorldTransform(Other.GetWorldTransform());

		this.ClearSplinePoints();
		this.AddPoints(Points);
		this.UpdateSpline();
		this.bSplineHasBeenEdited = true;
	}

	/*
	 *	Get an array of transforms for this UHazeSplineComponent at N intervals,
	 */
	UFUNCTION()
	TArray<FTransform> TransformsAlongSpline(int Intervals)
	{
		TArray<FTransform> Transforms;
		float DistanceBetweenEach = GetSplineLength() / float(Intervals - 1);
		for (int Index = 0; Index < Intervals; Index++)
		{
			float Distance = float(Index) * DistanceBetweenEach;
			FRotator NewRotaiton = GetRotationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::Local);
			FVector NewLocation = GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::Local);
			Transforms.Add(FTransform(NewRotaiton, NewLocation, FVector(1, 1, 1)));
		}
		return Transforms;
	}

	UFUNCTION()
	TArray<FTransform> TransformsAtInterval(int Intervals)
	{
		// @Todo AndreasR - Not sure if this acts as one would expect, but same behaviour as the Blueprint version,

		TArray<FTransform> Transforms;

		int LastIndex = GetLastSplinePointIndex();

		FRotator EndRotation = GetRotationAtSplinePoint(LastIndex, ESplineCoordinateSpace::Local);
		FVector StartLocation = GetLocationAtSplinePoint(0, ESplineCoordinateSpace::Local);
		FVector EndLocation = GetLocationAtSplinePoint(LastIndex, ESplineCoordinateSpace::Local);

		float Distance = StartLocation.Distance(EndLocation);
		FVector Direction = (EndLocation - StartLocation).GetSafeNormal();

		for (int Index = 0; Index < Intervals; Index++)
		{
			FVector Position = (Direction * float(Index)) * Distance;

			Transforms.Add(FTransform(
				EndRotation,
				Position,
				FVector(1, 1, 1)
			));
		}

		return Transforms;
	}

	UFUNCTION(BlueprintPure)
	int GetLastSplinePointIndex() property
	{
		return NumberOfSplinePoints - 1;
	}

	FSplinePoint MakeSplinePoint(FVector Position, FVector ArriveTangent, FVector LeaveTangent, float index, FRotator Rotation, FVector Scale)
	{
		FSplinePoint NewSplinePoint = FSplinePoint();
		NewSplinePoint.ArriveTangent = ArriveTangent;
		NewSplinePoint.LeaveTangent = LeaveTangent;
		NewSplinePoint.Position = Position;
		NewSplinePoint.InputKey = index;
		NewSplinePoint.Type = ESplinePointType::CurveCustomTangent;
		NewSplinePoint.Rotation = Rotation;
		NewSplinePoint.Scale = Scale;
		return NewSplinePoint;
	}
	
    void DebugDrawVector(FVector Location, FVector Vector, int color = 0)
    {
        int Color1 = color + 1;
        int Color2 = color + 2;
        int Color3 = color + 3;
        FVector vec = Vector;
        System::DrawDebugLine(Location, Location + vec, FLinearColor((Color1 % 3)/2.0, (Color2 % 3)/2.0, (Color3 % 3)/2.0, 0), 0, 2);
    }

	UFUNCTION(BlueprintPure, Category = "Spline")
	FTransform StepTransformAlongSpline(FTransform TransformToStep, float StepSize = 1000.f) const
	{
 		float DistAlongSpline = 0.f;
 		FVector LocationOnSpline = FVector::ZeroVector;
		FindDistanceAlongSplineAtWorldLocation(
 			TransformToStep.GetLocation(),
 			LocationOnSpline,
 			DistAlongSpline
 		);

 		const float DistToSplinePoint_SQ = (LocationOnSpline - TransformToStep.GetLocation()).SizeSquared();

 		FTransform DesiredTransform;
 		if (DistToSplinePoint_SQ > FMath::Square(StepSize) && DistToSplinePoint_SQ > KINDA_SMALL_NUMBER)
 		{
 			// Get us to the spline before we actually start following the spline. 
 			DesiredTransform.SetLocation(LocationOnSpline);
			const FVector TowardsTarget = LocationOnSpline - TransformToStep.GetLocation();
			const FQuat NewQuat = Math::MakeQuatFromX(TowardsTarget);
			DesiredTransform.SetRotation(NewQuat); 
 		}
 		else 
 		{
			// Wrap around (or clamp) if we happen to overshoot
			float DesiredDistanceAlongSpline = DistAlongSpline + StepSize;
			if (DesiredDistanceAlongSpline > GetSplineLength())
			{
				if (IsClosedLoop())
				{
					DesiredDistanceAlongSpline %= GetSplineLength();
				}
				else
				{
					DesiredDistanceAlongSpline = GetSplineLength();
				}
			}

			DesiredTransform = GetTransformAtDistanceAlongSpline(
				DesiredDistanceAlongSpline,
				ESplineCoordinateSpace::World,
				bUseScale = false
			);
 		}

		DesiredTransform.SetScale3D(TransformToStep.GetScale3D());
		return DesiredTransform;
	}
}
