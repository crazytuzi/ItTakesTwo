import Vino.Interactions.TriggerInteraction;
import Vino.Interactions.InteractionComponent;
import Cake.Interactions.Windup.WindupCapability;

event void FOnWindupFinishedEvent(AWindupActor WindupActor);
event void FAudioOnWindupFinishedEvent(AWindupActor WindupActor);
event void FOnWindupExitEvent(AWindupActor WindupActor, AHazePlayerCharacter Player);
event void FOnWindupUpdateValueEvent(float Value);
event void FOnWindupStartInteract(AHazePlayerCharacter Player);
event void FOnWindupEndInteract(AHazePlayerCharacter Player);
event void FOnWindupLockHitEvent(AWindupActor WindupActor, FName LockName);

enum EWindupInputDirection
{
	None,
	Push,
	Pull,
};

enum EWindupInputActorDirection
{
	None,
	Forward,
	Backward,
};

struct FWindupPlayerData
{
	EWindupInputActorDirection CurrentWindInput = EWindupInputActorDirection::None;
	UInteractionComponent Interaction = nullptr;
	EHazePlayer Player = EHazePlayer::MAX;
	bool bIsInteracting = false;
}

struct FWindupAmountLock
{
	UPROPERTY()
	FName Instigator = NAME_None;

	// -1; value is ignored
	UPROPERTY()
	float MinAmount = -1;

	// -1; value is ignored
	UPROPERTY()
	float MaxAmount = -1;

	void ClampValue(float Max)
	{
		if(MinAmount >= 0)
			MinAmount = FMath::Min(MinAmount, Max);

		if(MaxAmount >= 0)
		{
			MaxAmount = FMath::Min(MaxAmount, Max);
			if(MinAmount >= 0)
				MaxAmount = FMath::Max(MaxAmount, MinAmount);
		}	
	}
}

class AWindupActor : AHazeActor
{
	// The capability that will be added to the players
	UPROPERTY(Category = "Windup", AdvancedDisplay)
	TSubclassOf<UWindupCapability> CapabilityType;

	// If true, this actor can't be used when it has reached the end of the windup
	UPROPERTY(Category = "Windup")
	bool bLockWhenFinished = false;

	// How much you can wind up this actor
	UPROPERTY(Category = "Windup")
	float WindupAmount = 360.f;

	// How fast you are winding
	UPROPERTY(Category = "Windup")
	float WindupSpeed = 50.f;

	// The amount we should start at
	UPROPERTY(Category = "Windup")
	float WindupStartAmountPercentage = 0.1f;

	// How much the mesh heightoffset will decend when winding
	UPROPERTY(Category = "Windup", AdvancedDisplay)
	float MeshHeightOffsetAtMax = -40.f;

	UPROPERTY(Category = "Windup", AdvancedDisplay)
	TArray<FWindupAmountLock> WindupLocks;

	UPROPERTY()
	FOnWindupFinishedEvent OnWindupFinishedEvent;

	UPROPERTY()
	FAudioOnWindupFinishedEvent AudioOnWindupFinishedEvent;

	UPROPERTY()
	FOnWindupExitEvent OnWindpupExit;

	UPROPERTY()
	FOnWindupUpdateValueEvent OnWindupUpdateValueEvent;

	UPROPERTY()
	FOnWindupStartInteract OnStartInteractEvent;

	UPROPERTY()
	FOnWindupEndInteract OnEndInteractEvent;

	UPROPERTY()
	FOnWindupLockHitEvent OnLockHit;

	// Interal params

	// Root
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// Rotator
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Rotator;

	// Mesh
	UPROPERTY(DefaultComponent, Attach = Rotator)
	UStaticMeshComponent Mesh;
	
	// Push Left
	UPROPERTY(DefaultComponent, Attach = Rotator)
	UInteractionComponent PushLeft;
	default PushLeft.MovementSettings.InitializeSmoothTeleport();
	default PushLeft.ActionShape.Type = EHazeShapeType::Sphere;
	default PushLeft.ActionShape.SphereRadius = 0.f;
	default PushLeft.FocusShape.Type = EHazeShapeType::Sphere;
	default PushLeft.FocusShape.SphereRadius = 0.f;
	default PushLeft.Visuals.VisualOffset.Location = FVector(0.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = PushLeft)
	UBoxComponent LeftPushActionShape;
	default LeftPushActionShape.BoxExtent = FVector(150.f, 300.f, 200.f);

