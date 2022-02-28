import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticBase;

struct FParentBlobKineticDoubleDoorRumbleData
{
	UPROPERTY()
	FVector OffsetMinAmount;

	UPROPERTY()
	FVector OffsetMaxAmount;

	UPROPERTY()
	FRuntimeFloatCurve OffsetSpeedInRelationToProgress;

	UPROPERTY()
	FVector RotationMinAmount;

	UPROPERTY()
	FVector RotationMaxAmount;

	UPROPERTY()
	FRuntimeFloatCurve RotationSpeedInRelationToProgress;

	FVector GenerateLocationOffset(float Scale) const
	{
		float RandomX = FMath::RandRange(OffsetMinAmount.X, OffsetMaxAmount.X);
		float RandomY = FMath::RandRange(OffsetMinAmount.Y, OffsetMaxAmount.Y);
		float RandomZ = FMath::RandRange(OffsetMinAmount.Z, OffsetMaxAmount.Z);
		return FVector(RandomX, RandomY, RandomZ) * Scale;
	}

	FRotator GenerateRotationOffset(float Scale) const
	{
		float RandomPitch = FMath::RandRange(RotationMinAmount.Y, RotationMaxAmount.Y);
		float RandomYaw = FMath::RandRange(RotationMinAmount.X, RotationMaxAmount.X);
		float RandomRoll = FMath::RandRange(RotationMinAmount.Z, RotationMaxAmount.Z);
		return FRotator(RandomPitch, RandomYaw, RandomRoll) * Scale;
	}
}

class AParentBlobKineticDoubleDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LeftDoor;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RightDoor;

	UPROPERTY(DefaultComponent, Attach = Root)
	UParentBlobKineticDoubleDoorComponent Interaction;

	UPROPERTY(Category = "Rumble")
	FParentBlobKineticDoubleDoorRumbleData LeftRumble;

	UPROPERTY(Category = "Rumble")
	FParentBlobKineticDoubleDoorRumbleData RightRumble;

	UPROPERTY(Category = "Open")
	FVector LeftOpenOffset;

	UPROPERTY(Category = "Open")
	FVector RightOpenOffset;

	UPROPERTY(EditConst)
	FTransform LeftInitalTransform;

	UPROPERTY(EditConst)
	FTransform RightInitalTransform;

	UPROPERTY(Category = "Events")
	FParentBlobKineticInteractionCompletedSignature OnDoorOpened;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
	{
		LeftInitalTransform = LeftDoor.RelativeTransform;
		RightInitalTransform = RightDoor.RelativeTransform;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Interaction.OnCompleted.AddUFunction(this, n"DoorOpened");
	}

	UFUNCTION(NotBlueprintCallable)
	void DoorOpened(FParentBlobKineticInteractionCompletedDelegateData CompleteData)
	{
		OnDoorOpened.Broadcast(CompleteData);
	}

	UFUNCTION()
	void Open()
	{
		Interaction.SetOpen(true, KINDA_SMALL_NUMBER);	
	}

	UFUNCTION()
	void Close()
	{
		Interaction.SetOpen(false, KINDA_SMALL_NUMBER);	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Interaction.bIsOpen)
		{
			Interaction.UpdateOpenClose(LeftDoor, LeftInitalTransform.Location, LeftOpenOffset, DeltaSeconds);
			Interaction.UpdateOpenClose(RightDoor, RightInitalTransform.Location, RightOpenOffset, DeltaSeconds);
		}
		else
		{
			Interaction.UpdateOffset(true, LeftDoor, LeftInitalTransform, LeftRumble, DeltaSeconds);
			Interaction.UpdateOffset(false, RightDoor, RightInitalTransform, RightRumble, DeltaSeconds);
		}
	}
}

class UParentBlobKineticDoubleDoorComponent : UParentBlobKineticInteractionComponent
{
	float LeftAmount = 0;
	float LastLeftAmount = 0;
	float RightAmount = 0;
	float LastRightAmount = 0;

	bool bIsOpen = false;
	float TimeToOpen;
	float CurrentTime;

