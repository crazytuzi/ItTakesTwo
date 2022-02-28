import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunPlayerComponent;
import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunManager;

class UPlungerGunPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UPlungerGunPlayerComponent GunComp;
	APlungerGun Gun;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GunComp = UPlungerGunPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GunComp.Gun == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (GunComp.Gun == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (PlungerGunGameIsResetting())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Gun = GunComp.Gun;
		Gun.CurrentPlayer = Player;
		Gun.Interaction.Disable(n"Busy");

		Player.CleanupCurrentMovementTrail();
		Player.BlockMovementSyncronization(this);
		Player.TriggerMovementTransition(this, n"PlungerGunEnter");
		Player.AttachToComponent(Gun.SeatRoot, NAME_None, EAttachmentRule::SnapToTarget);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(ActionNames::WeaponAim, this);
		Player.BlockCapabilities(ActionNames::WeaponFire, this);

		Player.ActivateCamera(Gun.Camera, CameraBlend::Normal(1.2f));
		Player.DisableOutlineByInstigator(this);

		Player.PlaySlotAnimation(OnBlendingOut = FHazeAnimationDelegate(this, n"HandleEnterFinished"), Animation = GunComp.EnterAnim[Player], BlendTime = 0.03f);

		// Interact with the double-interact on the plungergun manager
		PlungerGunManager.DoubleInteract.StartInteracting(Player);

		System::SetTimer(this, n"CheckPendingBark", 2.f, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (!Gun.IsActorBeingDestroyed())
		{
			Gun.CurrentPlayer = nullptr;
			Gun.Interaction.EnableAfterFullSyncPoint(n"Busy");
		}

		Player.DeactivateCamera(Gun.Camera);

		Player.DetachRootComponentFromParent();

		Player.UnblockMovementSyncronization(this);
		Player.TriggerMovementTransition(this, n"PlungerGunExit");

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
		Player.UnblockCapabilities(ActionNames::WeaponFire, this);
		Player.EnableOutlineByInstigator(this);
		Player.StopAllSlotAnimations(0.4f);

		// If this exit is natural (ExitGun) then jump off it!
		// This wont happen if we're reloading a checkpoint and so on in that case
		if (GunComp.bNaturalExit)
		{
			FHazeJumpToData JumpTo;
			JumpTo.TargetComponent = Gun.JumpOffPoint;
			FHazeDestinationEvents OnFinishedJump;
			if (PlungerGunGameIsResetting())
				OnFinishedJump.OnDestinationReached.BindUFunction(this, n"DelayedPlayReactionAnims");

			JumpTo::ActivateJumpTo(Player, JumpTo, OnFinishedJump);
		}

		Gun = nullptr;
	}

	UFUNCTION()
	void CheckPendingBark()
	{
		if (!IsActive())
			return;

		if (!PlungerGunGameIsIdle())
			return;

		PlungerGunPlayPendingBark(Player);
	}

	UFUNCTION()
	void DelayedPlayReactionAnims(AHazeActor Actor)
	{
		PlungerGunManager.Minigame.ActivateReactionAnimations(Player);
	}

	UFUNCTION()
	void HandleEnterFinished()
	{
		if (!IsActive())
			return;

		FHazeSlotAnimSettings Settings;
		Settings.BlendTime = 0.03f;
		Settings.bLoop = true;
		Player.PlaySlotAnimation(Animation = GunComp.MHAnim[Player], Settings = Settings);
	}
}