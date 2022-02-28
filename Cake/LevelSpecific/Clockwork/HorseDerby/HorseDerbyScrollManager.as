import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyScrollingBackgroundActor;

class AHorseDerbyScrollManager : AHazeActor
{
	UPROPERTY(Category = "Setup")
	TArray<TSubclassOf<AHorseDerbyScrollingBackgroundActor>> ScrollActorTypes;

	UPROPERTY(Category = "Setup")
	TArray<AHorseDerbyScrollingBackgroundActor> ScrollActorPool;

	// UPROPERTY(Category = "Setup")
	TArray<AHorseDerbyScrollingBackgroundActor> ActiveScrollActors;
	
	UPROPERTY(Category = "Setup")
	float MoveSpeed = 180.f;

	FHazeAcceleratedFloat AccelMoveSpeed;

	UPROPERTY(Category = "Setup")
	int MaxScrollActors = 4;

	UPROPERTY(Category = "Setup")
	bool bDisable;

	float LengthActivation = 2000.f;

	float DeactivationDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bDisable)
			DisableActor(this);
		else
		{
			DeactivationDistance = LengthActivation * MaxScrollActors;

			for (AHorseDerbyScrollingBackgroundActor ScrollActor : ScrollActorPool)
				ScrollActor.DisableActor(this);

			CreatePieces();
		}
	}

	void CreatePieces()
	{
		for (int i = 0; i < MaxScrollActors; i++)
		{
			FVector OffsetLoc = ActorForwardVector * (i * LengthActivation);
			FVector ActivateLocation = ActorLocation + OffsetLoc;
			ActivatePiece(FindNextPiece(), ActivateLocation);
		}
	}

	UFUNCTION()
	void MoveAndCheckScrollActors(float DeltaTime)
	{
		int Index = 0;

		AHorseDerbyScrollingBackgroundActor PieceToAdd = nullptr;
		AHorseDerbyScrollingBackgroundActor PieceToDeactivate = nullptr;

		AccelMoveSpeed.AccelerateTo(MoveSpeed, 1.2f, DeltaTime);

		for (AHorseDerbyScrollingBackgroundActor ScrollActor : ActiveScrollActors)
		{
			FVector Movement = ActorForwardVector * (AccelMoveSpeed.Value * DeltaTime);
			FVector NextLoc = ScrollActor.ActorLocation + Movement;
			ScrollActor.SetActorLocation(NextLoc);

			float Distance = (ScrollActor.ActorLocation - ActorLocation).Size();

			if (Distance >= DeactivationDistance)
				PieceToDeactivate = ScrollActor;

			if (Index == ActiveScrollActors.Num() - 1)
			{
				if (Distance >= LengthActivation)
					PieceToAdd = FindNextPiece();
			}

			Index++;

			if (PieceToAdd != nullptr && PieceToDeactivate != nullptr)
				break;
		}

		if (PieceToAdd != nullptr && PieceToDeactivate != nullptr)
		{
			ActivatePiece(PieceToAdd, ActorLocation);
			DeactivatePiece(PieceToDeactivate);
		}
	}

	UFUNCTION()
	AHorseDerbyScrollingBackgroundActor FindNextPiece()
	{
		int RandomIndex = FMath::RandRange(0, ScrollActorPool.Num() - 1);
		return ScrollActorPool[RandomIndex];
	}

	void ActivatePiece(AHorseDerbyScrollingBackgroundActor ScrollActor, FVector ActivationLocation)
	{
		ScrollActor.EnableActor(this);
		ActiveScrollActors.Add(ScrollActor);
		ScrollActorPool.Remove(ScrollActor);
		ScrollActor.SetActorLocation(ActivationLocation);
	}

	void DeactivatePiece(AHorseDerbyScrollingBackgroundActor ScrollActor)
	{
		ScrollActorPool.Add(ScrollActor);	
		ActiveScrollActors.Remove(ScrollActor);
		ScrollActor.DisableActor(this);
	}
}