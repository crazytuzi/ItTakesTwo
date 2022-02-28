import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.Teleporter.CastleEnemyTeleporterComponent;

class UCastleEnemyAITeleportCapability : UHazeCapability
{
    default TickGroupOrder = 101;
    default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default CapabilityTags.Add(n"CastleEnemyAI");
    default CapabilityTags.Add(n"CastleEnemyAbility");
    default CapabilityTags.Add(n"CastleEnemyTeleport");

    default CapabilityDebugCategory = n"Castle";

    UPROPERTY()
    FVector TeleportLocation;
	FRotator TeleportRotation;
    bool bTeleportLocationSet;

    bool bTeleportInComplete;
    bool bTeleportOutComplete;

    UPROPERTY()
    FHazeTimeLike TeleportInMovementTimelike;
    default TeleportInMovementTimelike.Duration = 1.6f;

    UPROPERTY()
    FHazeTimeLike TeleportOutMovementTimelike;
    default TeleportOutMovementTimelike.Duration = 0.6f;

    ACastleEnemy OwningEnemy;
    UHazeBaseMovementComponent MoveComp;
	UCastleEnemyTeleporterComponent TeleportComp;
	bool bSkipEnter = false;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        OwningEnemy = Cast<ACastleEnemy>(Owner);
        MoveComp = UHazeBaseMovementComponent::Get(Owner);
        TeleportComp = UCastleEnemyTeleporterComponent::Get(Owner);

        TeleportInMovementTimelike.BindUpdate(this, n"OnTeleportInMovementTimelikeUpdate");
        TeleportInMovementTimelike.BindFinished(this, n"OnTeleportInMovementTimelikeFinished");

