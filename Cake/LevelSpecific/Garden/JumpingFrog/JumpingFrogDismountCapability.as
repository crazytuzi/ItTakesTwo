import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogPlayerRideComponent;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Garden.VOBanks.GardenFrogPondVOBank;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogWaterJumpCapability;

class UJumpingFrogDismountCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroupOrder = 90;
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AHazePlayerCharacter Player;
	UJumpingFrogPlayerRideComponent RideComponent;

	bool TutorialActive = false;

	UPROPERTY(Category = "Settings")
	FTutorialPrompt DismountPrompt;

	UPROPERTY(Category = "Setup")
	UGardenFrogPondVOBank VOBank;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RideComponent = UJumpingFrogPlayerRideComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(n"AllowDismount") && RideComponent.Frog != nullptr)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"AllowDismount") || RideComponent.Frog == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ShowTutorialPrompt(Player, DismountPrompt, this);
		TutorialActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
		TutorialActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(RideComponent.Frog.FrogMoveComp.IsGrounded() && ActiveDuration >= 2.f)
		{
			if(!TutorialActive)
			{
				ShowTutorialPrompt(Player, DismountPrompt, this);
				TutorialActive = true;

				if(IsActioning(n"TriggerMayDismountVO"))
					PlayFoghornVOBankEvent(VOBank, n"FoghornDBGardenFrogPondMainFountainPuzzleTaxiStandFrogNY", Actor2 = RideComponent.Frog);
				else if(IsActioning(n"TriggerCodyDismountVO"))	
					PlayFoghornVOBankEvent(VOBank, n"FoghornDBGardenFrogPondMainFountainPuzzleTopFrogFrench", Actor = RideComponent.Frog);
			}

			if(WasActionStarted(ActionNames::Cancel))
			{
				Player.SetCapabilityActionState(n"Dismount", EHazeActionState::ActiveForOneFrame);
			}
		}
		else
		{
			if(TutorialActive)
			{
				RemoveTutorialPromptByInstigator(Player, this);
				TutorialActive = false;
			}
		}
	}

	UFUNCTION()
	void Crumb_PlayerDismountCancel(const FHazeDelegateCrumbData& CrumbData)
	{
		Player.SetCapabilityActionState(n"Dismount" , EHazeActionState::Active);
	}
}