import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;

class UParentBlobBossBreathMovementCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AParentBlob ParentBlob;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		ParentBlob = Cast<AParentBlob>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"Breath"))
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"Breath"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

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
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Breath");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveCharacter(FrameMove, n"Breath");
		
		CrumbComp.LeaveMovementCrumb();
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			FVector Velocity = FVector(0.f, 1600.f, 0.f);
			FrameMove.ApplyVelocity(Velocity);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMove.ApplyTargetRotationDelta(); 
	}
}
