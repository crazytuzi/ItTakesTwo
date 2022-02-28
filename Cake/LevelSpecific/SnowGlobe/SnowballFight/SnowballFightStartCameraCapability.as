import Vino.Camera.Components.CameraUserComponent;
class USnowballFightStartCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnowballFightStartCameraCapability");
	default CapabilityTags.Add(n"SnowballFight");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UCameraUserComponent UserComp;

	FHazeAcceleratedRotator AccelRot;
	FVector PlayerDir;
	FRotator TargetRot; 

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AccelRot.SnapTo(UserComp.DesiredRotation);
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		Player.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFocusTarget FocusTarget;
		FocusTarget.Actor = Player.OtherPlayer;

		FHazePointOfInterest PointOfInterest;
		PointOfInterest.Blend = 1.5f;
		PointOfInterest.FocusTarget = FocusTarget;

		Player.ApplyPointOfInterest(PointOfInterest, this);
	}
}