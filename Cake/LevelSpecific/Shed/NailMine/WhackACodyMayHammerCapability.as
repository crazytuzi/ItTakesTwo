import Cake.LevelSpecific.Shed.NailMine.WhackACodyComponent;
import Cake.LevelSpecific.Shed.Main.WhackACody_May;
import Vino.Interactions.AnimNotify_Interaction;

class UWhackACodyMayHammerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WhackACody");

	default CapabilityDebugCategory = n"WhackACody";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 30;

	AHazePlayerCharacter Player;
	UWhackACodyComponent WhackaComp;
	EWhackACodyDirection HammerDirection;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WhackaComp = UWhackACodyComponent::Get(Player);
		// Use timer instead
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WhackaComp.WhackABoardRef == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStartedDuringTime(ActionNames::WeaponFire, 0.4f))
			return EHazeNetworkActivation::DontActivate;

		if (WhackaComp.WhackABoardRef.MinigameState == EWhackACodyGameStates::Countdown)
			return EHazeNetworkActivation::DontActivate;

		if (WhackaComp.WhackABoardRef.MinigameState == EWhackACodyGameStates::ShowingTutorial)
			return EHazeNetworkActivation::DontActivate;

		if (WhackaComp.HammerCooldown > 0.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.Mesh.SetAnimBoolParam(n"bHit", true);
		Player.BindOneShotAnimNotifyDelegate(
			UAnimNotify_Interaction::StaticClass(),
			FHazeAnimNotifyDelegate(this, n"OnAnimNotify")
		);

		WhackaComp.TurnCooldown = 0.05f;
		WhackaComp.HammerCooldown = 0.1f;
		HammerDirection = WhackaComp.CurrentDir;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION()
	void OnAnimNotify(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		auto CodyWhackComp = UWhackACodyComponent::Get(Game::Cody);
		if (CodyWhackComp == nullptr)
			return;

		if (CodyWhackComp.CurrentDir == HammerDirection &&
			CodyWhackComp.PeekAlpha > 0.9f)
		{
			if (HasControl())
				WhackaComp.WhackABoardRef.NetAddMayScore();

			// We do peek-cooldown locally so that it looks good on both sides
			// We don't care that much that it _might_ not be super synced with actual score gain :)
			CodyWhackComp.SetPeekCooldown();
			Player.GetOtherPlayer().SetCapabilityActionState(n"AudioCodyWasHit", EHazeActionState::ActiveForOneFrame);
		}
	}
}