	// Pull Left
	UPROPERTY(DefaultComponent, Attach = Rotator)
	UInteractionComponent PullLeft;
	default PullLeft.MovementSettings.InitializeSmoothTeleport();
	default PullLeft.ActionShape.Type = EHazeShapeType::Sphere;
	default PullLeft.ActionShape.SphereRadius = 0.f;
	default PullLeft.FocusShape.Type = EHazeShapeType::Sphere;
	default PullLeft.FocusShape.SphereRadius = 0.f;
	default PullLeft.Visuals.VisualOffset.Location = FVector(0.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = PullLeft)
	UBoxComponent LeftPullActionShape;
	default LeftPullActionShape.BoxExtent = FVector(150.f, 300.f, 200.f);

	// Push Right
	UPROPERTY(DefaultComponent, Attach = Rotator)
	UInteractionComponent PushRight;
	default PushRight.MovementSettings.InitializeSmoothTeleport();
	default PushRight.ActionShape.Type = EHazeShapeType::Sphere;
	default PushRight.ActionShape.SphereRadius = 0.f;
	default PushRight.FocusShape.Type = EHazeShapeType::Sphere;
	default PushRight.FocusShape.SphereRadius = 0.f;
	default PushRight.Visuals.VisualOffset.Location = FVector(0.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = PushRight)
	UBoxComponent RightPushActionShape;
	default RightPushActionShape.BoxExtent = FVector(150.f, 300.f, 200.f);

	// Pull Right
	UPROPERTY(DefaultComponent, Attach = Rotator)
	UInteractionComponent PullRight;
	default PullRight.MovementSettings.InitializeSmoothTeleport();
	default PullRight.ActionShape.Type = EHazeShapeType::Sphere;
	default PullRight.ActionShape.SphereRadius = 0.f;
	default PullRight.FocusShape.Type = EHazeShapeType::Sphere;
	default PullRight.FocusShape.SphereRadius = 0.f;
	default PullRight.Visuals.VisualOffset.Location = FVector(0.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = PullRight)
	UBoxComponent RightPullActionShape;
	default RightPullActionShape.BoxExtent = FVector(150.f, 300.f, 200.f);

	// Use this if you want the interaction to have a different focus volume
	UPROPERTY(EditInstanceOnly)
	AVolume OptinalFocusShape = nullptr;

	// this will make the key interaction only have 1 interaction for the players
	UPROPERTY()
	bool bUseOneVolumeForAll = false;

	UPROPERTY(meta = (EditCondition = "bUseOneVolumeForAll"))
	EWindupInputDirection OnlyUseInteractionType = EWindupInputDirection::None;
	
	// This will make the camera focus the correct way if we start interacting from the wrong side
	UPROPERTY()
	bool bFocusCameraOnWrongSide = true;

	// Push Pull All
	UPROPERTY(DefaultComponent, Attach = Rotator)
	UInteractionComponent PushPullAll;
	default PushPullAll.MovementSettings.InitializeNoMovement();
	default PushPullAll.ActionShape.Type = EHazeShapeType::Sphere;
	default PushPullAll.ActionShape.SphereRadius = 0.f;
	default PushPullAll.FocusShape.Type = EHazeShapeType::Sphere;
	default PushPullAll.FocusShape.SphereRadius = 0.f;
	default PushPullAll.Visuals.VisualOffset.Location = FVector(0.f, 0.f, 0.f);

	TArray<UInteractionComponent> AllInteractions;
	
	// Private
	protected TArray<FWindupPlayerData> PlayerData;
	private float StartZ = 0.f;
	private float CurrentWindupAmount = 0.f;
	private float ForcedWindupAmount = -1.f;
	protected bool bWasFinishedLastFrame = false;
	private float TimeLeftToFinish = 0.f;
	const float FinishTime = 0.3f;
	TPerPlayer<bool> bHasBlockedCapabilities;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		for(int i = 0; i < WindupLocks.Num(); ++i)
		{
			WindupLocks[i].ClampValue(WindupAmount);
		}

