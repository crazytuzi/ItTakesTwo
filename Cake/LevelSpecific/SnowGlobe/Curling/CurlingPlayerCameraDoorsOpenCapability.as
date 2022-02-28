import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerInteractComponent;


class UCurlingPlayerCameraDoorsOpenCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingPlayerCameraDoorsOpenCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UCameraUserComponent UserComp;
	UCurlingPlayerInteractComponent PlayerComp;
	
	FHazeAcceleratedRotator AccelRot;
	
	bool bMustDeactivate;

	float Timer;
	float MaxTimer = 3.f;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserComp = UCameraUserComponent::Get(Player);
		PlayerComp = UCurlingPlayerInteractComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.bLookAtDoors)
        	return EHazeNetworkActivation::ActivateFromControl;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bMustDeactivate)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AccelRot.SnapTo(UserComp.DesiredRotation);
		bMustDeactivate = false;
		Timer = MaxTimer;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerComp.bLookAtDoors = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector LookDoorsDirection = (PlayerComp.DoorLookAtObj.ActorLocation + FVector(0.f, 0.f, -1800.f)) - Player.ActorLocation;
		LookDoorsDirection.Normalize();
		FRotator LookAtRot = FRotator::MakeFromX(LookDoorsDirection);
		AccelRot.AccelerateTo(LookAtRot, 2.2f, DeltaTime);
		UserComp.SetDesiredRotation(AccelRot.Value);
		
		Timer -= DeltaTime;

		if (Timer <= 0.f)
			bMustDeactivate = true;
	}
}