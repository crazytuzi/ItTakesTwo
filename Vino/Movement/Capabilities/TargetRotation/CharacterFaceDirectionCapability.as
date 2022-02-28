
import Vino.Movement.Components.MovementComponent;

// One 30fps frame of snapback detection
const double SNAPBACK_DETECTION_DURATION = 1.f / 33.f;

struct FStickSnapbackDetector
{
	bool bDetectedSnapback = false;
	FVector SnapbackStoredDirection;
	FVector SnapbackBaseInput;
	float SnapbackDetectedTime = 0.f;

	FVector LastStickInput;
	FVector LastMovementDirection;

	bool IsReverseDirection(FVector Input, FVector Base) const
	{
		if (Base.IsZero() || Input.IsZero())
			return false;
		if (FMath::Sign(Input.X) != FMath::Sign(Base.X) && FMath::Abs(Input.X) > 0.01f)
			return true;
		if (FMath::Sign(Input.Y) != FMath::Sign(Base.Y) && FMath::Abs(Input.Y) > 0.01f)
			return true;
		return false;
	}

	FVector RemoveStickSnapbackJitter(FVector RawStick, FVector MovementDirection)
	{
		if (bDetectedSnapback)
		{
			if (IsReverseDirection(RawStick, SnapbackBaseInput))
			{
				// Snapback timed out, we probably actually reversed direction!
				double TimeDiff = Time::RealTimeSeconds - SnapbackDetectedTime;
				if (TimeDiff > SNAPBACK_DETECTION_DURATION)
				{
					bDetectedSnapback = false;

					LastStickInput = RawStick;
					LastMovementDirection = MovementDirection;
					return MovementDirection;
				}

				// Still detecting a snapback, so keep going in original direction
				LastStickInput = RawStick;
				LastMovementDirection = MovementDirection;
				return SnapbackStoredDirection;
			}
			else
			{
				// Snapback ended, allow input through
				if (!RawStick.IsZero())
				{
					// Only end snapback if we gave input in the 'right' direction,
					// otherwise just wait it out.
					bDetectedSnapback = false;
				}

				LastStickInput = RawStick;
				LastMovementDirection = MovementDirection;
				return MovementDirection;
			}
		}
		else
		{
			if (IsReverseDirection(RawStick, LastStickInput))
			{
				// Trigger a new snapback detection
				bDetectedSnapback = true;
				SnapbackBaseInput = LastStickInput;
				SnapbackStoredDirection = LastMovementDirection;
				SnapbackDetectedTime = Time::RealTimeSeconds;
				return SnapbackStoredDirection;
			}

			// Snapback detection did not trigger, so just use the input
			LastStickInput = RawStick;
			LastMovementDirection = MovementDirection;
			return MovementDirection;
		}
	}

	void ClearSnapbackDetection()
	{
		bDetectedSnapback = false;
		LastStickInput = FVector::ZeroVector;
		LastMovementDirection = FVector::ZeroVector;
	}
};

class UCharacterFaceDirectionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::CharacterFacing);
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	// Internal Variables
	UHazeMovementComponent MovementComp;
	UHazeCrumbComponent CrumbComp;
	AHazeCharacter CharacterOwner;
   	UHazePathFindingComponent TrackerComponent;

	UPROPERTY(NotEditable)
	UMovementSettings ActiveMovementSettings = nullptr;

	FStickSnapbackDetector SnapbackDetector;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CharacterOwner = Cast<AHazeCharacter>(Owner);
        ensure(CharacterOwner != nullptr);

		MovementComp = UHazeMovementComponent::GetOrCreate(CharacterOwner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		TrackerComponent = UHazePathFindingComponent::GetOrCreate(Owner);

		ActiveMovementSettings = UMovementSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (HasControl())
			MovementComp.SetTargetFacingRotation(Owner.ActorRotation, 0.f);
		TickActive(Owner.GetActorDeltaSeconds());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SnapbackDetector.ClearSnapbackDetection();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TargetLerpSpeed = MovementComp.IsGrounded() ? ActiveMovementSettings.GroundRotationSpeed : ActiveMovementSettings.AirRotationSpeed;

		FQuat PathTrackerRotation;
		if(TrackerComponent.ConsumePathRotation(PathTrackerRotation))
		{
			// Interpolate faster as the angle difference increases
			float RotationSpeedMultiplier = Owner.GetActorRotation().Quaternion().Inverse().AngularDistance( PathTrackerRotation );
			MovementComp.SetTargetFacingRotation(PathTrackerRotation, ActiveMovementSettings.GroundRotationSpeed * RotationSpeedMultiplier);
		}
		else if(HasControl() || CrumbComp == nullptr)
		{
			UMovementSettings MovementSettings = UMovementSettings::GetSettings(Owner);

			const float RotationSpeed = MovementComp.IsGrounded() ? MovementSettings.GroundRotationSpeed : MovementSettings.AirRotationSpeed;

			const FVector MovementDirection = GetAttributeVector(AttributeVectorNames::MovementDirection).ConstrainToPlane(MovementComp.WorldUp);
			const FVector StickInput = GetAttributeVector(AttributeVectorNames::MovementRaw);

			FVector MoveDirWithoutSnap = SnapbackDetector.RemoveStickSnapbackJitter(StickInput, MovementDirection);
			if(!MoveDirWithoutSnap.IsNearlyZero())
			{
				FRotator WorldUpCorrectedDirection = Math::ConstructRotatorFromUpAndForwardVector(MoveDirWithoutSnap, MovementComp.WorldUp);
				MovementComp.SetTargetFacingRotation(WorldUpCorrectedDirection, RotationSpeed);
			}
			else
			{
				MovementComp.SetTargetFacingRotation(MovementComp.GetTargetFacingRotation().Rotator(), RotationSpeed);
			}
		}
		else
		{
			FHazeActorReplicationFinalized TargetParams;
			if(CrumbComp.GetCurrentReplicatedData(TargetParams))
			{
				const float Distance = TargetParams.Rotation.Vector().AngularDistance(CharacterOwner.GetActorForwardVector());		
				float CurrentLerpSpeed = FMath::Max(Distance * 10.f, 10.f);
				MovementComp.SetTargetFacingRotation(TargetParams.Rotation, CurrentLerpSpeed);	
			}
		}

		// if(Game::GetCody() == CharacterOwner && (CurrentInputSize > 0 || LastInputSize > 0))
		// 	Print("Last: " + LastInputSize + " / " + "Current: " + CurrentInputSize, 0.f);

		// Debug
		if(IsDebugActive())
		{
			const FVector ActorLocation = Owner.GetActorLocation() + MovementComp.WorldUp * 50.f;
			System::DrawDebugArrow(ActorLocation, ActorLocation + (MovementComp.GetTargetFacingRotation().Vector() * 100.f), 10.f, FLinearColor::Green, Thickness = 4.f, Duration = 0.1f);
			
			//System::DrawDebugArrow(ActorLocation - (Owner.GetControlRotation().Vector() * 150.f), ActorLocation + (Owner.GetControlRotation().Vector() * 150.f), 10.f, FLinearColor::Blue, Thickness = 2.f, Duration = 0.1f);
		}
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
			FString DebugText = "";
			if(HasControl())
			{
				DebugText += "Control Side\n";
				DebugText += "<Green>Current Rotation: " + MovementComp.GetTargetFacingRotation().ToString() + "</>\n";
				DebugText += "<Blue>Control Rotation: " + Owner.GetControlRotation().ToString() + "</>\n";
			}
			else
			{
				DebugText += "Slave Side\n";
				DebugText += "<Green>Current Rotation: " + MovementComp.GetTargetFacingRotation().ToString() + "</>\n";
			}
			return DebugText;
		}

		return "Not Active";
	}
};
