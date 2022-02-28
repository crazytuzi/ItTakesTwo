import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerInteractComponent;

class UCurlingPlayerCameraTubeActiveCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingPlayerCameraTubeActiveCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UCameraUserComponent UserComp;
	UCurlingPlayerInteractComponent PlayerComp;
	
	FHazeAcceleratedRotator AccelRot;

	bool bMustDeactivate;

	float Timer;
	float MaxTimer = 1.8f;
	float MaxHeightToView = 2000.f;
	float MinHeightToView = 300.f;
	FHazeAcceleratedFloat currentHeightToView;
	
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
		if (PlayerComp.bLookAtTube)
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
		currentHeightToView.SnapTo(MaxHeightToView);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerComp.bLookAtTube = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		currentHeightToView.AccelerateTo(MinHeightToView, 4.f, DeltaTime);
		FVector LookDoorsDirection = PlayerComp.TubeLookAtObj.ActorLocation - (Player.ActorLocation + FVector(0.f, 0.f, currentHeightToView.Value));
		LookDoorsDirection.Normalize();
		FRotator LookAtRot = FRotator::MakeFromX(LookDoorsDirection);
		AccelRot.AccelerateTo(LookAtRot, 1.8f, DeltaTime);
		UserComp.SetDesiredRotation(AccelRot.Value);
		
		Timer -= DeltaTime;

		if (Timer <= 0.f)
			bMustDeactivate = true;
	}
}