		if(bUseOneVolumeForAll)
		{
			PushPullAll.Disable(n"UseOneVolumeForAll");
		}
		else
		{
			PushLeft.Disable(n"UseOneVolumeForAll");
			PullLeft.Disable(n"UseOneVolumeForAll");
			PushRight.Disable(n"UseOneVolumeForAll");
			PullRight.Disable(n"UseOneVolumeForAll");
		}
	}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		bHasBlockedCapabilities[0] = bHasBlockedCapabilities[1] = false;

		if(bUseOneVolumeForAll)
		{
			PushPullAll.AddActionPrimitive(LeftPushActionShape);
			if(OptinalFocusShape != nullptr)
				PushPullAll.AddFocusPrimitive(OptinalFocusShape.BrushComponent);
			else
				PushPullAll.AddFocusPrimitive(LeftPushActionShape);
			PushLeft.OnActivated.AddUFunction(this, n"OnInteractionActivated");
			AllInteractions.Add(PushLeft);

			PushPullAll.AddActionPrimitive(RightPushActionShape);
			if(OptinalFocusShape != nullptr)
				PushPullAll.AddFocusPrimitive(OptinalFocusShape.BrushComponent);
			else
				PushPullAll.AddFocusPrimitive(RightPushActionShape);
			PushRight.OnActivated.AddUFunction(this, n"OnInteractionActivated");
			AllInteractions.Add(PushRight);

			PushPullAll.AddActionPrimitive(LeftPullActionShape);
			if(OptinalFocusShape != nullptr)
				PushPullAll.AddFocusPrimitive(OptinalFocusShape.BrushComponent);
			else
				PushPullAll.AddFocusPrimitive(LeftPullActionShape);
			PullLeft.OnActivated.AddUFunction(this, n"OnInteractionActivated");
			AllInteractions.Add(PullLeft);

			PushPullAll.AddActionPrimitive(RightPullActionShape);
			if(OptinalFocusShape != nullptr)
				PushPullAll.AddFocusPrimitive(OptinalFocusShape.BrushComponent);
			else
				PushPullAll.AddFocusPrimitive(RightPullActionShape);
			PullRight.OnActivated.AddUFunction(this, n"OnInteractionActivated");
			AllInteractions.Add(PullRight);

			PushPullAll.OnActivated.AddUFunction(this, n"OnSingleInteractionActivated");
		}
		else
		{
			PushLeft.AddActionPrimitive(LeftPushActionShape);
			if(OptinalFocusShape != nullptr)
				PushPullAll.AddFocusPrimitive(OptinalFocusShape.BrushComponent);
			else
				PushLeft.AddFocusPrimitive(LeftPushActionShape);
			PushLeft.OnActivated.AddUFunction(this, n"OnInteractionActivated");
			AllInteractions.Add(PushLeft);

			PushRight.AddActionPrimitive(RightPushActionShape);
			if(OptinalFocusShape != nullptr)
				PushPullAll.AddFocusPrimitive(OptinalFocusShape.BrushComponent);
			else
				PushRight.AddFocusPrimitive(RightPushActionShape);
			PushRight.OnActivated.AddUFunction(this, n"OnInteractionActivated");
			AllInteractions.Add(PushRight);

			PullLeft.AddActionPrimitive(LeftPullActionShape);
			if(OptinalFocusShape != nullptr)
				PushPullAll.AddFocusPrimitive(OptinalFocusShape.BrushComponent);
			else
				PullLeft.AddFocusPrimitive(LeftPullActionShape);
			PullLeft.OnActivated.AddUFunction(this, n"OnInteractionActivated");
			AllInteractions.Add(PullLeft);

			PullRight.AddActionPrimitive(RightPullActionShape);
			if(OptinalFocusShape != nullptr)
				PushPullAll.AddFocusPrimitive(OptinalFocusShape.BrushComponent);
			else
				PullRight.AddFocusPrimitive(RightPullActionShape);	
			PullRight.OnActivated.AddUFunction(this, n"OnInteractionActivated");
			AllInteractions.Add(PullRight);
		}

		Capability::AddPlayerCapabilityRequest(CapabilityType);
		StartZ = Mesh.GetRelativeTransform().GetTranslation().Z;
		PlayerData.SetNum(2);

		UpdateAmount(WindupAmount * FMath::Clamp(WindupStartAmountPercentage, 0.f, 1.f), 0, WindupAmount);
		SetActorTickEnabled(false);
		TimeLeftToFinish = FinishTime;
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
		// If we are still blocking the player when this interaction is removed,
		// we need to clear the blocks
		for(auto Player : Game::GetPlayers())
		{
			if(!bHasBlockedCapabilities[Player.Player])
				continue;
			SetPendingInteractionCapabiltiesBlocked(Player, false);
		}
		
        Capability::RemovePlayerCapabilityRequest(CapabilityType);
    }

	UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
	{
		if(ForcedWindupAmount > 0.f)
		{			
			UpdateAmount(FMath::FInterpConstantTo(CurrentWindupAmount, ForcedWindupAmount, DeltaTime, WindupSpeed * 2), 0, WindupAmount);
			if(CurrentWindupAmount == ForcedWindupAmount)
			{
				ForcedWindupAmount = -1.f;
			}
		}
		else
		{
			// Handle finish
			if(IsFinished())	
			{				
				UpdateFinished(DeltaTime);
				
				// Clear interacting actors
				if(TimeLeftToFinish <= 0)
				{
					// No players are interacting with this so we turn it off
					PlayerData[0].Player = EHazePlayer::MAX;
					PlayerData[1].Player = EHazePlayer::MAX;
					SetActorTickEnabled(false);
				}
			}		
			else if(!PlayerData[0].bIsInteracting && !PlayerData[1].bIsInteracting)
			{
				// Clear interacting actors
				if(TimeLeftToFinish <= 0)
				{
					// No players are interacting with this so we turn it off
					PlayerData[0].Player = EHazePlayer::MAX;
					PlayerData[1].Player = EHazePlayer::MAX;
					SetActorTickEnabled(false);
				}
			}
			else
			{	
				// Update the actor actording to the players input direction
				if(PlayerData[0].CurrentWindInput != EWindupInputActorDirection::None && PlayerData[0].CurrentWindInput == PlayerData[1].CurrentWindInput)
				{
					if(PlayerData[0].CurrentWindInput == EWindupInputActorDirection::Forward)
					{	
						DecreaseAmount(CurrentWindupAmount - (DeltaTime * WindupSpeed));
						//UpdateAmount(CurrentWindupAmount - (DeltaTime * WindupSpeed), GetMinWindupAmountFromDecrease(), WindupAmount);
					}
					else
					{
						IncreaseAmount(CurrentWindupAmount + (DeltaTime * WindupSpeed));
						//UpdateAmount(CurrentWindupAmount + (DeltaTime * WindupSpeed), 0, GetMaxWindupAmountFromIncrease());
					}
				}
			}
		}
	}

    UFUNCTION(NotBlueprintCallable)
    protected void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		FWindupPlayerData& PlayerIndexData = PlayerData[int(Player.Player)];
		PlayerIndexData.Interaction = Component;
		Player.SetCapabilityAttributeObject(n"Windup", Component);
		OnStartInteractEvent.Broadcast(Player);
    }

	UFUNCTION(NotBlueprintCallable)
    protected void OnSingleInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		SetPendingInteractionCapabiltiesBlocked(Player, true);

		OnStartInteractEvent.Broadcast(Player);
		
		if(HasControl())
		{
			FWindupPlayerData& PlayerIndexData = PlayerData[int(Player.Player)];
			const FWindupPlayerData& OtherPlayerIndexData = PlayerData[int(Player.GetOtherPlayer().Player)];
			
			const FVector CurrentPlayerLocation = Player.GetActorLocation();
			int BestIndex = -1;
			float BestDistance = BIG_NUMBER;
			for(int i = 0; i < AllInteractions.Num(); ++i)
			{
				if(AllInteractions[i] == OtherPlayerIndexData.Interaction)
					continue;

				if(OnlyUseInteractionType == EWindupInputDirection::Pull)
				{
					if(AllInteractions[i] == PullLeft || AllInteractions[i] == PullRight)
						continue;
				}
				else if(OnlyUseInteractionType == EWindupInputDirection::Push)
				{
					if(AllInteractions[i] == PushLeft || AllInteractions[i] == PushRight)
						continue;
				}

				const FTransform ActivationTransform = AllInteractions[i].GetMovementDestination();
				const float DistSq = CurrentPlayerLocation.DistSquared(ActivationTransform.Location);
				if(DistSq > BestDistance)
					continue;

				BestDistance = DistSq;
				BestIndex = i;
			}

			const FTransform InteractionTransform = AllInteractions[BestIndex].GetMovementDestination();
			FVector DirToInteraction = GetActorLocation() - Player.GetActorLocation();
			DirToInteraction = DirToInteraction.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			const float Dot = DirToInteraction.DotProduct(InteractionTransform.Rotation.ForwardVector);
			NetActivateInteractionIndex(BestIndex, Player, Dot <= 0.f);
		}
    }

	UFUNCTION(NetFunction)
	void NetActivateInteractionIndex(int Index, AHazePlayerCharacter Player, bool bJumpTo)
	{
		FWindupPlayerData& PlayerIndexData = PlayerData[int(Player.Player)];
		PlayerIndexData.Interaction = AllInteractions[Index];

		FHazeDestinationSettings Movement;
		if(bJumpTo)
		{
			if(bFocusCameraOnWrongSide)
			{
				FHazePointOfInterest PointOfInterestSettings;
				PointOfInterestSettings.FocusTarget.Component = PlayerIndexData.Interaction;
				PointOfInterestSettings.FocusTarget.LocalOffset = FVector(5000.f, 0.f, 0.f);
				PointOfInterestSettings.Blend.BlendTime = 1.f;
				PointOfInterestSettings.Duration = PointOfInterestSettings.Blend.BlendTime;
				Player.ApplyPointOfInterest(PointOfInterestSettings, this);
			}

			Movement.InitializeJumpTo();
		}
		else
		{
			Movement.InitializeSmoothTeleport();
		}

		FTransform ActivationTransform = PlayerIndexData.Interaction.GetMovementDestination();
		FHazeDestinationEvents DestinationEvents;
		DestinationEvents.OnDestinationReached.BindUFunction(this, n"OnSingleInteractionTargetReached");

		Movement.ActivateOnActor(Player, ActivationTransform, DestinationEvents);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnSingleInteractionTargetReached(AHazeActor Actor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		FWindupPlayerData& PlayerIndexData = PlayerData[int(Player.Player)];
		// if(Player.HasControl())
		// 	System::SetTimer(this, Player.IsMay() ? n"MayFinishPendingInteraction" : n"CodyFinishPendingInteraction", 0.1f, false);
		Player.SetCapabilityAttributeObject(n"Windup", PlayerIndexData.Interaction);
	}

	// UFUNCTION(NotBlueprintCallable)
	// private void MayFinishPendingInteraction()
	// {
	// 	auto Player = Game::GetMay();
	// 	SetPendingInteractionCapabiltiesBlocked(Player, false);
	// }

	// UFUNCTION(NotBlueprintCallable)
	// private void CodyFinishPendingInteraction()
	// {
	// 	auto Player = Game::GetCody();
	// 	SetPendingInteractionCapabiltiesBlocked(Player, false);
	// }

	void SetPendingInteractionCapabiltiesBlocked(AHazePlayerCharacter Player, bool bStatus)
	{
		if(!Player.HasControl())
			return;

		if(bHasBlockedCapabilities[Player.Player] == bStatus)
			return;
		
		bHasBlockedCapabilities[Player.Player] = bStatus;
		if(bStatus)
		{
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
			Player.BlockCapabilities(CapabilityTags::MovementAction, this);
			Player.BlockCapabilities(CapabilityTags::Interaction, this);
		}
		else
		{
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
			Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
			Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		}
	}

	EWindupInputActorDirection GetInputType(AHazePlayerCharacter Player)const
	{
		return PlayerData[int(Player.Player)].CurrentWindInput;
	}

	void SetInputType(AHazePlayerCharacter Player, EWindupInputActorDirection InputType)
	{
		PlayerData[int(Player.Player)].CurrentWindInput = InputType;
	}

	float GetCurrentWindup() const property
	{
		return CurrentWindupAmount;
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentWindupPercentage() const property
	{
		return CurrentWindupAmount / WindupAmount;
	}

	// The amount should be between 0 and Windup Amount of this actor
	UFUNCTION()
	void AddWindupAmountLock(FName LockName, float MinAmount, float MaxAmount)
	{
		FWindupAmountLock NewLock;
		NewLock.Instigator = LockName;
		NewLock.MinAmount = MinAmount;
		NewLock.MaxAmount = MaxAmount;
		NewLock.ClampValue(WindupAmount);
		for(int i = 0; i < WindupLocks.Num(); ++i)
		{
			if(WindupLocks[i].Instigator == LockName)
			{
				WindupLocks[i] = NewLock;
				return;
			}
		}

		WindupLocks.Add(NewLock);
	}

	UFUNCTION()
	void RemoveWindupLock(FName LockName)
	{
		for(int i = WindupLocks.Num() - 1; i >= 0; --i)
		{
			if(WindupLocks[i].Instigator == LockName)
			{
				WindupLocks.RemoveAtSwap(i);
				return;
			}
		}
	}

	bool GetMaxWindupAmountFromIncreaseFromLocks(float& OutMaxAmount, FName& OutLockName)const
	{
		OutMaxAmount = -1;
		for(int i = 0; i < WindupLocks.Num(); ++i)
		{
			const float WindupLockAmount = WindupLocks[i].MaxAmount;
			if(WindupLockAmount < CurrentWindupAmount)
				continue;

			if(WindupLockAmount < OutMaxAmount)
				continue;

			OutMaxAmount = WindupLockAmount;
			OutLockName = WindupLocks[i].Instigator;
		}

		if(OutMaxAmount >= 0)
			return true;

		return false;
	}

	bool GetMinWindupAmountFromDecreaseFromLocks(float& OutMinAmount, FName& OutLockName)const
	{
		float DistanceToCurrent = BIG_NUMBER;
		OutMinAmount = -1;
		for(int i = 0; i < WindupLocks.Num(); ++i)
		{
			const float WindupLockAmount = WindupLocks[i].MinAmount;
			if(WindupLockAmount > CurrentWindupAmount)
				continue;

			const float Distance = CurrentWindupAmount - WindupLockAmount;
			if(Distance > DistanceToCurrent)
				continue;

			DistanceToCurrent = Distance;
			OutMinAmount = WindupLockAmount;
			OutLockName = WindupLocks[i].Instigator;
		}

		if(OutMinAmount >= 0)
			return true;

		return false;
	}

	bool IsFinished(bool bIncludeTimeLeft = false)const
	{
		if(TimeLeftToFinish > 0 && bIncludeTimeLeft)
			return false;
		return FMath::Abs(CurrentWindupAmount - WindupAmount) < SMALL_NUMBER;
	}

	void UpdateFinished(float DeltaTime)
	{
		if(!bWasFinishedLastFrame)
		{
			// Lock all interaction
			if(bLockWhenFinished)
			{
				for(UInteractionComponent Interaction : AllInteractions)
				{
					Interaction.Disable(n"WindupFinished");
				}

				PushPullAll.Disable(n"WindupFinished");
			}

			AudioOnWindupFinishedEvent.Broadcast(this);
		}

		if(TimeLeftToFinish > 0)
		{		
			TimeLeftToFinish = FMath::Max(TimeLeftToFinish - DeltaTime, 0.f);
			const float SinAlpha = FMath::EaseOut(0.f, 3.141592f, TimeLeftToFinish / FinishTime, 2.f);
			const float Alpha = FMath::Sin(SinAlpha);
			Mesh.SetRelativeLocation(FVector(0.f, 0.f, StartZ + FMath::Lerp(MeshHeightOffsetAtMax, 10.f, Alpha)));
		}

		if(TimeLeftToFinish <= 0)
		{
			TimeLeftToFinish = 0.f;
			if(OnWindupFinishedEvent.IsBound())
			{
				OnWindupFinishedEvent.Broadcast(this);
			}	
			
			Mesh.SetRelativeLocation(FVector(0.f, 0.f, StartZ + MeshHeightOffsetAtMax));
		}

		bWasFinishedLastFrame = IsFinished();	
	}

	void IncreaseAmount(float NewAmount)
	{
		if(WindupAmount > 0)
		{
			float MaxAmount = -1;
			FName LockName = NAME_None;
			if(GetMaxWindupAmountFromIncreaseFromLocks(MaxAmount, LockName))
			{
				if(NewAmount >= MaxAmount && CurrentWindupAmount != NewAmount)
				{
					// We have hit a lock
					OnLockHit.Broadcast(this, LockName);
				}
			}
			else
			{
				// We have no locks
				MaxAmount = WindupAmount;
			}
	
			UpdateAmount(NewAmount, 0, MaxAmount);
		}
	}

	void DecreaseAmount(float NewAmount)
	{
		if(WindupAmount > 0)
		{
			float MinAmount = -1;
			FName LockName = NAME_None;
			if(GetMinWindupAmountFromDecreaseFromLocks(MinAmount, LockName))
			{
				if(NewAmount <= MinAmount && CurrentWindupAmount != NewAmount)
				{
					// We have hit a lock
					OnLockHit.Broadcast(this, LockName);
				}
			}
			else
			{
				// We have no locks
				MinAmount = 0;
			}
			UpdateAmount(NewAmount, MinAmount, WindupAmount);
		}
	}

	void UpdateAmount(float NewAmount, float MinAmount, float MaxAmount)
	{
		if(WindupAmount > 0)
		{
			const float LastAmount = CurrentWindupAmount;
			CurrentWindupAmount = FMath::Clamp(NewAmount, MinAmount, MaxAmount);
			Rotator.SetRelativeRotation(FRotator(0.f, CurrentWindupAmount, 0.f));
			Mesh.SetRelativeLocation(FVector(0.f, 0.f, FMath::Lerp(StartZ, StartZ + MeshHeightOffsetAtMax, CurrentWindupAmount / WindupAmount)));
			OnWindupUpdateValueEvent.Broadcast(NewAmount);

			// We need to force the final target position from both sides since
			// the remote side might be finished and then the player can exit the interaction
			// before it can finish on the other side
			if(LastAmount > 0.f && CurrentWindupAmount == 0.f)
			{
				NetForceAmount(CurrentWindupAmount);
			}
			else if(LastAmount < WindupAmount && CurrentWindupAmount == WindupAmount)
			{
				NetForceAmount(CurrentWindupAmount);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetForceAmount(float Amount)
	{
		ForcedWindupAmount = Amount;
	}

	void ActivatePlayerInteracting(AHazePlayerCharacter Player)
	{
		if(Player != nullptr)
		{
			PlayerData[int(Player.Player)].Player = Player.Player;
			PlayerData[int(Player.Player)].bIsInteracting = true;
			SetActorTickEnabled(true);
			bWasFinishedLastFrame = IsFinished();
		}	
	}

	void DeactivatePlayerInteracting(AHazePlayerCharacter Player)
	{
		if(Player != nullptr)
		{
			FWindupPlayerData& PlayerDataIndex = PlayerData[int(Player.Player)];
			PlayerDataIndex.bIsInteracting = false;
			PlayerDataIndex.Interaction = nullptr;
			PlayerDataIndex.CurrentWindInput = EWindupInputActorDirection::None;

			if(bLockWhenFinished && IsFinished())
			{
				for(UInteractionComponent Interaction : AllInteractions)
				{
					Interaction.DisableForPlayer(Player, n"WindupFinished");
					OnEndInteractEvent.Broadcast(Player);
				}
				PushPullAll.Disable(n"WindupFinished");
			}

			OnWindpupExit.Broadcast(this, Player);

		}	
	}
};