import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.SpaceRocket;

class USpaceRocketMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityDebugCategory = n"Movement";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	ASpaceRocket SpaceRocket;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	FVector CurrentPlayerMovementInput;
	float CurrentPlayerRotationInput;

	FVector CurrentFacingDir;
	FVector TargetFacingDir;

	float CurrentPitch;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SpaceRocket = Cast<ASpaceRocket>(Owner);
		CurrentFacingDir = Owner.ActorForwardVector;
		TargetFacingDir = Owner.ActorForwardVector;
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SpaceRocket.bMoving)
        	return EHazeNetworkActivation::ActivateLocal;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SpaceRocket.bMoving)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentPitch = SpaceRocket.ActorRotation.Pitch;
		CrumbComp.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SpaceRocket.TriggerMovementTransition(this);
		SpaceRocket.RocketRoot.SetRelativeRotation(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (SpaceRocket.HasControl())
		{
			FVector MovementDirection = SpaceRocket.ForwardDirection.ForwardVector;
			SpaceRocket.AddActorWorldOffset(MovementDirection * SpaceRocket.CurrentMovementSpeed * DeltaTime);

			FVector2D PlayerInput = SpaceRocket.PlayerInput;
			
			FRotator YawRate = FRotator(0.f, PlayerInput.X, 0.f);
			FRotator PitchRate = FRotator(-PlayerInput.Y, 0.f, 0.f);
			CurrentPitch += PlayerInput.Y * 120.f * DeltaTime;
			CurrentPitch = FMath::Clamp(CurrentPitch, -75.f, 75.f);
			SpaceRocket.AddActorWorldRotation(YawRate * 100 * DeltaTime);
			SpaceRocket.SetActorRotation(FRotator(CurrentPitch, SpaceRocket.ActorRotation.Yaw, SpaceRocket.ActorRotation.Roll));

			FRotator RocketOffset = FRotator(PlayerInput.Y * 15.f, 0.f, PlayerInput.X * 40.f);
			SpaceRocket.RocketRoot.SetRelativeRotation(FMath::RInterpTo(SpaceRocket.RocketRoot.RelativeRotation, RocketOffset, DeltaTime, 2.f));

			CrumbComp.SetCustomCrumbRotation(SpaceRocket.RocketRoot.RelativeRotation);
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"Movement");
			MoveData.ApplyDelta(ConsumedParams.DeltaTranslation);

			MoveComp.Move(MoveData);
			
			FRotator TargetRot = ConsumedParams.Rotation;
			SpaceRocket.SetActorRotation(TargetRot);
			SpaceRocket.RocketRoot.SetRelativeRotation(ConsumedParams.CustomCrumbRotator);
		}
	}
}