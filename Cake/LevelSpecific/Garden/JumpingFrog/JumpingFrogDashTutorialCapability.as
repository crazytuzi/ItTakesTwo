import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogPlayerRideComponent;
import Vino.Tutorial.TutorialStatics;

class UJumpingFrogDashTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	UJumpingFrogPlayerRideComponent RideComp;
	AHazePlayerCharacter Player;

	bool bTutorialCompleted = false;
	float DashTimer = 0.f;
	float DashTimeRequired = 1.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RideComp = UJumpingFrogPlayerRideComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!bTutorialCompleted && RideComp != nullptr && RideComp.Frog != nullptr)
			return EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bTutorialCompleted)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DashTimer = 0.f;
/* 
		if(!bTutorialCompleted)
			ShowTutorialPrompt(Player, RideComp.Frog.DashPrompt, this); */

		ShowTutorialPrompt(Player, RideComp.Frog.JumpPrompt, this);
		ShowTutorialPrompt(Player, RideComp.Frog.DashPrompt, this);

		bTutorialCompleted = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		//RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
/* 		if(IsActioning(ActionNames::MovementDash))
		{
			if(DashTimer < DashTimeRequired)
				DashTimer += DeltaTime;
			else if(DashTimer >= DashTimeRequired)
				bTutorialCompleted = true;
		}
		else
		{
			DashTimer = 0.f;
		} */
	}
}