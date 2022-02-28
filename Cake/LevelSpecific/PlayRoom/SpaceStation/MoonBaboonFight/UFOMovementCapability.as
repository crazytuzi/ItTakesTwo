import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.ControllableUFO;

class UUfoMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityDebugCategory = n"Movement";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AControllableUFO ControllableUFO;

	FVector CurrentPlayerMovementInput;
	float CurrentPlayerRotationInput;

	FVector CurrentFacingDir;

	FVector LerpedPlayerMovementInput;
	float LerpedPlayerRotationInput;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ControllableUFO = Cast<AControllableUFO>(GetAttributeObject(n"ControllableUFO"));
		CurrentFacingDir = Owner.ActorForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (ControllableUFO.bActive)
        	return EHazeNetworkActivation::ActivateFromControl;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!ControllableUFO.MoveComp.CanCalculateMovement())
			return;

		if (HasControl())
		{
			CurrentPlayerMovementInput = ControllableUFO.PlayerMovementInput;
			CurrentPlayerRotationInput = ControllableUFO.PlayerRotationInput;

			LerpedPlayerMovementInput = FMath::VInterpTo(LerpedPlayerMovementInput, CurrentPlayerMovementInput, DeltaTime, 1.3f);
			LerpedPlayerRotationInput = FMath::FInterpTo(LerpedPlayerRotationInput, CurrentPlayerRotationInput, DeltaTime, 3.f);

			FVector Velocity = (Owner.ActorForwardVector * LerpedPlayerMovementInput.Y * 3000.f) + (Owner.ActorRightVector * LerpedPlayerMovementInput.X * 3000.f) + (-Owner.ActorUpVector * 1000.f);
			ControllableUFO.LerpedPlayerInputSyncComp.SetValue(LerpedPlayerMovementInput);

			FHazeFrameMovement MoveData = ControllableUFO.MoveComp.MakeFrameMovement(n"UFO");
			MoveData.ApplyVelocity(Velocity);

			FVector TargetFacingDir = Owner.ActorForwardVector +  (Owner.ActorRightVector * LerpedPlayerRotationInput * 1.5f * DeltaTime);
			TargetFacingDir.Normalize();

			MoveData.OverrideStepUpHeight(0.f);
			ControllableUFO.MoveComp.SetTargetFacingDirection(TargetFacingDir);
			MoveData.ApplyTargetRotationDelta();
			ControllableUFO.MoveComp.Move(MoveData);
			
			ControllableUFO.CrumbComponent.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			ControllableUFO.CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			FHazeFrameMovement MoveData = ControllableUFO.MoveComp.MakeFrameMovement(n"UFO");
			MoveData.ApplyDelta(ConsumedParams.DeltaTranslation);

			FRotator TargetRot = ConsumedParams.Rotation;
			ControllableUFO.MoveComp.SetTargetFacingRotation(TargetRot);
			MoveData.ApplyTargetRotationDelta();

			ControllableUFO.MoveComp.Move(MoveData);
		}
	}
}