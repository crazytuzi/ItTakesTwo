import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;

event void FOnWheelBoatBeginOverlapSignature(UPrimitiveComponent Shape, AWheelBoatActor Boat);
event void FOnWheelBoatEndOverlapSignature(UPrimitiveComponent Shape, AWheelBoatActor Boat);

struct FWheelBoatLazyCollisionShape
{
	bool bIsOverlapping = false;

	UPROPERTY()
	UPrimitiveComponent Shape;

	UPROPERTY()
	FOnWheelBoatBeginOverlapSignature OnBeginOverlap;
	
	UPROPERTY()
	FOnWheelBoatEndOverlapSignature OnEndOverlap;
	
}

class UPirateEnemyComponent : UActorComponent
{
	UPROPERTY(EditConst, BlueprintReadOnly)
	TArray<FWheelBoatLazyCollisionShape> Shapes;

	USceneComponent RotationRoot;
	
	bool bFacePlayer = false;

	UPROPERTY(EditDefaultsOnly)
	bool bFacePlayerFromStart = false;

	bool bAlerted = false;

	private float ActorDetectionSize = 0;
	private AWheelBoatActor _WheelBoat;
	private float WheelBoatDetectionSize = 0;


UFUNCTION()
	void AddBeginOverlap(UPrimitiveComponent Shape, UObject FunctionOwner, FName FunctionName)
	{
		// Validation
	#if EDITOR
		if(!devEnsure(Shape.bGenerateOverlapEvents == false, GetName() + "s shape: " + Shape + "has GenerateOverlapEvents set to true. This component will hadle that so turn that of."))
			return;

		for(int i = Shapes.Num() - 1; i >= 0; --i)
		{	
			if(Shapes[i].Shape == nullptr)
			{
				Shapes.RemoveAtSwap(i);
			}
		}
	#endif

		for(int i = Shapes.Num() - 1; i >= 0; --i)
		{
			if(Shapes[i].Shape == Shape)
			{
				Shapes[i].OnBeginOverlap.AddUFunction(FunctionOwner, FunctionName);
				return;
			}
		}

		Shapes.Add(FWheelBoatLazyCollisionShape());
		FWheelBoatLazyCollisionShape& NewShape = Shapes[Shapes.Num() - 1];
		NewShape.Shape = Shape;
		NewShape.OnBeginOverlap.AddUFunction(FunctionOwner, FunctionName);
	}

	UFUNCTION()
	void AddEndOverlap(UPrimitiveComponent Shape, UObject FunctionOwner, FName FunctionName)
	{
		// Validation
	#if EDITOR
		if(!devEnsure(Shape.bGenerateOverlapEvents == false, GetName() + "s shape: " + Shape + "has GenerateOverlapEvents set to true. This component will hadle that so turn that of."))
			return;

		for(int i = Shapes.Num() - 1; i >= 0; --i)
		{	
			if(Shapes[i].Shape == nullptr)
			{
				Shapes.RemoveAtSwap(i);
			}
		}
	#endif


		for(int i = Shapes.Num() - 1; i >= 0; --i)
		{
			if(Shapes[i].Shape == Shape)
			{
				Shapes[i].OnEndOverlap.AddUFunction(FunctionOwner, FunctionName);
				return;
			}
		}

		Shapes.Add(FWheelBoatLazyCollisionShape());
		FWheelBoatLazyCollisionShape& NewShape = Shapes[Shapes.Num() - 1];
		NewShape.Shape = Shape;
		NewShape.OnEndOverlap.AddUFunction(FunctionOwner, FunctionName);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> FoundActors;
		Gameplay::GetAllActorsOfClass(AWheelBoatActor::StaticClass(), FoundActors);

		// validation
	#if EDITOR
		if(!devEnsure(FoundActors.Num() == 1, GetName() + " requires exactly 1 of WheelBoatActorWheelActor in the same level"))
			return;
	#endif

		_WheelBoat = Cast<AWheelBoatActor>(FoundActors[0]);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Shapes.Num() > 0)
		{
			if(BoatIsInsideRange())
			{
				for(int i = 0; i < Shapes.Num(); ++i)
				{
					UpdateOverlap(Shapes[i]);
				}
			}
		}
	}

	void UpdateOverlap(FWheelBoatLazyCollisionShape& ShapeData)
	{
		bool bWantsOverlapping = false;

		// In Range
		if(ShapeData.Shape.CollisionEnabled != ECollisionEnabled::NoCollision
			&& ShapeData.Shape.CollisionProfileName != n"NoCollision")
		{
			bWantsOverlapping = Trace::ComponentOverlapComponent(
				_WheelBoat.CapsuleComponent,
				ShapeData.Shape,
				ShapeData.Shape.WorldLocation,
				ShapeData.Shape.ComponentQuat,
				bTraceComplex = false
			);
		}

		if(bWantsOverlapping && !ShapeData.bIsOverlapping)
		{
			// When we leave is not equally important
			ShapeData.bIsOverlapping = true;
			ShapeData.OnBeginOverlap.Broadcast(ShapeData.Shape, _WheelBoat);
		}
		else if(!bWantsOverlapping && ShapeData.bIsOverlapping)
		{
			ShapeData.bIsOverlapping = false;
			ShapeData.OnEndOverlap.Broadcast(ShapeData.Shape, _WheelBoat);
		}
	}

	float GetBiggestDetectionRange() const property
	{
		float MaxRange = -1;
		for(int i = 0; i < Shapes.Num(); ++i)
		{
			auto ShapeData = Shapes[i].Shape.GetCollisionShape();
			if(ShapeData.IsSphere())
			{
				MaxRange = FMath::Max(MaxRange, ShapeData.GetSphereRadius());
			}
			else if(ShapeData.IsCapsule())
			{
				MaxRange = FMath::Max(MaxRange, ShapeData.GetCapsuleHalfHeight());
			}
			else if(ShapeData.IsBox())
			{
				FVector BoxSize = ShapeData.GetBox();
				MaxRange = FMath::Max(MaxRange, FMath::Max(BoxSize.Z, FMath::Max(BoxSize.X, BoxSize.Y)));
			}
		}

		return MaxRange;
	}

	private bool BoatIsInsideRange() const
	{
		float ShapesRange = GetBiggestDetectionRange() * 2;
		float BoatSize = _WheelBoat.CapsuleComponent.GetCapsuleHalfHeight();
		return Owner.GetActorLocation().DistSquared(_WheelBoat.GetActorLocation()) - FMath::Square(ShapesRange + BoatSize) <= 0;
	}

	AWheelBoatActor GetWheelBoat() const property
	{
		return _WheelBoat;
	}
}
