import Cake.SteeringBehaviors.BoidShapeType;

class UBoidShapeComponent : USceneComponent
{
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(Shape == EBoidObstacleShape::Capsule)
		{
			Radius = FMath::Clamp(Radius, 0.0f, HalfHeight);
			//HalfHeight -= Radius;
			HalfHeight = FMath::Max(0.0f, HalfHeight);
		}
		else if(Shape == EBoidObstacleShape::Sphere)
		{
			Radius = FMath::Max(Radius, 0.0f);
		}
	}
#if TEST
	default PrimaryComponentTick.bStartWithTickEnabled = true;
#endif // TEST
	
	UPROPERTY()
	EBoidObstacleShape Shape = EBoidObstacleShape::Sphere;

	UPROPERTY(meta = (EditCondition="Shape == (EBoidObstacleShape::Sphere || EBoidObstacleShape::Capsule)", EditConditionHides))
	float Radius = 200;

	UPROPERTY(meta = (EditCondition="Shape == EBoidObstacleShape::Capsule", EditConditionHides))
	float HalfHeight = 400;

	UPROPERTY(meta = (EditCondition="bUseVirtualFloor == true", EditConditionHides))
	float VirtualFloorHeight = 0.0f;

	UPROPERTY(Category = Debug, meta = (EditCondition="bUseVirtualFloor == true", EditConditionHides))
	int VirtualFloorNumLines = 50;

	UPROPERTY(Category = Debug, meta = (EditCondition="bUseVirtualFloor == true", EditConditionHides))
	FLinearColor VirtualFloorColor = FLinearColor::Red;

	FVector GetShapeCenterLocation() const property
	{
		if(!bUseVirtualFloor)
			return WorldLocation;

		if(Shape == EBoidObstacleShape::Sphere)
		{
			const float LocalFloorHeight = Radius - VirtualFloorHeight;
			const float LocalFloorHeightHalf = LocalFloorHeight * 0.5f;
			return WorldLocation + FVector(0.0f, 0.0f, Radius - LocalFloorHeightHalf);
		}
		else if(Shape == EBoidObstacleShape::Capsule)
		{
			const float LocalFloorHeight = HalfHeight - VirtualFloorHeight;
			const float LocalFloorHeightHalf = LocalFloorHeight * 0.5f;
			return WorldLocation + FVector(0.0f, 0.0f, HalfHeight - LocalFloorHeightHalf);
		}
		
		return WorldLocation;
	}

	// Everything below the floor will be considered not inside the shape.
	UPROPERTY()
	bool bUseVirtualFloor = false;

	bool IsPointOverlapping(FVector Point) const
	{
		bool bIsAboveFloor = IsPointAboveFloor(Point);

		if(Shape == EBoidObstacleShape::Sphere)
		{
			const float DistSq = WorldLocation.DistSquared(Point);
			const bool bIsOverlapping = DistSq < FMath::Square(Radius);
			return bIsOverlapping && bIsAboveFloor;
		}
		else if(Shape == EBoidObstacleShape::Capsule)
		{
			FHazeIntersectionResult Results;
			FHazeIntersectionCapsule Capsule;
			Capsule.MakeUsingOrigin(WorldLocation, FRotator::ZeroRotator, HalfHeight, Radius);
			Results.QueryCapsulePoint(Capsule, Point);
			return Results.bIntersecting && bIsAboveFloor;
		}

		// How did we get here?
		devEnsure(false);

		return false;
	}

	private bool IsPointAboveFloor(FVector Point) const
	{
		if(!bUseVirtualFloor)
			return true;

		const FVector FloorLoc = VirtualFloorLocation;
		const FVector DirectionToPoint = (Point - FloorLoc).GetSafeNormal();
		const float FloorDot = DirectionToPoint.DotProduct(FVector::UpVector);

		return FloorDot > 0.0f;
	}

	FVector GetRandomPointInsideShape() const property
	{
		FVector RandomVector = GetRandomVectorWithOffset();
		

		if(Shape == EBoidObstacleShape::Sphere)
		{
			RandomVector.X *= Radius;
			RandomVector.Y *= Radius;
			RandomVector.Z *= Radius;
		}
		else if(Shape == EBoidObstacleShape::Capsule)
		{
			RandomVector.Z *= HalfHeight;
			RandomVector.X *= Radius;
			RandomVector.Y *= Radius;
		}

		RandomVector = WorldLocation + RandomVector;

		return RandomVector;
	}

	float GetVirtualFloorRandomOffset() const property
	{
		if(!bUseVirtualFloor)
			return 0.0f;

		float Height = Shape == EBoidObstacleShape::Capsule ? (HalfHeight) : Radius;

		const float FloorOffset = Height + VirtualFloorHeight;
		const float Fraction = FloorOffset / Height;
		return Fraction;
	}

	FVector GetRandomVectorWithOffset() const
	{
		FVector RandomVector = FVector::ZeroVector;

		do
		{
			RandomVector.X = FMath::RandRange(-1.0f, 1.0f);
			RandomVector.Y = FMath::RandRange(-1.0f, 1.0f);
			RandomVector.Z = FMath::RandRange(-1.0f + VirtualFloorRandomOffset, 1.0f);
		} while(RandomVector.Size() > 1.0f);

		return RandomVector;
	}

	void DrawShape()
	{
		if(Shape == EBoidObstacleShape::Sphere)
		{
			System::DrawDebugSphere(WorldLocation, Radius, 12, VisualizerColor, 0, VisualizerThickness);
		}
		else if(Shape == EBoidObstacleShape::Capsule)
		{
			System::DrawDebugCapsule(WorldLocation, HalfHeight, Radius, FRotator::ZeroRotator, VisualizerColor, 0, VisualizerThickness);
		}

		if(!bUseVirtualFloor)
			return;

		const float BoxSize = Radius * 1.4f;
		const float BoxHeight = 10.0f;
		const FVector BoxExtents(BoxSize, BoxSize, BoxHeight);
		const FVector VirtualFloorLoc = VirtualFloorLocation;
		System::DrawDebugBox(VirtualFloorLoc, BoxExtents, VirtualFloorColor, FRotator::ZeroRotator, 10.0f);

		const float SpaceBetweenLines = BoxSize / float(VirtualFloorNumLines);
		const float BoxSizeHalf = BoxSize * 0.5f;

		for(int i = 1; i < (VirtualFloorNumLines * 2); ++i)
		{
			const float X = (-BoxSize) + (i * SpaceBetweenLines);
			const FVector Start = VirtualFloorLoc + FVector(X, BoxSize, 0);
			const FVector End = VirtualFloorLoc + FVector(X, -BoxSize, 0);
			System::DrawDebugLine(Start, End, VirtualFloorColor, 0, 10.0f);
		}
	}

	FVector GetVirtualFloorLocation() const property
	{
		return WorldLocation + FVector(0.0f, 0.0f, VirtualFloorHeight);
	}

	UFUNCTION()
	void Test_Test()
	{
		//bool bIsAboveFloor = IsPointOverlapping(Game::GetCody().ActorLocation);
		//PrintToScreen("bIsAboveFloor " + bIsAboveFloor);
		//System::DrawDebugSphere(RandomPointInsideShape, 300.0f, 12, FLinearColor::Green, 2);
	}

#if TEST
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bAlwaysDrawShape)
		{
			DrawShape();
		}

	}
#endif // TEST

	UPROPERTY(Category = Debug)
	FLinearColor VisualizerColor = FLinearColor::Green;
	UPROPERTY(Category = Debug)
	float VisualizerThickness = 5;
	UPROPERTY(Category = Debug)
	bool bAlwaysDrawShape = false;
}
