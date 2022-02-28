import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtingDino;
import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadbuttingDinoAnimationDataComponent;

class HeadbuttingDinoAnimationDataCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::ActionMovement;

	AHeadButtingDino Dino;
	UHeadbuttingDinoAnimationDataComponent DinoDataComponent;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		AHeadButtingDino HeadbuttingDino = Cast<AHeadButtingDino>(GetAttributeObject(n"HeadbuttingDino"));
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        Dino = Cast<AHeadButtingDino>(Owner);
		DinoDataComponent = UHeadbuttingDinoAnimationDataComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DinoDataComponent.bIsHeadbutting = Dino.IsHeadButting;
		DinoDataComponent.ForwardSpeedAlpha = Dino.ForwardSpeedAlpha;
		DinoDataComponent.bEnteredDino = Dino.bJumpedOn;
	}
}