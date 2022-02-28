import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.SpaceRocket;

UCLASS(Abstract)
class UMountSpaceRocketCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	ASpaceRocket SpaceRocketActor;

	UPROPERTY()
	UAnimSequence CodyMountAnimation;
	UPROPERTY()
	UAnimSequence MayMountAnimation;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveRocketUpTimeLike;
	default MoveRocketUpTimeLike.Duration = 0.25f;

	FVector RocketStartLoc;

	bool bMounting = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"MountSpaceRocket"))
            return EHazeNetworkActivation::ActivateUsingCrumb;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!bMounting)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Player.IsPlayerDead())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"SpaceRocket", GetAttributeObject(n"SpaceRocketActor"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bMounting = true;
		SpaceRocketActor = Cast<ASpaceRocket>(ActivationParams.GetObject(n"SpaceRocket"));
		Player.SetCapabilityActionState(n"MountSpaceRocket", EHazeActionState::Inactive);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
        Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(n"ChangeSize", this);
		Player.BlockCapabilities(n"KnockDown", this);
		Player.TriggerMovementTransition(this);
		
		Player.SmoothSetLocationAndRotation(SpaceRocketActor.AttachmentPoint.WorldLocation, SpaceRocketActor.AttachmentPoint.WorldRotation);
		Player.AttachToComponent(SpaceRocketActor.AttachmentPoint, AttachmentRule = EAttachmentRule::KeepWorld);

		FHazeAnimationDelegate MountAnimFinishedDelegate;
		MountAnimFinishedDelegate.BindUFunction(this, n"MountAnimFinished");
		
		UAnimSequence EnterAnim = Player.IsCody() ? CodyMountAnimation : MayMountAnimation;
		Player.PlaySlotAnimation(OnBlendingOut = MountAnimFinishedDelegate, Animation = EnterAnim);

		MoveRocketUpTimeLike.BindUpdate(this, n"UpdateMoveRocketUp");
		RocketStartLoc = SpaceRocketActor.ActorLocation;
		MoveRocketUpTimeLike.PlayFromStart();

		FHazePointOfInterest PoI;
		PoI.FocusTarget.Actor = SpaceRocketActor;
		PoI.FocusTarget.LocalOffset = FVector(500.f, 0.f, 250.f);
		PoI.Blend.BlendTime = 0.5f;
		PoI.Duration = 1.f;
		Player.ApplyPointOfInterest(PoI, this);
	}

	UFUNCTION()
	void UpdateMoveRocketUp(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(RocketStartLoc, RocketStartLoc + FVector(0.f, 0.f, 150.f), CurValue);
		SpaceRocketActor.SetActorLocation(CurLoc);

		float CurPitch = FMath::Lerp(0.f, 25.f, CurValue);
		SpaceRocketActor.SetActorRotation(FRotator(CurPitch, SpaceRocketActor.ActorRotation.Yaw, 0.f));
	}

	UFUNCTION()
	void MountAnimFinished()
	{
		bMounting = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(n"ChangeSize", this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(n"KnockDown", this);

		if (Player.IsPlayerDead())
		{
			Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			SpaceRocketActor.NetTriggerExplosion();
			return;
		}

		if (!SpaceRocketActor.bPermanentlyDisabled)
		{
			Player.SetCapabilityActionState(n"ControlSpaceRocket", EHazeActionState::Active);
		}
	}
}