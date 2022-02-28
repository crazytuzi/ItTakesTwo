import Cake.LevelSpecific.Hopscotch.SideContent.Rodeo.RodeoMechanicalBull;

class URodeoPlayerMountCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 50;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayMh;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyMh;

	UAnimSequence Mh;

	AHazePlayerCharacter Player;
	ARodeoMechanicalBull CurrentRodeoBull;
	UHazeSkeletalMeshComponentBase BullMesh;

	bool bFullyMounted = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"RodeoMount"))
        	return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(n"Rodeo"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!IsActioning(n"RodeoMount"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentRodeoBull = Cast<ARodeoMechanicalBull>(GetAttributeObject(n"RodeoBull"));
		BullMesh = CurrentRodeoBull.BullMesh;
		CurrentRodeoBull.MountedPlayer = Player;
		CurrentRodeoBull.bMounted = true;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.TriggerMovementTransition(this);

		Player.AttachToComponent(CurrentRodeoBull.BullMesh, n"Bull", EAttachmentRule::KeepWorld);
		Player.SmoothSetLocationAndRotation(CurrentRodeoBull.PlayerAttachmentPoint.WorldLocation, CurrentRodeoBull.PlayerAttachmentPoint.WorldRotation);

		Player.ApplyCameraOffsetOwnerSpace(FVector(0.f, 0.f, -150.f), CameraBlend::Additive(), this);

		Mh = Player.IsMay() ? MayMh : CodyMh;
		Player.PlaySlotAnimation(Animation = Mh, bLoop = true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		Player.ClearCameraOffsetOwnerSpaceByInstigator(this);

		Player.StopAnimationByAsset(Mh);

		Player.SetCapabilityActionState(n"RodeoMount", EHazeActionState::Inactive);
	}
}