        TeleportOutMovementTimelike.BindUpdate(this, n"OnTeleportOutMovementTimelikeUpdate");
        TeleportOutMovementTimelike.BindFinished(this, n"OnTeleportOutMovementTimelikeFinished");
    }

    UFUNCTION()
    void OnTeleportInMovementTimelikeUpdate(float CurrentValue)
    {
        FVector StartLocation;
        FVector EndLocation;
        EndLocation.Z -= OwningEnemy.CapsuleComponent.CapsuleHalfHeight * 3; 

        FVector LerpedLocation;
        LerpedLocation = FMath::Lerp(StartLocation, EndLocation, CurrentValue);

		if (TeleportComp.bRiseOutOfFloor)
		{
			OwningEnemy.MeshOffsetComponent.OffsetLocationWithTime(OwningEnemy.ActorLocation + LerpedLocation, 0.f);
		}
		else
		{
			if (CurrentValue >= 0.25f && !OwningEnemy.bHidden)
			{
				if (TeleportComp.TeleporterVanishEffect != nullptr)
					Niagara::SpawnSystemAtLocation(TeleportComp.TeleporterVanishEffect, OwningEnemy.ActorLocation, OwningEnemy.ActorRotation);
				OwningEnemy.SetActorHiddenInGame(false);
			}
		}
    }

    UFUNCTION()
    void OnTeleportInMovementTimelikeFinished()
    {
		MoveComp.SetControlledComponentTransform(
			TeleportLocation,
			TeleportRotation);
        TeleportOutMovementTimelike.PlayFromStart();
		bTeleportInComplete = true;

		if (!TeleportComp.bRiseOutOfFloor)
			OwningEnemy.SetActorHiddenInGame(false);

		if (TeleportComp.TeleporterAppearEffect != nullptr)
			Niagara::SpawnSystemAtLocation(TeleportComp.TeleporterAppearEffect, TeleportLocation, TeleportRotation);
    }

    UFUNCTION()
    void OnTeleportOutMovementTimelikeUpdate(float CurrentValue)
    {
        FVector StartLocation;
        FVector EndLocation;
        EndLocation.Z -= OwningEnemy.CapsuleComponent.CapsuleHalfHeight * 3; 

        FVector LerpedLocation;
        LerpedLocation = FMath::Lerp(EndLocation, StartLocation, CurrentValue);

		if (TeleportComp.bRiseOutOfFloor)
			OwningEnemy.MeshOffsetComponent.OffsetLocationWithTime(OwningEnemy.ActorLocation + LerpedLocation, 0.f);
    }    

    UFUNCTION(BlueprintEvent)
    void OnTeleportOutMovementTimelikeFinished()
    {
        bTeleportOutComplete = true;
    }   

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (IsActioning(n"Teleport"))
			return EHazeNetworkActivation::ActivateUsingCrumb; 
        return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (bTeleportOutComplete)
            return EHazeNetworkDeactivation::DeactivateLocal; 
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		if (IsActioning(n"TeleportSkipEnter"))
			ActivationParams.AddActionState(n"TeleportSkipEnter");
		ActivationParams.AddVector(n"TeleportLocation", GetAttributeVector(n"TeleportLocation"));
		ActivationParams.AddVector(n"TeleportRotation", GetAttributeVector(n"TeleportRotation"));
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		TeleportLocation = ActivationParams.GetVector(n"TeleportLocation");
		TeleportRotation = FRotator::MakeFromX(ActivationParams.GetVector(n"TeleportRotation"));
		bSkipEnter = ActivationParams.GetActionState(n"TeleportSkipEnter");

		ConsumeAction(n"Teleport");
		ConsumeAction(n"TeleportSkipEnter");

        OwningEnemy.BlockCapabilities(CapabilityTags::Movement, this);
        OwningEnemy.BlockCapabilities(n"CastleEnemyAI", this);
        OwningEnemy.BlockCapabilities(n"CastleEnemyMovement", this);
		OwningEnemy.bUnhittable = true;
		OwningEnemy.bAlwaysShowHealthBar = false;

        bTeleportInComplete = false;
        bTeleportOutComplete = false;
        
        FVector ToTeleportLocation = TeleportLocation - Owner.ActorLocation;
        MoveComp.SetTargetFacingRotation(Math::MakeRotFromX(ToTeleportLocation), 25.f);

		if (bSkipEnter)
		{
			OnTeleportInMovementTimelikeUpdate(1.f);
			OnTeleportInMovementTimelikeFinished();
		}
		else
		{
			if (TeleportComp.bRiseOutOfFloor && TeleportComp.TeleporterVanishEffect != nullptr)
				Niagara::SpawnSystemAtLocation(TeleportComp.TeleporterVanishEffect, OwningEnemy.ActorLocation, OwningEnemy.ActorRotation);
			TeleportInMovementTimelike.PlayFromStart();
		}

		OwningEnemy.SetCapabilityActionState(n"AudioStartedTeleport", EHazeActionState::ActiveForOneFrame);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (MoveComp.CanCalculateMovement())
        {
			FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemyTeleport");        	
			if (bTeleportInComplete)
				MoveComp.SetTargetFacingRotation(TeleportRotation, 0.f);
			Movement.ApplyTargetRotationDelta();
			MoveComp.Move(Movement);    

			OwningEnemy.SendMovementAnimationRequest(
				Movement,
				n"CastleEnemyTeleport",
				!bTeleportInComplete ? n"TeleportEnter" : n"TeleportExit");
		}
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
        OwningEnemy.UnblockCapabilities(CapabilityTags::Movement, this);
        OwningEnemy.UnblockCapabilities(n"CastleEnemyAI", this);
        OwningEnemy.UnblockCapabilities(n"CastleEnemyMovement", this);
		OwningEnemy.bUnhittable = false;
		OwningEnemy.bAlwaysShowHealthBar = true;

        bTeleportLocationSet = false;
		OwningEnemy.MeshOffsetComponent.ResetLocationWithTime(0.1f);
		OwningEnemy.TriggerMovementTransition(this);
		
		OwningEnemy.SetCapabilityActionState(n"AudioStoppedTeleport", EHazeActionState::ActiveForOneFrame);

		TeleportComp.OnTeleporterChangedPhase.Broadcast(TeleportComp.CurrentPhase);
    }    
}

UFUNCTION()
void CastleEnemyMageForceTeleport(ACastleEnemy Enemy, FTransform Transform)
{
	Enemy.DisableComponent.SetUseAutoDisable(false);
	Enemy.SetCapabilityActionState(n"Teleport", EHazeActionState::Active);
	Enemy.SetCapabilityActionState(n"TeleportSkipEnter", EHazeActionState::Active);
	Enemy.SetCapabilityAttributeVector(n"TeleportLocation", Transform.Location);

	FVector EndLocation;
	EndLocation.Z -= Enemy.CapsuleComponent.CapsuleHalfHeight * 3; 
	Enemy.MeshOffsetComponent.OffsetLocationWithTime(Enemy.ActorLocation + EndLocation, 0.f);
}