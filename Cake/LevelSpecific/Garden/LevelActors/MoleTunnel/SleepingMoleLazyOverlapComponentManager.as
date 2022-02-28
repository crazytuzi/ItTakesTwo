import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;

event void FOnSleepingMoleBeginOverlapSignature(UPrimitiveComponent Shape, AHazePlayerCharacter Player);
event void FOnSleepingMoleEndOverlapSignature(UPrimitiveComponent Shape, AHazePlayerCharacter Player);

struct FSleepingMoleLazCollisionShape
{
	UPROPERTY()
	TArray<AHazePlayerCharacter> OverlappingPlayers;

	UPROPERTY()
	UPrimitiveComponent Shape;

	UPROPERTY()
	FOnSleepingMoleBeginOverlapSignature OnBeginOverlap;
	
	UPROPERTY()
	FOnSleepingMoleEndOverlapSignature OnEndOverlap;
	
}

#if EDITOR
class USleepingMoleLazyOverlapComponentManagerVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = USleepingMoleLazyOverlapComponentManager::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        auto ManagerComp = Cast<USleepingMoleLazyOverlapComponentManager>(Component);
		FVector WorldLocation = ManagerComp.GetWorldLocation();
		DrawWireSphere(WorldLocation, ManagerComp.DetectionRange, FLinearColor::Red, 3.0f, 12);
    }   
}
#endif

class USleepingMoleLazyOverlapComponentManager : USceneComponent
{
	UPROPERTY()
	float DetectionRange = 1200;

	UPROPERTY(EditConst, BlueprintReadOnly)
	TArray<FSleepingMoleLazCollisionShape> Shapes;

	private float ActorDetectionSize = 0;
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

		Shapes.Add(FSleepingMoleLazCollisionShape());
		FSleepingMoleLazCollisionShape& NewShape = Shapes[Shapes.Num() - 1];
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

		Shapes.Add(FSleepingMoleLazCollisionShape());
		FSleepingMoleLazCollisionShape& NewShape = Shapes[Shapes.Num() - 1];
		NewShape.Shape = Shape;
		NewShape.OnEndOverlap.AddUFunction(FunctionOwner, FunctionName);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Shapes.Num() > 0)
		{
			TArray<AHazePlayerCharacter> ValidPlayerCapsules;
			if(PlayersInRange(ValidPlayerCapsules))
			{
				for(int i = 0; i < Shapes.Num(); ++i)
				{
					UpdateOverlap(Shapes[i], ValidPlayerCapsules);
				}
			}
		}
	}

	void UpdateOverlap(FSleepingMoleLazCollisionShape& ShapeData, const TArray<AHazePlayerCharacter>& ValidPlayers)
	{
		TArray<AHazePlayerCharacter> WantedOverlappingPlayers;
		for(int i = 0; i < ValidPlayers.Num(); ++i)
		{
			// In Range
			if(ShapeData.Shape.CollisionEnabled != ECollisionEnabled::NoCollision
				&& ShapeData.Shape.CollisionProfileName != n"NoCollision")
			{
				if(Trace::ComponentOverlapComponent(
					ValidPlayers[i].CapsuleComponent,
					ShapeData.Shape,
					ShapeData.Shape.WorldLocation,
					ShapeData.Shape.ComponentQuat,
					bTraceComplex = false
				))
				{
					WantedOverlappingPlayers.Add(ValidPlayers[i]);
				}
			}
		}

			
		for(int i = ShapeData.OverlappingPlayers.Num() - 1; i >= 0; --i)
		{
			if(!WantedOverlappingPlayers.Contains(ShapeData.OverlappingPlayers[i]))
			{
				ShapeData.OnEndOverlap.Broadcast(ShapeData.Shape, ShapeData.OverlappingPlayers[i]);
				ShapeData.OverlappingPlayers.RemoveAtSwap(i);
			}
		}

		for(int i = 0; i < WantedOverlappingPlayers.Num(); ++i)
		{
			if(!ShapeData.OverlappingPlayers.Contains(WantedOverlappingPlayers[i]))
			{
				ShapeData.OnBeginOverlap.Broadcast(ShapeData.Shape, WantedOverlappingPlayers[i]);
				ShapeData.OverlappingPlayers.Add(WantedOverlappingPlayers[i]);
			}
		}
	}

	private bool PlayersInRange(TArray<AHazePlayerCharacter>& ValidPlayers) const
	{
		auto& Players = Game::GetPlayers();
		FVector CurrentWorldLocation = GetWorldLocation();
		for(auto Player : Players)
		{
			const float CollisionSize = Player.CapsuleComponent.GetCapsuleRadius();
			if(CurrentWorldLocation.DistSquared(Player.GetActorLocation()) - FMath::Square(DetectionRange) <= 0)
				ValidPlayers.Add(Player);
		}
		
		return ValidPlayers.Num() > 0;
	}
}
