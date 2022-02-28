event void FTownDoorUnlockEventSignature();
event void FTownDoorPinStateChangedEventSignature(bool IsPinned);

UCLASS(abstract)
class ATownDoorLock : AHazeactor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	AActor BlueWheelDirection;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent RedPin;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BluePin;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BluePinDesiredPosition;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent RedPinDesiredPosition;

	FVector BluePinOriginalPosition;
	FVector RedPinOriginalPosition;
	float TimeSpentInAlignedPosition = 0;
	
	UPROPERTY(Category = "Lock Events")
	FTownDoorPinStateChangedEventSignature OnRedPinChangedState;

	UPROPERTY(Category = "Lock Events")
	FTownDoorPinStateChangedEventSignature OnBluePinChangedState;

	UPROPERTY()
	AActor RedWheelDirection;

	UPROPERTY(DefaultComponent)
	UArrowComponent AlignDirection01;

	UPROPERTY(DefaultComponent)
	UArrowComponent AlignDirection02;

	UPROPERTY(Category = "Lock Events")
	FTownDoorUnlockEventSignature OnUnlocked;

	bool bHasUnlocked = false;
	 
	bool bRedPinIsAligned = false;
	bool bBluePinIsAligned = false;

	bool bBluePinWasAlignedLastFrame = false;
	bool bRedPinWasAlignedLastFrame = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BluePinOriginalPosition = BluePin.RelativeLocation;
		RedPinOriginalPosition = RedPin.RelativeLocation;

		BluePinDesiredPosition.SetHiddenInGame(true);
		RedPinDesiredPosition.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CheckIsAligned();
		if (bRedPinIsAligned && bBluePinIsAligned && !bHasUnlocked)
		{
			TimeSpentInAlignedPosition += DeltaTime;

			if (TimeSpentInAlignedPosition > 1)
			{
				OnUnlocked.Broadcast();
				bHasUnlocked = true;
			}
		}

		else
		{
			TimeSpentInAlignedPosition = 0;
		}

		UpdatePinPosition(DeltaTime);
	}

	void UpdatePinPosition(float DeltaTime)
	{
		// UpdateRedPin
		FVector BluePinDesiredLocation;
		if (bBluePinIsAligned)
		{
			BluePinDesiredLocation = FMath::Lerp(BluePin.RelativeLocation, BluePinDesiredPosition.RelativeLocation, DeltaTime * 20);
		}

		else
		{
			BluePinDesiredLocation = FMath::Lerp(BluePin.RelativeLocation, BluePinOriginalPosition, DeltaTime  * 20);
		}

		BluePin.SetRelativeLocation(BluePinDesiredLocation);


		FVector RedPinDesiredLocation;
		// UpdateBluePin
		if (bRedPinIsAligned)
		{
			RedPinDesiredLocation = FMath::Lerp(RedPin.RelativeLocation, RedPinDesiredPosition.RelativeLocation, DeltaTime  * 20);
		}

		else
		{
			RedPinDesiredLocation = FMath::Lerp(RedPin.RelativeLocation, RedPinOriginalPosition, DeltaTime  * 20);
		}

		RedPin.SetRelativeLocation(RedPinDesiredLocation);
	}

	void CheckIsAligned()
	{
		float BlueDotToAlignDirection01 = AlignDirection01.WorldRotation.ForwardVector.DotProduct(BlueWheelDirection.ActorForwardVector);
		float RedDotToAlignDirection01 = AlignDirection01.WorldRotation.ForwardVector.DotProduct(RedWheelDirection.ActorForwardVector);

		float BlueDotDirectionToAlignDirection02 = AlignDirection02.WorldRotation.ForwardVector.DotProduct(BlueWheelDirection.ActorForwardVector);
		float RedDotDirectionToAlignDirection02 = AlignDirection02.WorldRotation.ForwardVector.DotProduct(RedWheelDirection.ActorForwardVector);

		bBluePinIsAligned = false;
		bRedPinIsAligned = false;

		if(BlueDotToAlignDirection01 > 0.98f || BlueDotDirectionToAlignDirection02 > 0.98f)
		{
			bBluePinIsAligned = true;
		}
		
		if (RedDotToAlignDirection01 > 0.98f || RedDotDirectionToAlignDirection02 > 0.98f)
		{
			bRedPinIsAligned = true;
		}

		if (bRedPinIsAligned && !bRedPinWasAlignedLastFrame)
		{
			OnRedPinChangedState.Broadcast(true);
		}
		if (!bRedPinIsAligned && bRedPinWasAlignedLastFrame)
		{
			OnRedPinChangedState.Broadcast(false);
		}
		if (bBluePinIsAligned && !bBluePinWasAlignedLastFrame)
		{
			OnBluePinChangedState.Broadcast(true);
		}
		if (!bBluePinIsAligned && bBluePinWasAlignedLastFrame)
		{
			OnBluePinChangedState.Broadcast(false);
		}

		bRedPinWasAlignedLastFrame = bRedPinIsAligned;
		bBluePinWasAlignedLastFrame = bBluePinIsAligned;
	}
}