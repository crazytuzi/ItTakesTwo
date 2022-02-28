import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsPlayerComponent;

class UMusicalChairsAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MusicalChairs");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 30;

	AHazePlayerCharacter Player;
	AMusicalChairsActor MusicalChairs;
	UMusicalChairsPlayerComponent MusicalChairsComp;
	UMusicalChairsPlayerComponent OtherMusicalChairsComp;

	EMusicalChairsButtonType PressedButton;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		MusicalChairsComp = UMusicalChairsPlayerComponent::Get(Owner);
		OtherMusicalChairsComp = UMusicalChairsPlayerComponent::Get(Player.OtherPlayer);
		MusicalChairs = MusicalChairsComp.MusicalChairs;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MusicalChairsComp.bRequestLocomotion)
			return EHazeNetworkActivation::DontActivate;

		if(MusicalChairsComp.bWonRound)
			return EHazeNetworkActivation::DontActivate;

		if(MusicalChairsComp.bExploded)
			return EHazeNetworkActivation::DontActivate;

		if(MusicalChairs.bGameOver)
			return EHazeNetworkActivation::DontActivate;

		else
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MusicalChairsComp.bWonRound)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		if(MusicalChairs.bGameOver)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MusicalChairsComp.bExploded)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(Player.IsPlayingAnyLoopingAnimationOnSlot(EHazeSlotAnimType::SlotAnimType_Default))
			Player.StopAllSlotAnimations();


		ULocomotionFeatureMusicalChairs AnimFeature = Player.IsMay() ? MusicalChairs.MayAnimFeature : MusicalChairs.CodyAnimFeature;
		Player.AddLocomotionFeature(AnimFeature);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ULocomotionFeatureMusicalChairs AnimFeature = Player.IsMay() ? MusicalChairs.MayAnimFeature : MusicalChairs.CodyAnimFeature;
		Player.RemoveLocomotionFeature(AnimFeature);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Player.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Request;
			Request.AnimationTag = n"MusicalChairs";
			Player.RequestLocomotion(Request);
		}
	}
}