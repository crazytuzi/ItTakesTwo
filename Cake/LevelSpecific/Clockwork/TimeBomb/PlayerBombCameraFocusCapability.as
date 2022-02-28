import Cake.LevelSpecific.Clockwork.TimeBomb.PlayerTimeBombComp;
import Vino.Camera.Components.CameraUserComponent;
class UPlayerBombCameraFocusCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerBombCameraFocusCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UPlayerTimeBombComp PlayerComp;

	UCameraUserComponent UserComp;

	FRotator CurrentRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerTimeBombComp::Get(Player);
		UserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.TimeBombState == ETimeBombState::Ready)
        	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.TimeBombState != ETimeBombState::Ready)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentRotation = UserComp.DesiredRotation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FRotator Direction = FRotator::MakeFromX(PlayerComp.FacingDirection);
		FRotator DirectionAdjusted = Direction + FRotator(-25.f, 0.f, 0.f);
		CurrentRotation = FMath::RInterpTo(CurrentRotation, DirectionAdjusted, DeltaTime, 2.5f);
		UserComp.SetDesiredRotation(CurrentRotation);
	}
}