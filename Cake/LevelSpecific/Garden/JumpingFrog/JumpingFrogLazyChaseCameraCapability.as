import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogTags;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogPlayerRideComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Camera.Capabilities.CameraLazyChaseCapability;

class UJumpingFrogLazyChaseCameraCapability : UCameraLazyChaseCapability
{
	default CapabilityTags.Add(n"JumpingFrogLazyChaseCamera");
	default CapabilityTags.Add(CameraTags::OptionalChaseAssistance);

	UJumpingFrogPlayerRideComponent RideComponent;
	float ActiveJumpTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams) override
	{
		Super::Setup(SetupParams);
		RideComponent = UJumpingFrogPlayerRideComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const override
	{
		if(RideComponent.Frog == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const override
	{
		if(RideComponent.Frog == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return Super::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) override
	{
		Super::OnActivated(ActivationParams);
		PlayerUser.ApplySettings(RideComponent.Frog.CameraLazyChaseSettings, this, EHazeSettingsPriority::Gameplay);
		SetMutuallyExclusive(CameraTags::ChaseAssistance, true);
		MoveComp = RideComponent.Frog.FrogMoveComp;
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) override
	{
		Super::OnDeactivated(DeactivationParams);
		PlayerUser.ClearSettingsByInstigator(this);
		SetMutuallyExclusive(CameraTags::ChaseAssistance, false);
	}	

	FRotator FinalizeDeltaRotation(float DeltaTime, FRotator DeltaRot) override
	{
		FRotator FinalDeltaRot = Super::FinalizeDeltaRotation(DeltaTime, DeltaRot);
		
		if(RideComponent.Frog.bJumping)
		{
			ActiveJumpTime += DeltaTime;
			const float SpeedAlpha = FMath::Min(ActiveJumpTime / 1.f, 1.f);
			FRotator DesiredRot = User.WorldToLocalRotation(GetDesiredRotation()); 
			FRotator TargetRot = User.WorldToLocalRotation(GetTargetRotation());
			float AngleDiff = FRotator::NormalizeAxis(TargetRot.Yaw - DesiredRot.Yaw);
			FinalDeltaRot.Yaw += AngleDiff * DeltaTime * FMath::Lerp(0.f, 1.f, SpeedAlpha) * GetSpeedFactorMultiplier(FMath::Abs(AngleDiff));
		}
		else
		{
			ActiveJumpTime = 0;
		}

		return FinalDeltaRot;
	}

	bool IsMoving() const override
	{
		FVector MoveUp = RideComponent.Frog.GetMovementWorldUp();

		FVector Velocity;
		Velocity = RideComponent.Frog.GetActualVelocity();

		UPrimitiveComponent MoveWithPrimitive;
		if ((MoveComp != nullptr) && MoveComp.GetCurrentMoveWithComponent(MoveWithPrimitive, FVector()))
			Velocity -= MoveWithPrimitive.GetPhysicsLinearVelocity() * (1 -Settings.InheritedVelocityFactor);

		return Velocity.ConstrainToPlane(MoveUp).SizeSquared2D() > FMath::Square(Settings.MovementThreshold);
	}

	FRotator GetTargetRotation() override
	{
		return RideComponent.Frog.GetActorRotation();
	}

	// bool IsChargingJump() const
	// {
	// 	return RideComponent.Frog.bCharging;
	// }

	// bool HasInput() const
	// {
	// 	return !RideComponent.Frog.CurrentMovementInput.IsNearlyZero(0.1f);
	// }

	// bool IsMoving() const
	// {
	// 	return (HasInput() || IsChargingJump());
	// }
}
