import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogPlayerRideComponent;
import Vino.Camera.Components.CameraUserComponent;

class UJumpingFrogJumpCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CameraTags::OptionalChaseAssistance);
	default CapabilityTags.Add(n"FrogCamera");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 51;

	AHazePlayerCharacter Player;
	UCameraUserComponent User;
	UJumpingFrogPlayerRideComponent JumpingFrogComp;
	UCameraLazyChaseSettings CameraChaseSettings;

	float CurrentPitch = 0.0f;
	float CurrentTime = 0.0f;
	float TargetTime = 2.f;

	FHazeAcceleratedRotator ChaseRotation;

	bool bFinished = false;

	//const float InterupdateDelayMax = 2.f;
	float InterupdateDelay = 0;
	float LastInputTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
		JumpingFrogComp = UJumpingFrogPlayerRideComponent::Get(Player);
		CameraChaseSettings = UCameraLazyChaseSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(JumpingFrogComp.Frog.bJumping)
			return EHazeNetworkActivation::ActivateLocal;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!JumpingFrogComp.Frog.bJumping)
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
		InterupdateDelay = 0;
		ChaseRotation.Velocity = 0.0f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bFinished)
		{
			CurrentTime += DeltaTime;
			if(CurrentTime >= TargetTime)
				bFinished = true;

			const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
			InterupdateDelay = FMath::Max(InterupdateDelay - DeltaTime, 0.f);
			const float InterupdateDelayMax = CameraChaseSettings.AccelerationDuration;

			const FRotator CurrentDesiredRotation = User.WorldToLocalRotation(User.GetDesiredRotation());

			const bool bBlockedByInput = AxisInput.Size() > KINDA_SMALL_NUMBER || ActiveDuration < CameraChaseSettings.MovementInputDelay * 0.5f;
			if(bBlockedByInput)
				LastInputTime = Time::GetGameTimeSeconds();

			const float TimeSinceInput = Time::GetGameTimeSince(LastInputTime);
			if(bBlockedByInput || TimeSinceInput < CameraChaseSettings.CameraInputDelay)
			{
				ChaseRotation.SnapTo(CurrentDesiredRotation);
				FRotator DeltaRot = (ChaseRotation.Value - CurrentDesiredRotation).GetNormalized();
				User.AddDesiredRotation(DeltaRot);
			}
			else
			{
				const FVector CurrentCameraHorizontalForward = CurrentDesiredRotation.GetForwardVector().ConstrainToPlane(FVector::UpVector).GetSafeNormal();
				
				FRotator WantedDesiredRotation;
				const FVector TargetDirection = JumpingFrogComp.Frog.FrogMoveComp.GetVelocity().ConstrainToPlane(FVector::UpVector);
				
				if(!TargetDirection.IsNearlyZero(1500.f) && TargetDirection.DotProduct(JumpingFrogComp.Frog.GetActorForwardVector()) > 0.1f)
					WantedDesiredRotation = User.WorldToLocalRotation(FRotator::MakeFromXZ(TargetDirection.GetSafeNormal(), CurrentDesiredRotation.UpVector));
				else
					WantedDesiredRotation = CurrentDesiredRotation;

				WantedDesiredRotation.Pitch = CurrentDesiredRotation.Pitch;
				
				if(JumpingFrogComp.Frog.VerticalTravelDirection == -1)
				{
					float CurrentWantedPitch = FMath::Min(CurrentDesiredRotation.Pitch, -35.0f);
					WantedDesiredRotation.Pitch = FMath::FInterpTo(CurrentDesiredRotation.Pitch, CurrentWantedPitch, DeltaTime, 10.f);
				}

				ChaseRotation.Value = CurrentDesiredRotation;
				ChaseRotation.AccelerateTo(WantedDesiredRotation, InterupdateDelayMax, DeltaTime);

				FRotator DeltaRot = (ChaseRotation.Value - CurrentDesiredRotation).GetNormalized();
				User.AddDesiredRotation(DeltaRot);
			}	
		}
	}
}