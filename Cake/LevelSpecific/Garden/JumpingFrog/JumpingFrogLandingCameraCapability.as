import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogPlayerRideComponent;
import Vino.Camera.Components.CameraUserComponent;

class UJumpingFrogLandingCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"FrogCamera");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	UCameraUserComponent User;
	UJumpingFrogPlayerRideComponent JumpingFrogComp;

	float CurrentPitch = 0.0f;
	float CurrentTime = 0.0f;
	float TargetTime = 2.f;

	FHazeAcceleratedRotator ChaseRotation;

	bool bFinished = false;
	bool bInterrupted = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
		JumpingFrogComp = UJumpingFrogPlayerRideComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(JumpingFrogComp.Frog.FrogMoveComp.BecameGrounded())
			return EHazeNetworkActivation::ActivateLocal;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(JumpingFrogComp.Frog.bJumping || bFinished || bInterrupted)
			return EHazeNetworkDeactivation::DeactivateLocal;
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
		CurrentTime = 0.0f;
		bFinished = false;
		bInterrupted = false;
		ChaseRotation.Velocity = 0.0f;
		SetMutuallyExclusive(n"FrogCamera", true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(n"FrogCamera", false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator CameraRotation;
		FRotator DesiredRotation;

		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		
		if(AxisInput.Size() > 0.0f)
			bInterrupted = true;

		if(!bInterrupted || !bFinished)
		{
			FVector TargetDirection = JumpingFrogComp.Frog.ActorVelocity.GetSafeNormal();

			CameraRotation = Math::MakeRotFromX(TargetDirection);

			DesiredRotation = User.WorldToLocalRotation(User.GetDesiredRotation());
			ChaseRotation.Value = DesiredRotation;
			CameraRotation.Pitch = -20.0f;

			ChaseRotation.AccelerateTo(CameraRotation, TargetTime, DeltaTime);
			FRotator DeltaRot = (ChaseRotation.Value - DesiredRotation).GetNormalized();

			DeltaRot.Roll = 0.0f;
			DeltaRot.Yaw = 0.0f;

			User.AddDesiredRotation(DeltaRot);

			CurrentTime += DeltaTime;
			if(CurrentTime >= TargetTime)
				bFinished = true;
		}


	}
}