	void OnInteractionUpdated(float MayProgress, float CodyProgress, float TotalHoldProgress) override
	{
		LeftAmount = MayProgress * TotalHoldProgress;
		RightAmount = CodyProgress * TotalHoldProgress;
		Super::OnInteractionUpdated(MayProgress, CodyProgress, TotalHoldProgress);
	}

	void OnInteractionCompleted() override
	{
		SetOpen(true, 0.5f);
		Super::OnInteractionCompleted();
	}

	void SetOpen(bool bStatus, float Time)
	{
		bIsOpen = bStatus;
		MakeAvailableAsTarget(!bStatus);
		TimeToOpen = Time;
		CurrentTime = 0;
	}

	void UpdateOffset(bool bIsLeft, UStaticMeshComponent Mesh, FTransform InitalTransform, FParentBlobKineticDoubleDoorRumbleData RumbleData, float DeltaTime)
	{
		float& LastAmount = bIsLeft ? LastLeftAmount : LastRightAmount;
		float Amount = bIsLeft ? LeftAmount : RightAmount;
		if(Amount > KINDA_SMALL_NUMBER && Amount >= LastAmount)
		{
			const float TotalScale = Owner.GetActorScale3D().Size() * InitalTransform.GetScale3D().Size();

			const float DefaultOffsetLerpSpeed = FMath::Lerp(2.f, 5.f, FMath::EaseIn(0.5f, 1.f, Amount, 2.f));
			const float OffsetLerpSpeed = RumbleData.OffsetSpeedInRelationToProgress.GetFloatValue(Amount, DefaultOffsetLerpSpeed);
			const FVector LocationOffset = RumbleData.GenerateLocationOffset(TotalScale);
			const FVector NewLocation = FMath::VInterpTo(Mesh.RelativeLocation, InitalTransform.Location + (LocationOffset * Amount), DeltaTime, OffsetLerpSpeed);

			const float DefaultRotationLerpSpeed = FMath::Lerp(1.f, 3.f, FMath::EaseIn(0.5f, 1.f, Amount, 2.f));
			const float OffsetRotationSpeed = RumbleData.RotationSpeedInRelationToProgress.GetFloatValue(Amount, DefaultRotationLerpSpeed);
			const FRotator RotationOffset = RumbleData.GenerateRotationOffset(TotalScale);
			const FRotator NewRotation = FMath::RInterpTo(Mesh.RelativeRotation, InitalTransform.Rotator() + (RotationOffset * Amount), DeltaTime, OffsetRotationSpeed);
			Mesh.SetRelativeTransform(FTransform(NewRotation, NewLocation, InitalTransform.Scale3D));
		}
		else
		{
			const FVector NewLocation = FMath::VInterpTo(Mesh.RelativeLocation, InitalTransform.Location, DeltaTime, 20.f);
			const FRotator NewRotation = FMath::RInterpTo(Mesh.RelativeRotation, InitalTransform.Rotator(), DeltaTime, 10.f);
			Mesh.SetRelativeTransform(FTransform(NewRotation, NewLocation, InitalTransform.Scale3D));
		}

		LastAmount = Amount;
	}

	void UpdateOpenClose(UStaticMeshComponent Mesh, FVector IntialLocation, FVector TargetLocation, float DeltaTime)
	{
		if(TimeToOpen <= 0)
			return;

		float OpenAlpha = 0;
		CurrentTime += DeltaTime;
		if(CurrentTime >= TimeToOpen)
		{
			OpenAlpha = 1;
			TimeToOpen = 0;
		}
		else
		{
			OpenAlpha = CurrentTime / TimeToOpen;
		}

		if(bIsOpen)
		{
			FVector FinalLocation = FMath::Lerp(Mesh.RelativeLocation, TargetLocation, OpenAlpha);
			Mesh.SetRelativeLocation(FinalLocation);
		}
		else
		{
			FVector FinalLocation = FMath::Lerp(Mesh.RelativeLocation, IntialLocation, OpenAlpha);
			Mesh.SetRelativeLocation(FinalLocation);
		}
	}
}