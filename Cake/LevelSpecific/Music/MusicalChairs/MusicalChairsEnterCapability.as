import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsPlayerComponent;

class UMusicalChairsEnterCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MusicalChairs");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AMusicalChairsActor MusicalChairs;
	UMusicalChairsPlayerComponent MusicalChairsComp;

	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);

		MusicalChairsComp = UMusicalChairsPlayerComponent::Get(Owner);
		MusicalChairs = MusicalChairsComp.MusicalChairs;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IsActioning(n"ReadyForMusicalChairs"))
			return EHazeNetworkActivation::DontActivate;
		else
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Player.IsMay() && MusicalChairs.bMayCancelledInteraction)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Player.IsCody() && MusicalChairs.bCodyCancelledInteraction)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MusicalChairs.bMiniGameIsOn)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MusicalChairs.bTutorialWasCancelled)
			return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ConsumeAction(n"ReadyForMusicalChairs");

		Player.BlockCapabilities(CapabilityTags::MovementInput, MusicalChairs);
		Player.BlockCapabilities(MovementSystemTags::Swinging, MusicalChairs);
		Player.BlockCapabilities(n"CameraControl", MusicalChairs);
		Player.BlockCapabilities(n"LevelSpecific", MusicalChairs);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bool bCancelled = false;

		if(Player.IsMay() && MusicalChairs.bMayCancelledInteraction)
		{
			MusicalChairs.bMayCancelledInteraction = false;
			bCancelled = true;
		}
		if(Player.IsCody() && MusicalChairs.bCodyCancelledInteraction)
		{
			MusicalChairs.bCodyCancelledInteraction = false;
			bCancelled = true;
		}

		if(bCancelled || MusicalChairs.bTutorialWasCancelled)
		{
			Player.UnblockCapabilities(CapabilityTags::MovementInput, MusicalChairs);
			Player.UnblockCapabilities(MovementSystemTags::Swinging, MusicalChairs);
			Player.UnblockCapabilities(n"CameraControl", MusicalChairs);
			Player.UnblockCapabilities(n"LevelSpecific", MusicalChairs);

			MusicalChairs.CancelPlayer(Player);
		}
		else
		{
			Player.SetCapabilityActionState(n"StartMusicalChairs", EHazeActionState::Active);
			Player.SetAnimBoolParam(n"DoubleInteractStarted", true);
		}
		
	}
}